const { Sell, Stock, Product, sequelize, Sequelize, User } = require('../models');
const { Op } = Sequelize;

exports.summary = async (req, res) => {
  try {
    // Revenue all time
    const revenueAll = await Sell.sum('total_price') || 0;

    // Revenue today
    const startOfDay = new Date();
    startOfDay.setHours(0, 0, 0, 0);
    const revenueToday = await Sell.sum('total_price', {
      where: {
        createdAt: { [Op.gte]: startOfDay }
      }
    }) || 0;

    // Low stock (<=5)
    const lowStockRows = await Stock.findAll({
      where: { quantity: { [Op.lte]: 5 } },
      include: [{ model: Product, as: 'product', attributes: ['id', 'name'] }],
      order: [['quantity', 'ASC']],
      limit: 5
    });

    const lowStock = lowStockRows.map(s => ({
      productId: s.productId,
      name: s.product ? s.product.name : null,
      quantity: s.quantity
    }));

    // Top products by total quantity sold
    const top = await Sell.findAll({
      attributes: [
        'productId',
        [sequelize.fn('SUM', sequelize.col('quantity_sold')), 'totalSold']
      ],
      include: [{ model: Product, as: 'product', attributes: ['id', 'name'] }],
      group: ['productId', 'product.id', 'product.name'],
      order: [[sequelize.literal('totalSold'), 'DESC']],
      limit: 5,
      raw: false
    });

    const topProducts = top.map(t => ({
      productId: t.productId,
      name: t.product ? t.product.name : null,
      totalSold: parseInt((t.get && t.get('totalSold')) || t.dataValues.totalSold || 0, 10)
    }));

    return res.json({
      revenue: { allTime: Number(revenueAll) || 0, today: Number(revenueToday) || 0 },
      lowStock,
      topProducts
    });
  } catch (err) {
    console.error('Dashboard summary error:', err);
    return res.status(500).json({ message: 'Internal server error' });
  }
};
