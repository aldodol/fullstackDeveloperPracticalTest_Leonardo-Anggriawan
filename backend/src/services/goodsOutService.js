const { pool } = require('../config/db');

class GoodsOutService {
  /**
   * Generate next Goods Out code: OUT-YYYYMMDD-XXXX
   */
  async generateTransactionCode(conn) {
    const today = new Date();
    const yyyy = today.getFullYear();
    const mm = String(today.getMonth() + 1).padStart(2, '0');
    const dd = String(today.getDate()).padStart(2, '0');
    const prefix = `OUT-${yyyy}${mm}${dd}-`;

    const [rows] = await conn.query(
      `SELECT transaction_code FROM goods_out 
       WHERE transaction_code LIKE ? 
       ORDER BY id DESC LIMIT 1`,
      [`${prefix}%`]
    );

    let nextNumber = 1;
    if (rows.length > 0) {
      const lastCode = rows[0].transaction_code;
      const parts = lastCode.split('-');
      if (parts.length === 3) {
        nextNumber = parseInt(parts[2], 10) + 1;
      }
    }

    return `${prefix}${String(nextNumber).padStart(4, '0')}`;
  }

  /**
   * Process Transaksi Barang Keluar
   */
  async createGoodsOut({ department, recipient_name, notes, items }) {
    if (!items || !Array.isArray(items) || items.length === 0) {
      const error = new Error('Daftar barang keluar tidak boleh kosong');
      error.statusCode = 400;
      throw error;
    }

    const conn = await pool.getConnection();
    try {
      await conn.beginTransaction();

      const transactionCode = await this.generateTransactionCode(conn);
      let totalQty = 0;
      const validatedItems = [];

      // Phase 1: Validate all items & lock rows
      for (const item of items) {
        const materialId = parseInt(item.material_id, 10);
        const requestedQty = parseFloat(item.quantity);

        if (isNaN(requestedQty) || requestedQty <= 0) {
          const error = new Error(`Jumlah untuk material ID ${materialId} harus lebih dari 0`);
          error.statusCode = 400;
          throw error;
        }

        // Lock material row for update
        const [matRows] = await conn.query(
          'SELECT id, code, name, unit, min_stock, current_stock, is_active FROM materials WHERE id = ? FOR UPDATE',
          [materialId]
        );

        if (matRows.length === 0) {
          const error = new Error(`Material dengan ID ${materialId} tidak ditemukan`);
          error.statusCode = 404;
          throw error;
        }

        const material = matRows[0];

        if (!material.is_active) {
          const error = new Error(`Material '${material.name}' (${material.code}) sedang dinonaktifkan`);
          error.statusCode = 400;
          throw error;
        }

        const currentStock = parseFloat(material.current_stock);
        if (currentStock < requestedQty) {
          const error = new Error(
            `Stok untuk material '${material.name}' (${material.code}) tidak mencukupi! Stok saat ini: ${currentStock} ${material.unit}, diminta: ${requestedQty} ${material.unit}`
          );
          error.statusCode = 400;
          throw error;
        }

        totalQty += requestedQty;
        validatedItems.push({
          material,
          quantity: requestedQty,
          notes: item.notes || null,
          stockBefore: currentStock,
          stockAfter: currentStock - requestedQty
        });
      }

      // Phase 2: Insert master goods_out record
      const [goResult] = await conn.query(
        `INSERT INTO goods_out 
         (transaction_code, transaction_date, department, recipient_name, notes, total_items, total_qty)
         VALUES (?, NOW(), ?, ?, ?, ?, ?)`,
        [
          transactionCode,
          department,
          recipient_name,
          notes || null,
          validatedItems.length,
          totalQty
        ]
      );

      const goodsOutId = goResult.insertId;

      // Phase 3: Insert items, deduct stock, record movements
      for (let i = 0; i < validatedItems.length; i++) {
        const item = validatedItems[i];
        const movementCode = `MOV-OUT-${goodsOutId}-${i + 1}`;

        // Insert goods_out_item
        await conn.query(
          `INSERT INTO goods_out_items 
           (goods_out_id, material_id, quantity, unit, returned_qty, notes)
           VALUES (?, ?, ?, ?, 0.00, ?)`,
          [
            goodsOutId,
            item.material.id,
            item.quantity,
            item.material.unit,
            item.notes
          ]
        );

        // Deduct material current_stock
        await conn.query(
          'UPDATE materials SET current_stock = ? WHERE id = ?',
          [item.stockAfter, item.material.id]
        );

        // Record stock movement (negative quantity)
        await conn.query(
          `INSERT INTO stock_movements 
           (movement_code, material_id, movement_type, reference_type, reference_id, quantity, stock_before, stock_after, notes)
           VALUES (?, ?, 'OUT_USAGE', 'GOODS_OUT', ?, ?, ?, ?, ?)`,
          [
            movementCode,
            item.material.id,
            goodsOutId,
            -item.quantity,
            item.stockBefore,
            item.stockAfter,
            `Barang Keluar Ref ${transactionCode} ke ${department} (${recipient_name})`
          ]
        );
      }

      await conn.commit();
      return this.getGoodsOutById(goodsOutId);
    } catch (err) {
      await conn.rollback();
      throw err;
    } finally {
      conn.release();
    }
  }

