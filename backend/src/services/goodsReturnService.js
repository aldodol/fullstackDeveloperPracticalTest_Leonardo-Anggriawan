const { pool } = require('../config/db');

class GoodsReturnService {
  /**
   * Generate next Goods Return code: RET-YYYYMMDD-XXXX
   */
  async generateReturnCode(conn) {
    const today = new Date();
    const yyyy = today.getFullYear();
    const mm = String(today.getMonth() + 1).padStart(2, '0');
    const dd = String(today.getDate()).padStart(2, '0');
    const prefix = `RET-${yyyy}${mm}${dd}-`;

    const [rows] = await conn.query(
      `SELECT return_code FROM goods_returns 
       WHERE return_code LIKE ? 
       ORDER BY id DESC LIMIT 1`,
      [`${prefix}%`]
    );

    let nextNumber = 1;
    if (rows.length > 0) {
      const lastCode = rows[0].return_code;
      const parts = lastCode.split('-');
      if (parts.length === 3) {
        nextNumber = parseInt(parts[2], 10) + 1;
      }
    }

    return `${prefix}${String(nextNumber).padStart(4, '0')}`;
  }

  /**
   * Process Transaksi Pengembalian Barang
   */
  async createGoodsReturn({ goods_out_id, returner_name, department, reason, notes, items }) {
    if (!items || !Array.isArray(items) || items.length === 0) {
      const error = new Error('Daftar barang kembali tidak boleh kosong');
      error.statusCode = 400;
      throw error;
    }

    const conn = await pool.getConnection();
    try {
      await conn.beginTransaction();

      // Check goods_out reference if provided
      let goodsOutRecord = null;
      if (goods_out_id) {
        const [goRows] = await conn.query(
          'SELECT id, transaction_code, department FROM goods_out WHERE id = ?',
          [goods_out_id]
        );
        if (goRows.length === 0) {
          const error = new Error(`Transaksi barang keluar dengan ID ${goods_out_id} tidak ditemukan`);
          error.statusCode = 404;
          throw error;
        }
        goodsOutRecord = goRows[0];
      }

      const returnCode = await this.generateReturnCode(conn);
      let totalQty = 0;
      const validatedItems = [];

      // Validate each item
      for (const item of items) {
        const materialId = parseInt(item.material_id, 10);
        const returnQty = parseFloat(item.quantity);
        const conditionType = item.condition_type === 'DAMAGED' ? 'DAMAGED' : 'GOOD';
        const isRestocked = item.is_restocked !== undefined ? Boolean(item.is_restocked) : (conditionType === 'GOOD');

        if (isNaN(returnQty) || returnQty <= 0) {
          const error = new Error(`Jumlah pengembalian untuk material ID ${materialId} harus lebih dari 0`);
          error.statusCode = 400;
          throw error;
        }

        // Lock material row
        const [matRows] = await conn.query(
          'SELECT id, code, name, unit, current_stock FROM materials WHERE id = ? FOR UPDATE',
          [materialId]
        );

        if (matRows.length === 0) {
          const error = new Error(`Material dengan ID ${materialId} tidak ditemukan`);
          error.statusCode = 404;
          throw error;
        }

        const material = matRows[0];
        let goodsOutItemId = null;

        // If linked to a specific goods_out_item
        if (item.goods_out_item_id) {
          const [goiRows] = await conn.query(
            'SELECT id, goods_out_id, material_id, quantity, returned_qty FROM goods_out_items WHERE id = ? FOR UPDATE',
            [item.goods_out_item_id]
          );

          if (goiRows.length === 0) {
            const error = new Error(`Detail barang keluar dengan ID ${item.goods_out_item_id} tidak ditemukan`);
            error.statusCode = 404;
            throw error;
          }

          const goi = goiRows[0];
          const currentReturned = parseFloat(goi.returned_qty) || 0;
          const originalQty = parseFloat(goi.quantity);
          const maxReturnable = originalQty - currentReturned;

          if (returnQty > maxReturnable) {
            const error = new Error(
              `Jumlah pengembalian untuk '${material.name}' melebihi kuota sisa yang dapat dikembalikan! Maksimal: ${maxReturnable} ${material.unit}, diminta: ${returnQty} ${material.unit}`
            );
            error.statusCode = 400;
            throw error;
          }

          goodsOutItemId = goi.id;
        }

        const currentStock = parseFloat(material.current_stock);
        const stockAfter = isRestocked ? currentStock + returnQty : currentStock;

        totalQty += returnQty;
        validatedItems.push({
          material,
          goodsOutItemId,
          quantity: returnQty,
          conditionType,
          isRestocked,
          notes: item.notes || null,
          stockBefore: currentStock,
          stockAfter
        });
      }

      // Insert goods_returns master
      const [grResult] = await conn.query(
        `INSERT INTO goods_returns 
         (return_code, return_date, goods_out_id, returner_name, department, reason, notes, total_items, total_qty)
         VALUES (?, NOW(), ?, ?, ?, ?, ?, ?, ?)`,
        [
          returnCode,
          goods_out_id || null,
          returner_name,
          department,
          reason,
          notes || null,
          validatedItems.length,
          totalQty
        ]
      );

      const goodsReturnId = grResult.insertId;

      // Process items and stock updates
      for (let i = 0; i < validatedItems.length; i++) {
        const item = validatedItems[i];
        const movementCode = `MOV-RET-${goodsReturnId}-${i + 1}`;

        // Insert goods_return_item
        await conn.query(
          `INSERT INTO goods_return_items 
           (goods_return_id, goods_out_item_id, material_id, quantity, unit, condition_type, is_restocked, notes)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
          [
            goodsReturnId,
            item.goodsOutItemId,
            item.material.id,
            item.quantity,
            item.material.unit,
            item.conditionType,
            item.isRestocked ? 1 : 0,
            item.notes
          ]
        );

        // Update returned_qty in goods_out_items if linked
        if (item.goodsOutItemId) {
          await conn.query(
            'UPDATE goods_out_items SET returned_qty = returned_qty + ? WHERE id = ?',
            [item.quantity, item.goodsOutItemId]
          );
        }

        // If item is restocked back to inventory
        if (item.isRestocked) {
          await conn.query(
            'UPDATE materials SET current_stock = ? WHERE id = ?',
            [item.stockAfter, item.material.id]
          );

          await conn.query(
            `INSERT INTO stock_movements 
             (movement_code, material_id, movement_type, reference_type, reference_id, quantity, stock_before, stock_after, notes)
             VALUES (?, ?, 'IN_RETURN', 'GOODS_RETURN', ?, ?, ?, ?, ?)`,
            [
              movementCode,
              item.material.id,
              goodsReturnId,
              item.quantity,
              item.stockBefore,
              item.stockAfter,
              `Pengembalian Ref ${returnCode} dari ${returner_name} (${reason})`
            ]
          );
        } else {
          // If condition is damaged and not returned to active stock, log movement entry with 0 qty change but note
          await conn.query(
            `INSERT INTO stock_movements 
             (movement_code, material_id, movement_type, reference_type, reference_id, quantity, stock_before, stock_after, notes)
             VALUES (?, ?, 'ADJUSTMENT', 'GOODS_RETURN', ?, 0, ?, ?, ?)`,
            [
              movementCode,
              item.material.id,
              goodsReturnId,
              item.stockBefore,
              item.stockBefore,
              `Barang Rusak Ref ${returnCode} (${item.quantity} ${item.material.unit} tidak dimasukkan ke stok aktif - ${reason})`
            ]
          );
        }
      }

      await conn.commit();
      return this.getGoodsReturnById(goodsReturnId);
    } catch (err) {
      await conn.rollback();
      throw err;
    } finally {
      conn.release();
    }
  }

  async getAllGoodsReturns({ search, startDate, endDate, limit = 50, offset = 0 } = {}) {
    let sql = `
      SELECT 
        gr.id,
        gr.return_code,
        gr.return_date,
        gr.goods_out_id,
        go.transaction_code AS goods_out_code,
        gr.returner_name,
        gr.department,
        gr.reason,
        gr.notes,
        gr.total_items,
        gr.total_qty,
        gr.created_at
      FROM goods_returns gr
      LEFT JOIN goods_out go ON go.id = gr.goods_out_id
      WHERE 1=1
    `;

    const params = [];

    if (search) {
      sql += ' AND (gr.return_code LIKE ? OR gr.department LIKE ? OR gr.returner_name LIKE ? OR gr.reason LIKE ?)';
      const pattern = `%${search}%`;
      params.push(pattern, pattern, pattern, pattern);
    }

    if (startDate) {
      sql += ' AND DATE(gr.return_date) >= ?';
      params.push(startDate);
    }

    if (endDate) {
      sql += ' AND DATE(gr.return_date) <= ?';
      params.push(endDate);
    }

    sql += ' ORDER BY gr.id DESC LIMIT ? OFFSET ?';
    params.push(parseInt(limit, 10), parseInt(offset, 10));

    const [rows] = await pool.query(sql, params);
    return rows;
  }

  async getGoodsReturnById(id) {
    const [headerRows] = await pool.query(
      `SELECT 
        gr.*,
        go.transaction_code AS goods_out_code,
        go.transaction_date AS goods_out_date
       FROM goods_returns gr
       LEFT JOIN goods_out go ON go.id = gr.goods_out_id
       WHERE gr.id = ?`,
      [id]
    );

    if (headerRows.length === 0) {
      const error = new Error('Transaksi pengembalian barang tidak ditemukan');
      error.statusCode = 404;
      throw error;
    }

    const header = headerRows[0];

    const [itemRows] = await pool.query(
      `SELECT 
        gri.id,
        gri.goods_return_id,
        gri.goods_out_item_id,
        gri.material_id,
        m.code AS material_code,
        m.name AS material_name,
        c.name AS category_name,
        gri.quantity,
        gri.unit,
        gri.condition_type,
        gri.is_restocked,
        gri.notes,
        gri.created_at
       FROM goods_return_items gri
       JOIN materials m ON m.id = gri.material_id
       JOIN categories c ON c.id = m.category_id
       WHERE gri.goods_return_id = ?
       ORDER BY gri.id ASC`,
      [id]
    );

    header.items = itemRows;
    return header;
  }
}

module.exports = new GoodsReturnService();
