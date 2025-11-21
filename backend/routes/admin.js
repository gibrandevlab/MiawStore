const express = require('express');
const router = express.Router();
const { isAdmin } = require('../middleware/authMiddleware');

const usersCtrl = require('../controllers/adminUsersController');
const productsCtrl = require('../controllers/adminProductsController');
const stocksCtrl = require('../controllers/adminStocksController');
const sellsCtrl = require('../controllers/adminSellsController');
const dashboardCtrl = require('../controllers/adminDashboardController');

// Protect all admin routes
router.use(isAdmin);

// Users
router.get('/users', usersCtrl.index);
router.post('/users', usersCtrl.create);
router.put('/users/:id', usersCtrl.update);
router.delete('/users/:id', usersCtrl.remove);

// Products
router.get('/products', productsCtrl.index);
router.post('/products', productsCtrl.create);
router.put('/products/:id', productsCtrl.update);
router.delete('/products/:id', productsCtrl.remove);

// Stocks
router.get('/stocks', stocksCtrl.index);
router.put('/stocks/:productId', stocksCtrl.update);

// Sells (view only)
router.get('/sells', sellsCtrl.index);

// Dashboard summary
router.get('/dashboard-summary', dashboardCtrl.summary);

module.exports = router;
