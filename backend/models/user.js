module.exports = (sequelize, DataTypes) => {
  const User = sequelize.define('User', {
    username: {
      type: DataTypes.STRING,
      allowNull: false,
      unique: true
    },
    email: {
      type: DataTypes.STRING,
      allowNull: false,
      unique: true,
      validate: { isEmail: true }
    },
    password: {
      type: DataTypes.STRING,
      allowNull: false
    },
    role: {
      type: DataTypes.ENUM('admin', 'kasir'),
      allowNull: false,
      defaultValue: 'kasir'
    }
  }, {
    tableName: 'users',
    timestamps: true
  });
  User.associate = (models) => {
    User.hasMany(models.Sell, { foreignKey: 'userId', as: 'sells' });
  };

  return User;
};
