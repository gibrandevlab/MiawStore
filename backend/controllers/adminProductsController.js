const { Product, Stock, sequelize } = require('../models');

exports.index = async (req, res) => {
  try {
    const products = await Product.findAll({ include: [{ model: Stock, as: 'stock' }] });
    return res.json(products);
  } catch (err) {
    console.error(err);
    return res.status(500).json({ message: 'Internal server error' });
  }
};

exports.create = async (req, res) => {
  const t = await sequelize.transaction();
  try {
    const { name, description, price } = req.body;
    if (!name) return res.status(400).json({ message: 'name is required' });

    const product = await Product.create({ name, description, price }, { transaction: t });
    await Stock.create({ productId: product.id, quantity: 0 }, { transaction: t });
    await t.commit();

    const created = await Product.findByPk(product.id, { include: [{ model: Stock, as: 'stock' }] });
    return res.status(201).json(created);
  } catch (err) {
    await t.rollback();
    console.error(err);
    return res.status(500).json({ message: 'Internal server error' });
  }
};

exports.update = async (req, res) => {
  try {
    const { id } = req.params;
    const { name, description, price } = req.body;
    const product = await Product.findByPk(id);
    if (!product) return res.status(404).json({ message: 'Product not found' });

    if (name !== undefined) product.name = name;
    if (description !== undefined) product.description = description;
    if (price !== undefined) product.price = price;

    await product.save();
    const updated = await Product.findByPk(product.id, { include: [{ model: Stock, as: 'stock' }] });
    return res.json(updated);
  } catch (err) {
    console.error(err);
    return res.status(500).json({ message: 'Internal server error' });
  }
};

exports.remove = async (req, res) => {
  try {
    const { id } = req.params;
    const product = await Product.findByPk(id);
    if (!product) return res.status(404).json({ message: 'Product not found' });

    await product.destroy();
    return res.json({ message: 'Product deleted' });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ message: 'Internal server error' });
  }
};
