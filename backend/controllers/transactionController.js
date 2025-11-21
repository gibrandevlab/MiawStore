const { sequelize, Stock, Sell, Product } = require('../models');

// POST /api/transaction
// body: { items: [{ productId, quantity }, ...] }
exports.create = async (req, res) => {
  const { items } = req.body || {};
  if (!Array.isArray(items) || items.length === 0) {
    return res.status(400).json({ success: false, message: 'Items diperlukan' });
  }

  try {
    await sequelize.transaction(async (t) => {
      // Loop items and operate under transaction
      for (const it of items) {
        const productId = it.productId;
        const qty = parseInt(it.quantity, 10) || 0;

        if (!productId || qty <= 0) {
          throw new Error('Item tidak valid');
        }

        // Lock the stock row for update to avoid race conditions
        const stock = await Stock.findOne({ where: { productId }, transaction: t, lock: t.LOCK.UPDATE });
        if (!stock) {
          throw new Error('Stok tidak ditemukan');
        }

        if (stock.quantity < qty) {
          throw new Error('Stok tidak cukup');
        }

        // Get product price
        const product = await Product.findByPk(productId, { transaction: t });
        if (!product) throw new Error('Produk tidak ditemukan');

        const price = parseFloat(product.price || 0);
        const totalPrice = Number((price * qty).toFixed(2));

        // Insert sell record (attach userId from authenticated req.user)
        const userId = (req.user && req.user.id) ? req.user.id : null;
        await Sell.create(
          {
            productId,
            userId,
            quantity_sold: qty,
            total_price: totalPrice,
          },
          { transaction: t }
        );

        // Update stock
        stock.quantity = stock.quantity - qty;
        await stock.save({ transaction: t });
      }
    });

    return res.json({ success: true, message: 'Transaksi berhasil' });
  } catch (err) {
    console.error('Transaction error:', err.message || err);
    return res.status(400).json({ success: false, message: err.message || 'Transaksi gagal' });
  }
};
