const { Product, Stock } = require('../models');

/**
 * Controller for public/Kasir product endpoints
 */
exports.index = async (req, res) => {
  try {
    const products = await Product.findAll({
      include: [{ model: Stock, as: 'stock' }],
      order: [['id', 'ASC']],
    });

    const out = products.map((p) => ({
      id: p.id,
      name: p.name,
      description: p.description,
      price: parseFloat(p.price || 0),
      stock: p.stock ? p.stock.quantity : 0,
    }));

    return res.json(out);
  } catch (err) {
    console.error('Kasir products fetch error:', err);
    return res.status(500).json({ message: 'Gagal mengambil produk' });
  }
};
