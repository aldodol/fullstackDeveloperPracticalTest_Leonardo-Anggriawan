const materialService = require('../services/materialService');
const { successResponse } = require('../utils/response');

class MaterialController {
  async getAll(req, res, next) {
    try {
      const { search, category_id, stock_status, is_active, limit, offset } = req.query;
      const data = await materialService.getAllMaterials({
        search,
        category_id,
        stock_status,
        is_active,
        limit,
        offset
      });
      return successResponse(res, data, 'Berhasil mengambil daftar bahan baku');
    } catch (err) {
      next(err);
    }
  }

  async getById(req, res, next) {
    try {
      const data = await materialService.getMaterialById(req.params.id);
      return successResponse(res, data, 'Berhasil mengambil detail bahan baku');
    } catch (err) {
      next(err);
    }
  }

  async create(req, res, next) {
    try {
      const data = await materialService.createMaterial(req.body);
      return successResponse(res, data, 'Bahan baku berhasil ditambahkan', 201);
    } catch (err) {
      next(err);
    }
  }

  async update(req, res, next) {
    try {
      const data = await materialService.updateMaterial(req.params.id, req.body);
      return successResponse(res, data, 'Bahan baku berhasil diperbarui');
    } catch (err) {
      next(err);
    }
  }

  async delete(req, res, next) {
    try {
      const data = await materialService.deleteMaterial(req.params.id);
      return successResponse(res, data, data.message);
    } catch (err) {
      next(err);
    }
  }

  async adjustStock(req, res, next) {
    try {
      const data = await materialService.adjustStock(req.params.id, req.body);
      return successResponse(res, data, 'Stok bahan baku berhasil disesuaikan');
    } catch (err) {
      next(err);
    }
  }
}

module.exports = new MaterialController();
