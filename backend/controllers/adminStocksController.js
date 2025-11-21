const { Stock, Product } = require('../models');

exports.index = async (req, res) => {
  try {
    const stocks = await Stock.findAll({
      include: [{ model: Product, as: 'product' }],
      order: [['quantity', 'ASC']]
    });
    return res.json(stocks);
  } catch (err) {
    console.error(err);
    return res.status(500).json({ message: 'Internal server error' });
  }
};

// Update stock for a productId; body { quantity: number } will set the absolute quantity
exports.update = async (req, res) => {
  try {
    const { productId } = req.params;
    const { quantity } = req.body;
    if (quantity === undefined) return res.status(400).json({ message: 'quantity is required' });

    let stock = await Stock.findOne({ where: { productId } });
    if (!stock) {
      // create if missing with the provided absolute quantity
      stock = await Stock.create({ productId, quantity: Number(quantity) });
      // include product before returning
      const created = await Stock.findOne({ where: { id: stock.id }, include: [{ model: Product, as: 'product' }] });
      return res.json(created);
    }

    stock.quantity = Math.max(0, Number(quantity));
    await stock.save();

    const updated = await Stock.findOne({ where: { id: stock.id }, include: [{ model: Product, as: 'product' }] });
    return res.json(updated);
  } catch (err) {
    console.error(err);
    return res.status(500).json({ message: 'Internal server error' });
  }
};
