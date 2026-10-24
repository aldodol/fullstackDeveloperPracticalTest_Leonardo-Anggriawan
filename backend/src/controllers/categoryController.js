const categoryService = require('../services/categoryService');
const { successResponse } = require('../utils/response');

class CategoryController {
  async getAll(req, res, next) {
    try {
      const data = await categoryService.getAllCategories();
      return successResponse(res, data, 'Berhasil mengambil daftar kategori');
    } catch (err) {
      next(err);
    }
  }

  async getById(req, res, next) {
    try {
      const data = await categoryService.getCategoryById(req.params.id);
      return successResponse(res, data, 'Berhasil mengambil detail kategori');
    } catch (err) {
      next(err);
    }
  }

  async create(req, res, next) {
    try {
      const data = await categoryService.createCategory(req.body);
      return successResponse(res, data, 'Kategori berhasil ditambahkan', 201);
    } catch (err) {
      next(err);
    }
  }

  async update(req, res, next) {
    try {
      const data = await categoryService.updateCategory(req.params.id, req.body);
      return successResponse(res, data, 'Kategori berhasil diperbarui');
    } catch (err) {
      next(err);
    }
  }

  async delete(req, res, next) {
    try {
      const data = await categoryService.deleteCategory(req.params.id);
      return successResponse(res, data, data.message);
    } catch (err) {
      next(err);
    }
  }
}

module.exports = new CategoryController();
