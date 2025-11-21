'use strict';

module.exports = {
  async up(queryInterface, Sequelize) {
    return queryInterface.bulkInsert('Products', [
      { id: 1, name: 'Royal Canin Adult (Kucing) 400g', description: 'Makanan kering premium untuk kucing dewasa', price: 65000.00, createdAt: new Date(), updatedAt: new Date() },
      { id: 2, name: 'Whiskas Tuna 1.2kg', description: 'Makanan kucing rasa tuna lezat', price: 72000.00, createdAt: new Date(), updatedAt: new Date() },
      { id: 3, name: 'Pedigree Chicken (Anjing) 1kg', description: 'Makanan anjing ras kecil', price: 55000.00, createdAt: new Date(), updatedAt: new Date() },
      { id: 4, name: 'Pasir Kucing Bentonite 10L', description: 'Pasir gumpal wangi lavender', price: 45000.00, createdAt: new Date(), updatedAt: new Date() },
      { id: 5, name: 'Shampoo Anti Kutu 250ml', description: 'Efektif membasmi kutu kucing & anjing', price: 35000.00, createdAt: new Date(), updatedAt: new Date() },
      { id: 6, name: 'Vitamin Bulu & Kulit (100 tab)', description: 'Suplemen agar bulu lebat dan berkilau', price: 80000.00, createdAt: new Date(), updatedAt: new Date() },
      { id: 7, name: 'Kandang Hamster 2 Tingkat', description: 'Kandang lengkap dengan kincir mainan', price: 120000.00, createdAt: new Date(), updatedAt: new Date() },
      { id: 8, name: 'Pelet Ikan Takari 100g', description: 'Makanan ikan hias floating type', price: 8000.00, createdAt: new Date(), updatedAt: new Date() },
      { id: 9, name: 'Kalung Kucing Lonceng', description: 'Kalung nilon dengan lonceng berbunyi', price: 15000.00, createdAt: new Date(), updatedAt: new Date() },
      { id: 10, name: 'Mainan Tulang Karet', description: 'Mainan gigitan untuk anjing', price: 25000.00, createdAt: new Date(), updatedAt: new Date() }
    ], {});
  },

  async down(queryInterface, Sequelize) {
    return queryInterface.bulkDelete('Products', { id: { [Sequelize.Op.in]: [1,2,3,4,5,6,7,8,9,10] } }, {});
  }
};
