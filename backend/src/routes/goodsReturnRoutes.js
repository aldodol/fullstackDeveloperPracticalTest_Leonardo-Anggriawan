const express = require('express');
const router = express.Router();
const goodsReturnController = require('../controllers/goodsReturnController');
const validate = require('../middlewares/validate');
const { createGoodsReturnSchema } = require('../validators/schemas');

router.get('/', goodsReturnController.getAll);
router.get('/:id', goodsReturnController.getById);
router.post('/', validate(createGoodsReturnSchema), goodsReturnController.create);

module.exports = router;
