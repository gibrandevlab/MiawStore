const express = require('express');
const router = express.Router();
const { isStaff } = require('../middleware/authMiddleware');

const kasirStocksCtrl = require('../controllers/kasirStocksController');
const kasirDashboardCtrl = require('../controllers/kasirDashboardController');

// protect all kasir routes with isStaff (admin or kasir)
router.use(isStaff);

router.get('/dashboard', kasirDashboardCtrl.index);
router.get('/stocks', kasirStocksCtrl.index);
router.put('/stocks/:productId', kasirStocksCtrl.update);

module.exports = router;
