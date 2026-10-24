const goodsReturnService = require('../services/goodsReturnService');
const { successResponse } = require('../utils/response');

class GoodsReturnController {
  async getAll(req, res, next) {
    try {
      const { search, startDate, endDate, limit, offset } = req.query;
      const data = await goodsReturnService.getAllGoodsReturns({
        search,
        startDate,
        endDate,
        limit,
        offset
      });
      return successResponse(res, data, 'Berhasil mengambil daftar pengembalian barang');
    } catch (err) {
      next(err);
    }
  }

  async getById(req, res, next) {
    try {
      const data = await goodsReturnService.getGoodsReturnById(req.params.id);
      return successResponse(res, data, 'Berhasil mengambil detail pengembalian barang');
    } catch (err) {
      next(err);
    }
  }

  async create(req, res, next) {
    try {
      const data = await goodsReturnService.createGoodsReturn(req.body);
      return successResponse(res, data, 'Transaksi pengembalian barang berhasil diproses', 201);
    } catch (err) {
      next(err);
    }
  }
}

module.exports = new GoodsReturnController();
