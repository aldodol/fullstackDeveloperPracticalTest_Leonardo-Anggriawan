const express = require('express');
const router = express.Router();
const categoryController = require('../controllers/categoryController');
const validate = require('../middlewares/validate');
const { createCategorySchema, updateCategorySchema } = require('../validators/schemas');

router.get('/', categoryController.getAll);
router.get('/:id', categoryController.getById);
router.post('/', validate(createCategorySchema), categoryController.create);
router.put('/:id', validate(updateCategorySchema), categoryController.update);
router.delete('/:id', categoryController.delete);

module.exports = router;
