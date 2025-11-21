module.exports = (sequelize, DataTypes) => {
  const Product = sequelize.define('Product', {
    name: {
      type: DataTypes.STRING,
      allowNull: false
    },
    description: {
      type: DataTypes.TEXT,
      allowNull: true
    },
    price: {
      type: DataTypes.DECIMAL(10, 2),
      allowNull: false,
      defaultValue: 0.00
    }
  }, {
    tableName: 'Products',
    timestamps: true
  });

  Product.associate = (models) => {
    Product.hasOne(models.Stock, { foreignKey: 'productId', as: 'stock', onDelete: 'CASCADE' });
    Product.hasMany(models.Sell, { foreignKey: 'productId', as: 'sells', onDelete: 'CASCADE' });
  };

  return Product;
};
