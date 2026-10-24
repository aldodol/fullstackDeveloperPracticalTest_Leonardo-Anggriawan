const goodsOutService = require('../services/goodsOutService');
const { successResponse } = require('../utils/response');

class GoodsOutController {
  async getAll(req, res, next) {
    try {
      const { search, startDate, endDate, limit, offset } = req.query;
      const data = await goodsOutService.getAllGoodsOut({
        search,
        startDate,
        endDate,
        limit,
        offset
      });
      return successResponse(res, data, 'Berhasil mengambil daftar transaksi barang keluar');
    } catch (err) {
      next(err);
    }
  }

  async getById(req, res, next) {
    try {
      const data = await goodsOutService.getGoodsOutById(req.params.id);
      return successResponse(res, data, 'Berhasil mengambil detail transaksi barang keluar');
    } catch (err) {
      next(err);
    }
  }

  async create(req, res, next) {
    try {
      const data = await goodsOutService.createGoodsOut(req.body);
      return successResponse(res, data, 'Transaksi barang keluar berhasil diproses', 201);
    } catch (err) {
      next(err);
    }
  }
}

module.exports = new GoodsOutController();
