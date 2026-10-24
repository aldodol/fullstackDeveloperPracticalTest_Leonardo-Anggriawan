const stockService = require('../services/stockService');
const { successResponse } = require('../utils/response');

class StockController {
  async getOverview(req, res, next) {
    try {
      const data = await stockService.getStockOverview();
      return successResponse(res, data, 'Berhasil mengambil ringkasan stok');
    } catch (err) {
      next(err);
    }
  }

  async getMovements(req, res, next) {
    try {
      const { material_id, movement_type, reference_type, startDate, endDate, search, limit, offset } = req.query;
      const data = await stockService.getStockMovements({
        material_id,
        movement_type,
        reference_type,
        startDate,
        endDate,
        search,
        limit,
        offset
      });
      return successResponse(res, data, 'Berhasil mengambil riwayat pergerakan stok');
    } catch (err) {
      next(err);
    }
  }

  async getMaterialLedger(req, res, next) {
    try {
      const { limit, offset } = req.query;
      const data = await stockService.getMaterialLedger(req.params.id, { limit, offset });
      return successResponse(res, data, 'Berhasil mengambil kartu stok bahan baku');
    } catch (err) {
      next(err);
    }
  }
}

module.exports = new StockController();
