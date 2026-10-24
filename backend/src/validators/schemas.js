const Joi = require('joi');

const createCategorySchema = Joi.object({
  code: Joi.string().trim().max(20).required().messages({
    'any.required': 'Kode kategori wajib diisi',
    'string.empty': 'Kode kategori tidak boleh kosong'
  }),
  name: Joi.string().trim().max(100).required().messages({
    'any.required': 'Nama kategori wajib diisi',
    'string.empty': 'Nama kategori tidak boleh kosong'
  }),
  description: Joi.string().trim().allow('', null)
});

const updateCategorySchema = Joi.object({
  code: Joi.string().trim().max(20),
  name: Joi.string().trim().max(100),
  description: Joi.string().trim().allow('', null)
}).min(1);

const createMaterialSchema = Joi.object({
  code: Joi.string().trim().max(50).required().messages({
    'any.required': 'Kode bahan baku wajib diisi',
    'string.empty': 'Kode bahan baku tidak boleh kosong'
  }),
  name: Joi.string().trim().max(150).required().messages({
    'any.required': 'Nama bahan baku wajib diisi',
    'string.empty': 'Nama bahan baku tidak boleh kosong'
  }),
  category_id: Joi.number().integer().positive().required().messages({
    'any.required': 'Kategori wajib dipilih',
    'number.base': 'Kategori harus berupa angka ID yang valid'
  }),
  unit: Joi.string().trim().max(20).required().messages({
    'any.required': 'Satuan (unit) wajib diisi',
    'string.empty': 'Satuan tidak boleh kosong'
  }),
  min_stock: Joi.number().min(0).default(0).messages({
    'number.min': 'Batas minimum stok tidak boleh negatif'
  }),
  initial_stock: Joi.number().min(0).default(0).messages({
    'number.min': 'Stok awal tidak boleh negatif'
  }),
  description: Joi.string().trim().allow('', null)
});

const updateMaterialSchema = Joi.object({
  code: Joi.string().trim().max(50),
  name: Joi.string().trim().max(150),
  category_id: Joi.number().integer().positive(),
  unit: Joi.string().trim().max(20),
  min_stock: Joi.number().min(0),
  description: Joi.string().trim().allow('', null),
  is_active: Joi.boolean()
}).min(1);

const adjustStockSchema = Joi.object({
  adjustment_type: Joi.string().valid('ADD', 'SUBTRACT', 'SET').required().messages({
    'any.required': 'Tipe penyesuaian (ADD, SUBTRACT, SET) wajib diisi',
    'any.only': 'Tipe penyesuaian harus ADD, SUBTRACT, atau SET'
  }),
  quantity: Joi.number().positive().required().messages({
    'any.required': 'Jumlah stok wajib diisi',
    'number.positive': 'Jumlah penyesuaian harus bernilai positif'
  }),
  reason: Joi.string().trim().max(255).required().messages({
    'any.required': 'Alasan penyesuaian wajib diisi'
  }),
  notes: Joi.string().trim().allow('', null)
});

const goodsOutItemSchema = Joi.object({
  material_id: Joi.number().integer().positive().required().messages({
    'any.required': 'Material wajib dipilih'
  }),
  quantity: Joi.number().positive().required().messages({
    'any.required': 'Jumlah barang keluar wajib diisi',
    'number.positive': 'Jumlah harus lebih besar dari 0'
  }),
  notes: Joi.string().trim().allow('', null)
});

const createGoodsOutSchema = Joi.object({
  department: Joi.string().trim().max(100).required().messages({
    'any.required': 'Departemen/Divisi pemohon wajib diisi',
    'string.empty': 'Departemen/Divisi pemohon tidak boleh kosong'
  }),
  recipient_name: Joi.string().trim().max(100).required().messages({
    'any.required': 'Nama penerima/pemohon wajib diisi',
    'string.empty': 'Nama penerima tidak boleh kosong'
  }),
  notes: Joi.string().trim().allow('', null),
  items: Joi.array().items(goodsOutItemSchema).min(1).required().messages({
    'any.required': 'Daftar barang keluar wajib diisi',
    'array.min': 'Minimal harus ada 1 barang keluar'
  })
});

const goodsReturnItemSchema = Joi.object({
  material_id: Joi.number().integer().positive().required().messages({
    'any.required': 'Material wajib dipilih'
  }),
  goods_out_item_id: Joi.number().integer().positive().allow(null),
  quantity: Joi.number().positive().required().messages({
    'any.required': 'Jumlah pengembalian wajib diisi',
    'number.positive': 'Jumlah pengembalian harus lebih dari 0'
  }),
  condition_type: Joi.string().valid('GOOD', 'DAMAGED').default('GOOD'),
  is_restocked: Joi.boolean().default(true),
  notes: Joi.string().trim().allow('', null)
});

const createGoodsReturnSchema = Joi.object({
  goods_out_id: Joi.number().integer().positive().allow(null),
  returner_name: Joi.string().trim().max(100).required().messages({
    'any.required': 'Nama pengembali wajib diisi',
    'string.empty': 'Nama pengembali tidak boleh kosong'
  }),
  department: Joi.string().trim().max(100).required().messages({
    'any.required': 'Departemen asal pengembalian wajib diisi',
    'string.empty': 'Departemen tidak boleh kosong'
  }),
  reason: Joi.string().trim().max(255).required().messages({
    'any.required': 'Alasan pengembalian wajib diisi',
    'string.empty': 'Alasan pengembalian tidak boleh kosong'
  }),
  notes: Joi.string().trim().allow('', null),
  items: Joi.array().items(goodsReturnItemSchema).min(1).required().messages({
    'any.required': 'Daftar barang kembali wajib diisi',
    'array.min': 'Minimal harus ada 1 barang yang dikembalikan'
  })
});

module.exports = {
  createCategorySchema,
  updateCategorySchema,
  createMaterialSchema,
  updateMaterialSchema,
  adjustStockSchema,
  createGoodsOutSchema,
  createGoodsReturnSchema
};
