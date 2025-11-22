const { Stock, Product } = require('../models');

// Return stocks where quantity <= 5 (include product)
exports.index = async (req, res) => {
  try {
    const low = await Stock.findAll({
      where: { quantity: { [require('sequelize').Op.lte]: 5 } },
      include: [{ model: Product, as: 'product' }],
      order: [['quantity', 'ASC']]
    });

    return res.json(low);
  } catch (err) {
    console.error(err);
    return res.status(500).json({ message: 'Internal server error' });
  }
};
