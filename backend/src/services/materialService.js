const { pool } = require('../config/db');

class MaterialService {
  async getAllMaterials({ search, category_id, stock_status, is_active = 'true', limit = 100, offset = 0 } = {}) {
    let sql = `
      SELECT 
        m.id,
        m.code,
        m.name,
        m.category_id,
        c.name AS category_name,
        c.code AS category_code,
        m.unit,
        m.min_stock,
        m.current_stock,
        m.description,
        m.is_active,
        m.created_at,
        m.updated_at,
        CASE
          WHEN m.current_stock <= 0 THEN 'OUT_OF_STOCK'
          WHEN m.current_stock <= m.min_stock THEN 'LOW_STOCK'
          ELSE 'NORMAL'
        END AS stock_status
      FROM materials m
      JOIN categories c ON c.id = m.category_id
      WHERE 1=1
    `;

    const params = [];

    if (is_active !== 'all') {
      sql += ' AND m.is_active = ?';
      params.push(is_active === 'true' || is_active === true ? 1 : 0);
    }

    if (category_id) {
      sql += ' AND m.category_id = ?';
      params.push(parseInt(category_id, 10));
    }

    if (search) {
      sql += ' AND (m.code LIKE ? OR m.name LIKE ? OR m.description LIKE ?)';
      const queryPattern = `%${search}%`;
      params.push(queryPattern, queryPattern, queryPattern);
    }

    if (stock_status === 'low_stock') {
      sql += ' AND m.current_stock <= m.min_stock AND m.current_stock > 0';
    } else if (stock_status === 'out_of_stock') {
      sql += ' AND m.current_stock <= 0';
    } else if (stock_status === 'normal') {
      sql += ' AND m.current_stock > m.min_stock';
    }

    sql += ' ORDER BY m.id DESC LIMIT ? OFFSET ?';
    params.push(parseInt(limit, 10), parseInt(offset, 10));

    const [rows] = await pool.query(sql, params);
    return rows;
  }

  async getMaterialById(id) {
    const [rows] = await pool.query(
      `SELECT 
        m.*,
        c.name AS category_name,
        c.code AS category_code,
        CASE
          WHEN m.current_stock <= 0 THEN 'OUT_OF_STOCK'
          WHEN m.current_stock <= m.min_stock THEN 'LOW_STOCK'
          ELSE 'NORMAL'
        END AS stock_status
       FROM materials m
       JOIN categories c ON c.id = m.category_id
       WHERE m.id = ?`,
      [id]
    );

    if (rows.length === 0) {
      const error = new Error('Bahan baku tidak ditemukan');
      error.statusCode = 404;
      throw error;
    }

    return rows[0];
  }

  async createMaterial({ code, name, category_id, unit, min_stock = 0, initial_stock = 0, description }) {
    // Check code uniqueness
    const [existing] = await pool.query('SELECT id FROM materials WHERE code = ?', [code]);
    if (existing.length > 0) {
      const error = new Error(`Kode bahan baku '${code}' sudah digunakan`);
      error.statusCode = 409;
      throw error;
    }

    // Verify category exists
    const [cat] = await pool.query('SELECT id FROM categories WHERE id = ?', [category_id]);
    if (cat.length === 0) {
      const error = new Error('Kategori yang dipilih tidak valid');
      error.statusCode = 400;
      throw error;
    }

    const conn = await pool.getConnection();
    try {
      await conn.beginTransaction();

      const [result] = await conn.query(
        `INSERT INTO materials (code, name, category_id, unit, min_stock, current_stock, description, is_active)
         VALUES (?, ?, ?, ?, ?, ?, ?, TRUE)`,
        [
          code,
          name,
          category_id,
          unit,
          parseFloat(min_stock) || 0,
          parseFloat(initial_stock) || 0,
          description || null
        ]
      );

      const materialId = result.insertId;

      // If initial stock is provided, record into stock movements
      if (parseFloat(initial_stock) > 0) {
        const movementCode = `MOV-INIT-${String(materialId).padStart(4, '0')}`;
        await conn.query(
          `INSERT INTO stock_movements 
           (movement_code, material_id, movement_type, reference_type, reference_id, quantity, stock_before, stock_after, notes)
           VALUES (?, ?, 'INITIAL', 'INITIAL_STOCK', NULL, ?, 0, ?, 'Saldo Awal Pendaftaran Bahan Baku')`,
          [movementCode, materialId, parseFloat(initial_stock), parseFloat(initial_stock)]
        );
      }

      await conn.commit();
      return this.getMaterialById(materialId);
    } catch (err) {
      await conn.rollback();
      throw err;
    } finally {
      conn.release();
    }
  }

