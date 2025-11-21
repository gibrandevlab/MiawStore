'use strict';

module.exports = {
  async up(queryInterface, Sequelize) {
    return queryInterface.bulkInsert('Stocks', [
      { productId: 1, quantity: 3, createdAt: new Date(), updatedAt: new Date() },
      { productId: 2, quantity: 20, createdAt: new Date(), updatedAt: new Date() },
      { productId: 3, quantity: 15, createdAt: new Date(), updatedAt: new Date() },
      { productId: 4, quantity: 30, createdAt: new Date(), updatedAt: new Date() },
      { productId: 5, quantity: 2, createdAt: new Date(), updatedAt: new Date() },
      { productId: 6, quantity: 12, createdAt: new Date(), updatedAt: new Date() },
      { productId: 7, quantity: 18, createdAt: new Date(), updatedAt: new Date() },
      { productId: 8, quantity: 50, createdAt: new Date(), updatedAt: new Date() },
      { productId: 9, quantity: 25, createdAt: new Date(), updatedAt: new Date() },
      { productId: 10, quantity: 40, createdAt: new Date(), updatedAt: new Date() }
    ], {});
  },

  async down(queryInterface, Sequelize) {
    return queryInterface.bulkDelete('Stocks', { productId: { [Sequelize.Op.in]: [1,2,3,4,5,6,7,8,9,10] } }, {});
  }
};
