const express = require('express');
const router = express.Router();
const transactionCtrl = require('../controllers/transactionController');
const { isAuthenticated } = require('../middleware/authMiddleware');

// POST /api/transaction (requires authentication)
router.post('/', isAuthenticated, transactionCtrl.create);

module.exports = router;
