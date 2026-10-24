const express = require('express');
const router = express.Router();

const categoryRoutes = require('./categoryRoutes');
const materialRoutes = require('./materialRoutes');
const goodsOutRoutes = require('./goodsOutRoutes');
const goodsReturnRoutes = require('./goodsReturnRoutes');
const stockRoutes = require('./stockRoutes');

router.use('/categories', categoryRoutes);
router.use('/materials', materialRoutes);
router.use('/goods-out', goodsOutRoutes);
router.use('/goods-returns', goodsReturnRoutes);
router.use('/stock', stockRoutes);

module.exports = router;
