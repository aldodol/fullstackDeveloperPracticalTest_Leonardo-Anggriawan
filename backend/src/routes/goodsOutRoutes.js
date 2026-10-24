const express = require('express');
const router = express.Router();
const goodsOutController = require('../controllers/goodsOutController');
const validate = require('../middlewares/validate');
const { createGoodsOutSchema } = require('../validators/schemas');

router.get('/', goodsOutController.getAll);
router.get('/:id', goodsOutController.getById);
router.post('/', validate(createGoodsOutSchema), goodsOutController.create);

module.exports = router;
