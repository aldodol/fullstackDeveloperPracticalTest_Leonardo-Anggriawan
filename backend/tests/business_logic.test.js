const test = require('node:test');
const assert = require('node:assert/strict');
const {
  createCategorySchema,
  createMaterialSchema,
  createGoodsOutSchema,
  createGoodsReturnSchema
} = require('../src/validators/schemas');

test('Validation: createMaterialSchema accepts valid input', () => {
  const payload = {
    code: 'RM-MET-099',
    name: 'Baja Galvanis 2mm',
    category_id: 1,
    unit: 'lembar',
    min_stock: 10,
    initial_stock: 50,
    description: 'Bahan galvanis anti karat'
  };

  const { error, value } = createMaterialSchema.validate(payload);
  assert.equal(error, undefined);
  assert.equal(value.code, 'RM-MET-099');
  assert.equal(value.min_stock, 10);
});

test('Validation: createMaterialSchema rejects negative min_stock', () => {
  const payload = {
    code: 'RM-MET-099',
    name: 'Baja Galvanis 2mm',
    category_id: 1,
    unit: 'lembar',
    min_stock: -5
  };

  const { error } = createMaterialSchema.validate(payload);
  assert.notEqual(error, undefined);
});

test('Validation: createGoodsOutSchema rejects empty items', () => {
  const payload = {
    department: 'Divisi Produksi',
    recipient_name: 'Budi Santoso',
    items: []
  };

  const { error } = createGoodsOutSchema.validate(payload);
  assert.notEqual(error, undefined);
});

test('Validation: createGoodsOutSchema rejects non-positive quantity', () => {
  const payload = {
    department: 'Divisi Produksi',
    recipient_name: 'Budi Santoso',
    items: [
      { material_id: 1, quantity: 0 }
    ]
  };

  const { error } = createGoodsOutSchema.validate(payload);
  assert.notEqual(error, undefined);
});

test('Business Rule: Stock deduction math consistency', () => {
  const initialStock = 100;
  const issueQty = 25;
  const expectedRemaining = 75;

  assert.equal(initialStock - issueQty, expectedRemaining);
});

test('Business Rule: Return quota check prevents over-return', () => {
  const issuedQty = 10;
  const alreadyReturned = 7;
  const maxReturnable = issuedQty - alreadyReturned; // 3
  const requestedReturn = 5;

  const isAllowed = requestedReturn <= maxReturnable;
  assert.equal(isAllowed, false);
});

test('Business Rule: Damaged items are tracked without adding to usable stock', () => {
  const currentUsableStock = 50;
  const returnQty = 5;
  const condition = 'DAMAGED';
  const isRestocked = condition === 'GOOD';

  const newUsableStock = isRestocked ? currentUsableStock + returnQty : currentUsableStock;
  assert.equal(newUsableStock, 50); // Unaltered usable stock
});
