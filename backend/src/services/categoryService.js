const { pool } = require('../config/db');

class CategoryService {
  async getAllCategories() {
    const [rows] = await pool.query(
      `SELECT c.*, COUNT(m.id) AS total_materials
       FROM categories c
       LEFT JOIN materials m ON m.category_id = c.id AND m.is_active = TRUE
       GROUP BY c.id
       ORDER BY c.name ASC`
    );
    return rows;
  }

  async getCategoryById(id) {
    const [rows] = await pool.query('SELECT * FROM categories WHERE id = ?', [id]);
    if (rows.length === 0) {
      const error = new Error('Kategori tidak ditemukan');
      error.statusCode = 404;
      throw error;
    }
    return rows[0];
  }

  async createCategory({ code, name, description }) {
    const [existing] = await pool.query('SELECT id FROM categories WHERE code = ?', [code]);
    if (existing.length > 0) {
      const error = new Error(`Kode kategori '${code}' sudah digunakan`);
      error.statusCode = 409;
      throw error;
    }

    const [result] = await pool.query(
      'INSERT INTO categories (code, name, description) VALUES (?, ?, ?)',
      [code, name, description || null]
    );

    return this.getCategoryById(result.insertId);
  }

  async updateCategory(id, { code, name, description }) {
    await this.getCategoryById(id);

    if (code) {
      const [existing] = await pool.query(
        'SELECT id FROM categories WHERE code = ? AND id != ?',
        [code, id]
      );
      if (existing.length > 0) {
        const error = new Error(`Kode kategori '${code}' sudah digunakan`);
        error.statusCode = 409;
        throw error;
      }
    }

    await pool.query(
      'UPDATE categories SET code = COALESCE(?, code), name = COALESCE(?, name), description = COALESCE(?, description) WHERE id = ?',
      [code, name, description, id]
    );

    return this.getCategoryById(id);
  }

  async deleteCategory(id) {
    await this.getCategoryById(id);

    // Check if category is used by materials
    const [materials] = await pool.query(
      'SELECT id FROM materials WHERE category_id = ? AND is_active = TRUE LIMIT 1',
      [id]
    );
    if (materials.length > 0) {
      const error = new Error('Kategori tidak dapat dihapus karena masih digunakan oleh bahan baku aktif');
      error.statusCode = 400;
      throw error;
    }

    await pool.query('DELETE FROM categories WHERE id = ?', [id]);
    return { id: Number(id), message: 'Kategori berhasil dihapus' };
  }
}

module.exports = new CategoryService();