  async getAllGoodsOut({ search, startDate, endDate, limit = 50, offset = 0 } = {}) {
    let sql = `
      SELECT 
        go.id,
        go.transaction_code,
        go.transaction_date,
        go.department,
        go.recipient_name,
        go.notes,
        go.total_items,
        go.total_qty,
        go.created_at,
        COALESCE(SUM(goi.returned_qty), 0) AS total_returned_qty
      FROM goods_out go
      LEFT JOIN goods_out_items goi ON goi.goods_out_id = go.id
      WHERE 1=1
    `;

    const params = [];

    if (search) {
      sql += ' AND (go.transaction_code LIKE ? OR go.department LIKE ? OR go.recipient_name LIKE ?)';
      const pattern = `%${search}%`;
      params.push(pattern, pattern, pattern);
    }

    if (startDate) {
      sql += ' AND DATE(go.transaction_date) >= ?';
      params.push(startDate);
    }

    if (endDate) {
      sql += ' AND DATE(go.transaction_date) <= ?';
      params.push(endDate);
    }

    sql += ' GROUP BY go.id ORDER BY go.id DESC LIMIT ? OFFSET ?';
    params.push(parseInt(limit, 10), parseInt(offset, 10));

    const [rows] = await pool.query(sql, params);
    return rows;
  }

  async getGoodsOutById(id) {
    const [headerRows] = await pool.query(
      `SELECT 
        go.*,
        COALESCE(SUM(goi.returned_qty), 0) AS total_returned_qty
       FROM goods_out go
       LEFT JOIN goods_out_items goi ON goi.goods_out_id = go.id
       WHERE go.id = ?
       GROUP BY go.id`,
      [id]
    );

    if (headerRows.length === 0) {
      const error = new Error('Transaksi barang keluar tidak ditemukan');
      error.statusCode = 404;
      throw error;
    }

    const header = headerRows[0];

    // Fetch detail items with material information
    const [itemRows] = await pool.query(
      `SELECT 
        goi.id,
        goi.goods_out_id,
        goi.material_id,
        m.code AS material_code,
        m.name AS material_name,
        c.name AS category_name,
        goi.quantity,
        goi.unit,
        goi.returned_qty,
        (goi.quantity - goi.returned_qty) AS returnable_qty,
        goi.notes,
        goi.created_at
       FROM goods_out_items goi
       JOIN materials m ON m.id = goi.material_id
       JOIN categories c ON c.id = m.category_id
       WHERE goi.goods_out_id = ?
       ORDER BY goi.id ASC`,
      [id]
    );

    header.items = itemRows;
    return header;
  }
}

module.exports = new GoodsOutService();
