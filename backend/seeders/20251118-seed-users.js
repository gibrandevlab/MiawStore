"use strict";

const bcrypt = require('bcryptjs');

module.exports = {
  async up(queryInterface, Sequelize) {
    const passwordAdmin = await bcrypt.hash('admin123', 10);
    const passwordKasir = await bcrypt.hash('kasir123', 10);

    return queryInterface.bulkInsert('users', [
      {
        username: 'admin',
        email: 'admin@example.com',
        password: passwordAdmin,
        role: 'admin',
        createdAt: new Date(),
        updatedAt: new Date()
      },
      {
        username: 'kasir1',
        email: 'kasir1@example.com',
        password: passwordKasir,
        role: 'kasir',
        createdAt: new Date(),
        updatedAt: new Date()
      }
    ], {});
  },

  async down(queryInterface, Sequelize) {
    return queryInterface.bulkDelete('users', {
      email: { [Sequelize.Op.or]: ['admin@example.com', 'kasir1@example.com'] }
    }, {});
  }
};
