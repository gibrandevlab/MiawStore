module.exports = (sequelize, DataTypes) => {
  const Sell = sequelize.define('Sell', {
    userId: {
      type: DataTypes.INTEGER,
      allowNull: true
    },
    quantity_sold: {
      type: DataTypes.INTEGER,
      allowNull: false
    },
    total_price: {
      type: DataTypes.DECIMAL(10, 2),
      allowNull: false
    }
  }, {
    tableName: 'Sells',
    timestamps: true
  });

  Sell.associate = (models) => {
    Sell.belongsTo(models.Product, { foreignKey: 'productId', as: 'product' });
    Sell.belongsTo(models.User, { foreignKey: 'userId', as: 'cashier' });
  };

  return Sell;
};
