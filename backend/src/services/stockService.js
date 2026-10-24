const { pool } = require('../config/db');

class StockService {
  /**
   * Summary overview and dashboard metrics
   */
  async getStockOverview() {
    // 1. Total materials count
    const [[materialStats]] = await pool.query(`
      SELECT 
        COUNT(*) AS total_materials,
        SUM(CASE WHEN is_active = TRUE THEN 1 ELSE 0 END) AS active_materials,
        SUM(CASE WHEN current_stock <= 0 AND is_active = TRUE THEN 1 ELSE 0 END) AS out_of_stock_materials,
        SUM(CASE WHEN current_stock <= min_stock AND current_stock > 0 AND is_active = TRUE THEN 1 ELSE 0 END) AS low_stock_materials,
        SUM(CASE WHEN current_stock > min_stock AND is_active = TRUE THEN 1 ELSE 0 END) AS safe_stock_materials
      FROM materials
    `);

    // 2. Total Goods Out stats
    const [[goodsOutStats]] = await pool.query(`
      SELECT 
        COUNT(*) AS total_goods_out_count,
        COALESCE(SUM(total_qty), 0) AS total_goods_out_qty
      FROM goods_out
    `);

    // 3. Total Goods Return stats
    const [[returnStats]] = await pool.query(`
      SELECT 
        COUNT(*) AS total_returns_count,
        COALESCE(SUM(total_qty), 0) AS total_returns_qty
      FROM goods_returns
    `);

    // 4. Low stock materials list
    const [lowStockList] = await pool.query(`
      SELECT 
        m.id,
        m.code,
        m.name,
        c.name AS category_name,
        m.unit,
        m.min_stock,
        m.current_stock,
        (m.min_stock - m.current_stock) AS deficit_qty,
        CASE
          WHEN m.current_stock <= 0 THEN 'OUT_OF_STOCK'
          ELSE 'LOW_STOCK'
        END AS urgency_level
      FROM materials m
      JOIN categories c ON c.id = m.category_id
      WHERE m.current_stock <= m.min_stock AND m.is_active = TRUE
      ORDER BY (m.current_stock / NULLIF(m.min_stock, 0)) ASC
      LIMIT 10
    `);

    // 5. Recent stock movements
    const [recentMovements] = await pool.query(`
      SELECT 
        sm.id,
        sm.movement_code,
        sm.material_id,
        m.code AS material_code,
        m.name AS material_name,
        m.unit,
        sm.movement_type,
        sm.reference_type,
        sm.reference_id,
        sm.quantity,
        sm.stock_before,
        sm.stock_after,
        sm.notes,
        sm.created_at
      FROM stock_movements sm
      JOIN materials m ON m.id = sm.material_id
      ORDER BY sm.id DESC
      LIMIT 10
    `);

    return {
      stats: {
        totalMaterials: materialStats.total_materials || 0,
        activeMaterials: materialStats.active_materials || 0,
        outOfStockMaterials: materialStats.out_of_stock_materials || 0,
        lowStockMaterials: materialStats.low_stock_materials || 0,
        safeStockMaterials: materialStats.safe_stock_materials || 0,
        totalGoodsOutCount: goodsOutStats.total_goods_out_count || 0,
        totalGoodsOutQty: parseFloat(goodsOutStats.total_goods_out_qty) || 0,
        totalReturnsCount: returnStats.total_returns_count || 0,
        totalReturnsQty: parseFloat(returnStats.total_returns_qty) || 0
      },
      lowStockList,
      recentMovements
    };
  }

  /**
   * Filterable stock ledger / audit history
   */
  async getStockMovements({ material_id, movement_type, reference_type, startDate, endDate, search, limit = 50, offset = 0 } = {}) {
    let sql = `
      SELECT 
        sm.id,
        sm.movement_code,
        sm.material_id,
        m.code AS material_code,
        m.name AS material_name,
        c.name AS category_name,
        m.unit,
        sm.movement_type,
        sm.reference_type,
        sm.reference_id,
        sm.quantity,
        sm.stock_before,
        sm.stock_after,
        sm.notes,
        sm.created_at
      FROM stock_movements sm
      JOIN materials m ON m.id = sm.material_id
      JOIN categories c ON c.id = m.category_id
      WHERE 1=1
    `;

    const params = [];

    if (material_id) {
      sql += ' AND sm.material_id = ?';
      params.push(parseInt(material_id, 10));
    }

    if (movement_type) {
      sql += ' AND sm.movement_type = ?';
      params.push(movement_type);
    }

    if (reference_type) {
      sql += ' AND sm.reference_type = ?';
      params.push(reference_type);
    }

    if (startDate) {
      sql += ' AND DATE(sm.created_at) >= ?';
      params.push(startDate);
    }

    if (endDate) {
      sql += ' AND DATE(sm.created_at) <= ?';
      params.push(endDate);
    }

    if (search) {
      sql += ' AND (m.name LIKE ? OR m.code LIKE ? OR sm.movement_code LIKE ? OR sm.notes LIKE ?)';
      const queryPattern = `%${search}%`;
      params.push(queryPattern, queryPattern, queryPattern, queryPattern);
    }

    // Get total count for pagination
    const countSql = `SELECT COUNT(*) AS total FROM (${sql}) AS count_table`;
    const [[countResult]] = await pool.query(countSql, params);

    sql += ' ORDER BY sm.id DESC LIMIT ? OFFSET ?';
    params.push(parseInt(limit, 10), parseInt(offset, 10));

    const [rows] = await pool.query(sql, params);

    return {
      total: countResult.total,
      limit: parseInt(limit, 10),
      offset: parseInt(offset, 10),
      movements: rows
    };
  }

  /**
   * Get specific material's stock card / ledger
   */
  async getMaterialLedger(materialId, { limit = 50, offset = 0 } = {}) {
    const [materials] = await pool.query(
      `SELECT m.*, c.name AS category_name 
       FROM materials m 
       JOIN categories c ON c.id = m.category_id 
       WHERE m.id = ?`,
      [materialId]
    );

    if (materials.length === 0) {
      const error = new Error('Bahan baku tidak ditemukan');
      error.statusCode = 404;
      throw error;
    }

    const material = materials[0];
    const ledger = await this.getStockMovements({ material_id: materialId, limit, offset });

    return {
      material,
      ledger
    };
  }
}

module.exports = new StockService();
