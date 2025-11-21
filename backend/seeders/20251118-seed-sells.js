'use strict';

module.exports = {
  async up(queryInterface, Sequelize) {
    // Resolve user IDs dynamically to avoid FK issues if users are seeded in different order.
    const users = await queryInterface.sequelize.query(
      `SELECT id, email FROM users WHERE email IN ('admin@test.com','kasir@test.com')`,
      { type: Sequelize.QueryTypes.SELECT }
    );

    const userByEmail = {};
    users.forEach((u) => { userByEmail[u.email] = u.id; });
    // We'll create several sells (mix of userId 1 and 2), some today and some earlier.
    const now = new Date();
    const yesterday = new Date(Date.now() - 24 * 60 * 60 * 1000);
    const lastWeek = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);

    // Prices must match the product prices in products seeder
    const price = {
      1: 65000.00,
      2: 72000.00,
      3: 55000.00,
      4: 45000.00,
      5: 35000.00,
      6: 80000.00,
      7: 120000.00,
      8: 8000.00,
      9: 15000.00,
      10: 25000.00
    };

    const records = [
      { productId: 1, userId: userByEmail['admin@test.com'] || 1, quantity_sold: 1, total_price: price[1] * 1, createdAt: now, updatedAt: now },
      { productId: 5, userId: userByEmail['kasir@test.com'] || 2, quantity_sold: 2, total_price: price[5] * 2, createdAt: now, updatedAt: now },
      { productId: 3, userId: userByEmail['admin@test.com'] || 1, quantity_sold: 1, total_price: price[3] * 1, createdAt: yesterday, updatedAt: yesterday },
      { productId: 7, userId: userByEmail['kasir@test.com'] || 2, quantity_sold: 1, total_price: price[7] * 1, createdAt: lastWeek, updatedAt: lastWeek },
      { productId: 2, userId: userByEmail['admin@test.com'] || 1, quantity_sold: 3, total_price: price[2] * 3, createdAt: yesterday, updatedAt: yesterday },
      { productId: 10, userId: userByEmail['kasir@test.com'] || 2, quantity_sold: 2, total_price: price[10] * 2, createdAt: now, updatedAt: now },
      { productId: 8, userId: userByEmail['admin@test.com'] || 1, quantity_sold: 5, total_price: price[8] * 5, createdAt: lastWeek, updatedAt: lastWeek }
    ];

    return queryInterface.bulkInsert('Sells', records, {});
  },

  async down(queryInterface, Sequelize) {
    // Remove sells matching these recent price combinations (safe for demo)
    return queryInterface.bulkDelete('Sells', {
      total_price: { [Sequelize.Op.in]: [
        65000.00,          // 1 x product 1
        35000.00 * 2,      // 2 x product 5
        55000.00,          // 1 x product 3
        120000.00,         // 1 x product 7
        72000.00 * 3,      // 3 x product 2
        25000.00 * 2,      // 2 x product 10
        8000.00 * 5        // 5 x product 8
      ] }
    }, {});
  }
};
