const { Sell, Product, User } = require('../models');

exports.index = async (req, res) => {
  try {
    const sells = await Sell.findAll({
      include: [
        { model: Product, as: 'product' },
        { model: User, as: 'cashier', attributes: ['id', 'username', 'email'] }
      ],
      order: [['createdAt', 'DESC']]
    });
    return res.json(sells);
  } catch (err) {
    console.error(err);
    return res.status(500).json({ message: 'Internal server error' });
  }
};
