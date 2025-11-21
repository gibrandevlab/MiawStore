module.exports = (sequelize, DataTypes) => {
  const Stock = sequelize.define('Stock', {
    quantity: {
      type: DataTypes.INTEGER,
      allowNull: false,
      defaultValue: 0
    }
  }, {
    tableName: 'Stocks',
    timestamps: true
  });

  Stock.associate = (models) => {
    Stock.belongsTo(models.Product, { foreignKey: 'productId', as: 'product' });
  };

  return Stock;
};
