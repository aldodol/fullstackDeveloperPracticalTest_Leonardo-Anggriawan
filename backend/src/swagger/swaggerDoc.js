const swaggerUi = require('swagger-ui-express');

const swaggerDefinition = {
  openapi: '3.0.0',
  info: {
    title: 'Raw Material Inventory & Transaction API (Studi Kasus 4)',
    version: '1.0.0',
    description: 'Dokumentasi REST API Sistem Transaksi Bahan Baku: Master Bahan Baku, Transaksi Barang Keluar, Transaksi Pengembalian Barang, dan Kartu Stok Terkini.'
  },
  servers: [
    {
      url: '/api',
      description: 'Default API Endpoint'
    }
  ],
  paths: {
    '/stock/overview': {
      get: {
        summary: 'Mendapatkan ringkasan stok, KPI metrik, dan alert low stock',
        tags: ['Stok & Dashboard'],
        responses: {
          200: { description: 'Ringkasan berhasil diambil' }
        }
      }
    },
    '/stock/movements': {
      get: {
        summary: 'Riwayat pergerakan stok (Kartu Stok / Audit Trail)',
        tags: ['Stok & Dashboard'],
        parameters: [
          { name: 'material_id', in: 'query', schema: { type: 'integer' } },
          { name: 'movement_type', in: 'query', schema: { type: 'string', enum: ['INITIAL', 'OUT_USAGE', 'IN_RETURN', 'ADJUSTMENT'] } },
          { name: 'startDate', in: 'query', schema: { type: 'string', format: 'date' } },
          { name: 'endDate', in: 'query', schema: { type: 'string', format: 'date' } },
          { name: 'search', in: 'query', schema: { type: 'string' } },
          { name: 'limit', in: 'query', schema: { type: 'integer', default: 50 } },
          { name: 'offset', in: 'query', schema: { type: 'integer', default: 0 } }
        ],
        responses: { 200: { description: 'Daftar riwayat pergerakan stok' } }
      }
    },
    '/stock/materials/{id}/ledger': {
      get: {
        summary: 'Kartu stok spesifik per material',
        tags: ['Stok & Dashboard'],
        parameters: [
          { name: 'id', in: 'path', required: true, schema: { type: 'integer' } }
        ],
        responses: { 200: { description: 'Kartu stok material' } }
      }
    },
    '/materials': {
      get: {
        summary: 'Daftar bahan baku (Master Bahan Baku)',
        tags: ['Master Bahan Baku'],
        parameters: [
          { name: 'search', in: 'query', schema: { type: 'string' } },
          { name: 'category_id', in: 'query', schema: { type: 'integer' } },
          { name: 'stock_status', in: 'query', schema: { type: 'string', enum: ['all', 'low_stock', 'out_of_stock', 'normal'] } },
          { name: 'is_active', in: 'query', schema: { type: 'string', default: 'true' } }
        ],
        responses: { 200: { description: 'Daftar bahan baku' } }
      },
      post: {
        summary: 'Tambah bahan baku baru',
        tags: ['Master Bahan Baku'],
        requestBody: {
          required: true,
          content: {
            'application/json': {
              schema: {
                type: 'object',
                required: ['code', 'name', 'category_id', 'unit'],
                properties: {
                  code: { type: 'string', example: 'RM-MET-004' },
                  name: { type: 'string', example: 'Aluminium Sheet 1.5mm' },
                  category_id: { type: 'integer', example: 1 },
                  unit: { type: 'string', example: 'lembar' },
                  min_stock: { type: 'number', example: 20 },
                  initial_stock: { type: 'number', example: 100 },
                  description: { type: 'string', example: 'Aluminium grade 5052' }
                }
              }
            }
          }
        },
        responses: { 201: { description: 'Bahan baku berhasil dibuat' } }
      }
    },
    '/materials/{id}': {
      get: {
        summary: 'Detail bahan baku berdasarkan ID',
        tags: ['Master Bahan Baku'],
        parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'integer' } }],
        responses: { 200: { description: 'Detail bahan baku' }, 404: { description: 'Tidak ditemukan' } }
      },
      put: {
        summary: 'Perbarui data bahan baku',
        tags: ['Master Bahan Baku'],
        parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'integer' } }],
        requestBody: {
          required: true,
          content: {
            'application/json': {
              schema: {
                type: 'object',
                properties: {
                  code: { type: 'string' },
                  name: { type: 'string' },
                  category_id: { type: 'integer' },
                  unit: { type: 'string' },
                  min_stock: { type: 'number' },
                  description: { type: 'string' },
                  is_active: { type: 'boolean' }
                }
              }
            }
          }
        },
        responses: { 200: { description: 'Bahan baku berhasil diperbarui' } }
      },
      delete: {
        summary: 'Hapus / Nonaktifkan bahan baku',
        tags: ['Master Bahan Baku'],
        parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'integer' } }],
        responses: { 200: { description: 'Bahan baku berhasil dihapus/dinonaktifkan' } }
      }
    },
    '/materials/{id}/adjust-stock': {
      post: {
        summary: 'Penyesuaian stok bahan baku (Stock Opname / Manual Adjustment)',
        tags: ['Master Bahan Baku'],
        parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'integer' } }],
        requestBody: {
          required: true,
          content: {
            'application/json': {
              schema: {
                type: 'object',
                required: ['adjustment_type', 'quantity', 'reason'],
                properties: {
                  adjustment_type: { type: 'string', enum: ['ADD', 'SUBTRACT', 'SET'] },
                  quantity: { type: 'number', example: 10 },
                  reason: { type: 'string', example: 'Hasil Stock Opname Bulanan' },
                  notes: { type: 'string', example: 'Ditemukan selisih fisik' }
                }
              }
            }
          }
        },
        responses: { 200: { description: 'Stok berhasil disesuaikan' } }
      }
    },
    '/goods-out': {
      get: {
        summary: 'Daftar riwayat transaksi barang keluar',
        tags: ['Transaksi Barang Keluar'],
        parameters: [
          { name: 'search', in: 'query', schema: { type: 'string' } },
          { name: 'startDate', in: 'query', schema: { type: 'string', format: 'date' } },
          { name: 'endDate', in: 'query', schema: { type: 'string', format: 'date' } }
        ],
        responses: { 200: { description: 'Daftar transaksi barang keluar' } }
      },
      post: {
        summary: 'Buat transaksi barang keluar baru (Pengurangan Stok Otomatis & ACID Transaction)',
        tags: ['Transaksi Barang Keluar'],
        requestBody: {
          required: true,
          content: {
            'application/json': {
              schema: {
                type: 'object',
                required: ['department', 'recipient_name', 'items'],
                properties: {
                  department: { type: 'string', example: 'Divisi Assembly Panel' },
                  recipient_name: { type: 'string', example: 'Agus Pratama' },
                  notes: { type: 'string', example: 'Perakitan batch 2026' },
                  items: {
                    type: 'array',
                    items: {
                      type: 'object',
                      required: ['material_id', 'quantity'],
                      properties: {
                        material_id: { type: 'integer', example: 1 },
                        quantity: { type: 'number', example: 5 },
                        notes: { type: 'string', example: 'Kebutuhan cover box' }
                      }
                    }
                  }
                }
              }
            }
          }
        },
        responses: {
          201: { description: 'Transaksi berhasil disimpan dan stok berkurang' },
          400: { description: 'Validasi gagal atau stok tidak mencukupi' }
        }
      }
    },
    '/goods-out/{id}': {
      get: {
        summary: 'Detail transaksi barang keluar beserta daftar item',
        tags: ['Transaksi Barang Keluar'],
        parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'integer' } }],
        responses: { 200: { description: 'Detail barang keluar' } }
      }
    },
    '/goods-returns': {
      get: {
        summary: 'Daftar riwayat transaksi pengembalian barang',
        tags: ['Transaksi Pengembalian'],
        parameters: [
          { name: 'search', in: 'query', schema: { type: 'string' } },
          { name: 'startDate', in: 'query', schema: { type: 'string', format: 'date' } },
          { name: 'endDate', in: 'query', schema: { type: 'string', format: 'date' } }
        ],
        responses: { 200: { description: 'Daftar pengembalian barang' } }
      },
      post: {
        summary: 'Buat transaksi pengembalian barang (Pengembalian Stok ke Inventory)',
        tags: ['Transaksi Pengembalian'],
        requestBody: {
          required: true,
          content: {
            'application/json': {
              schema: {
                type: 'object',
                required: ['returner_name', 'department', 'reason', 'items'],
                properties: {
                  goods_out_id: { type: 'integer', example: 1, description: 'Opsional: ID referensi transaksi barang keluar' },
                  returner_name: { type: 'string', example: 'Agus Pratama' },
                  department: { type: 'string', example: 'Divisi Assembly Panel' },
                  reason: { type: 'string', example: 'Sisa Pemakaian' },
                  notes: { type: 'string', example: 'Dikembalikan dalam kondisi utuh' },
                  items: {
                    type: 'array',
                    items: {
                      type: 'object',
                      required: ['material_id', 'quantity'],
                      properties: {
                        material_id: { type: 'integer', example: 1 },
                        goods_out_item_id: { type: 'integer', example: 1, description: 'Opsional: ID item barang keluar' },
                        quantity: { type: 'number', example: 2 },
                        condition_type: { type: 'string', enum: ['GOOD', 'DAMAGED'], default: 'GOOD' },
                        is_restocked: { type: 'boolean', default: true },
                        notes: { type: 'string', example: 'Sisa 2 lembar mulus' }
                      }
                    }
                  }
                }
              }
            }
          }
        },
        responses: {
          201: { description: 'Pengembalian berhasil diproses dan stok bertambah' },
          400: { description: 'Validasi gagal atau pengembalian melebihi kuota keluar' }
        }
      }
    },
    '/goods-returns/{id}': {
      get: {
        summary: 'Detail transaksi pengembalian barang',
        tags: ['Transaksi Pengembalian'],
        parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'integer' } }],
        responses: { 200: { description: 'Detail pengembalian barang' } }
      }
    },
    '/categories': {
      get: {
        summary: 'Daftar kategori bahan baku',
        tags: ['Kategori'],
        responses: { 200: { description: 'Daftar kategori' } }
      },
      post: {
        summary: 'Tambah kategori baru',
        tags: ['Kategori'],
        requestBody: {
          required: true,
          content: {
            'application/json': {
              schema: {
                type: 'object',
                required: ['code', 'name'],
                properties: {
                  code: { type: 'string', example: 'CAT-ELC' },
                  name: { type: 'string', example: 'Elektronik & Komponen' },
                  description: { type: 'string', example: 'Komponen PCB, switch, dan kabel' }
                }
              }
            }
          }
        },
        responses: { 201: { description: 'Kategori berhasil dibuat' } }
      }
    }
  }
};

function setupSwagger(app) {
  app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerDefinition, {
    customCss: '.swagger-ui .topbar { display: none }',
    customSiteTitle: 'Raw Material Inventory API Docs'
  }));

  app.get('/api-docs.json', (req, res) => {
    res.setHeader('Content-Type', 'application/json');
    res.send(swaggerDefinition);
  });
}

module.exports = {
  setupSwagger,
  swaggerDefinition
};
