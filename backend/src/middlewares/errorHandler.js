const { errorResponse } = require('../utils/response');

/**
 * Global Error Handling Middleware
 */
function errorHandler(err, req, res, next) {
  console.error('[Error Handler]', err);

  const statusCode = err.statusCode || (err.status ? err.status : 500);
  const message = err.message || 'Terjadi kesalahan internal pada server';

  // MySQL specific error handling
  if (err.code === 'ER_DUP_ENTRY') {
    return errorResponse(res, 'Data duplikat: kode atau data yang dimasukkan sudah ada', 409);
  }

  if (err.code === 'ER_ROW_IS_REFERENCED_2') {
    return errorResponse(res, 'Data tidak dapat dihapus karena masih direferensikan oleh data lain', 409);
  }

  if (err.code === 'ER_NO_REFERENCED_ROW_2') {
    return errorResponse(res, 'Referensi data (kategori/material) tidak ditemukan', 400);
  }

  return errorResponse(res, message, statusCode, process.env.NODE_ENV === 'development' ? err.stack : null);
}

module.exports = errorHandler;
