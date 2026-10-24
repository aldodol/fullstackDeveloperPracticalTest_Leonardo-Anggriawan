const express = require('express');
const router = express.Router();
const materialController = require('../controllers/materialController');
const validate = require('../middlewares/validate');
const { createMaterialSchema, updateMaterialSchema, adjustStockSchema } = require('../validators/schemas');

router.get('/', materialController.getAll);
router.get('/:id', materialController.getById);
router.post('/', validate(createMaterialSchema), materialController.create);
router.put('/:id', validate(updateMaterialSchema), materialController.update);
router.delete('/:id', materialController.delete);
router.post('/:id/adjust-stock', validate(adjustStockSchema), materialController.adjustStock);

module.exports = router;
