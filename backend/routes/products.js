const express = require('express');
const router = express.Router();
const kasirProductController = require('../controllers/kasirProductController');

// Public products list for Kasir (read-only)
router.get('/', kasirProductController.index);

module.exports = router;
