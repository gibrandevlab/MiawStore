const fs = require('fs');
const path = require('path');
const Sequelize = require('sequelize');
const basename = path.basename(__filename);
const env = process.env.NODE_ENV || 'development';
const config = require(path.resolve(__dirname, '..', 'config', 'config.js'))[env];

const db = {};

const sequelize = new Sequelize(config.database, config.username, config.password, config);

db.sequelize = sequelize;
db.Sequelize = Sequelize;

// Load models
db.User = require('./user')(sequelize, Sequelize.DataTypes);
db.Product = require('./product')(sequelize, Sequelize.DataTypes);
db.Stock = require('./stock')(sequelize, Sequelize.DataTypes);
db.Sell = require('./sell')(sequelize, Sequelize.DataTypes);

// Run associations if defined
Object.keys(db).forEach((modelName) => {
	if (db[modelName] && typeof db[modelName].associate === 'function') {
		db[modelName].associate(db);
	}
});

module.exports = db;