  async updateMaterial(id, { code, name, category_id, unit, min_stock, description, is_active }) {
    await this.getMaterialById(id);

    if (code) {
      const [existing] = await pool.query(
        'SELECT id FROM materials WHERE code = ? AND id != ?',
        [code, id]
      );
      if (existing.length > 0) {
        const error = new Error(`Kode bahan baku '${code}' sudah digunakan`);
        error.statusCode = 409;
        throw error;
      }
    }

    if (category_id) {
      const [cat] = await pool.query('SELECT id FROM categories WHERE id = ?', [category_id]);
      if (cat.length === 0) {
        const error = new Error('Kategori yang dipilih tidak valid');
        error.statusCode = 400;
        throw error;
      }
    }

    await pool.query(
      `UPDATE materials SET 
        code = COALESCE(?, code),
        name = COALESCE(?, name),
        category_id = COALESCE(?, category_id),
        unit = COALESCE(?, unit),
        min_stock = COALESCE(?, min_stock),
        description = COALESCE(?, description),
        is_active = COALESCE(?, is_active)
       WHERE id = ?`,
      [
        code,
        name,
        category_id,
        unit,
        min_stock !== undefined ? parseFloat(min_stock) : null,
        description,
        is_active !== undefined ? (is_active ? 1 : 0) : null,
        id
      ]
    );

    return this.getMaterialById(id);
  }

  async deleteMaterial(id) {
    const material = await this.getMaterialById(id);

    // Check if material has been used in transactions
    const [usage] = await pool.query(
      'SELECT id FROM goods_out_items WHERE material_id = ? LIMIT 1',
      [id]
    );
    const [returns] = await pool.query(
      'SELECT id FROM goods_return_items WHERE material_id = ? LIMIT 1',
      [id]
    );

    if (usage.length > 0 || returns.length > 0) {
      // Soft delete to maintain relational integrity
      await pool.query('UPDATE materials SET is_active = FALSE WHERE id = ?', [id]);
      return { id: Number(id), message: 'Bahan baku telah dinonaktifkan (karena memiliki riwayat transaksi)' };
    }

    // Hard delete if never used
    await pool.query('DELETE FROM stock_movements WHERE material_id = ?', [id]);
    await pool.query('DELETE FROM materials WHERE id = ?', [id]);
    return { id: Number(id), message: 'Bahan baku berhasil dihapus secara permanen' };
  }

  async adjustStock(id, { adjustment_type, quantity, reason, notes }) {
    const conn = await pool.getConnection();
    try {
      await conn.beginTransaction();

      const [rows] = await conn.query('SELECT * FROM materials WHERE id = ? FOR UPDATE', [id]);
      if (rows.length === 0) {
        const error = new Error('Bahan baku tidak ditemukan');
        error.statusCode = 404;
        throw error;
      }

      const material = rows[0];
      const stockBefore = parseFloat(material.current_stock);
      const qtyNum = parseFloat(quantity);

      let stockAfter = stockBefore;
      let movementQty = 0;

      if (adjustment_type === 'ADD') {
        stockAfter = stockBefore + qtyNum;
        movementQty = qtyNum;
      } else if (adjustment_type === 'SUBTRACT') {
        if (stockBefore < qtyNum) {
          const error = new Error(`Stok tidak mencukupi untuk dikurangi. Stok saat ini: ${stockBefore} ${material.unit}`);
          error.statusCode = 400;
          throw error;
        }
        stockAfter = stockBefore - qtyNum;
        movementQty = -qtyNum;
      } else if (adjustment_type === 'SET') {
        stockAfter = qtyNum;
        movementQty = stockAfter - stockBefore;
      }

      await conn.query('UPDATE materials SET current_stock = ? WHERE id = ?', [stockAfter, id]);

      const timestamp = Date.now().toString().slice(-6);
      const movementCode = `MOV-ADJ-${material.id}-${timestamp}`;

      await conn.query(
        `INSERT INTO stock_movements 
         (movement_code, material_id, movement_type, reference_type, reference_id, quantity, stock_before, stock_after, notes)
         VALUES (?, ?, 'ADJUSTMENT', 'MANUAL_ADJUSTMENT', NULL, ?, ?, ?, ?)`,
        [
          movementCode,
          material.id,
          movementQty,
          stockBefore,
          stockAfter,
          `Penyesuaian Stok: ${reason || 'Koreksi Stok Fisik'}. Catatan: ${notes || '-'}`
        ]
      );

      await conn.commit();
      return this.getMaterialById(id);
    } catch (err) {
      await conn.rollback();
      throw err;
    } finally {
      conn.release();
    }
  }
}

module.exports = new MaterialService();
