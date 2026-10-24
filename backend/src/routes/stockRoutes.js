const express = require('express');
const router = express.Router();
const stockController = require('../controllers/stockController');

router.get('/overview', stockController.getOverview);
router.get('/movements', stockController.getMovements);
router.get('/materials/:id/ledger', stockController.getMaterialLedger);

module.exports = router;
