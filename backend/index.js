const express = require('express');
const app = express();
const port = process.env.PORT || 3000;

const { sequelize } = require('./models');
const authRouter = require('./routes/auth');
const adminRouter = require('./routes/admin');
const transactionRouter = require('./routes/transaction');
const productsRouter = require('./routes/products');

app.use(express.json());

app.get('/', (req, res) => res.send('Miaw backend is up'));

app.use('/api/auth', authRouter);
app.use('/api/admin', adminRouter);
// Public products endpoint for POS / kasir
app.use('/api/products', productsRouter);
// Transaction endpoint for creating sells (POS)
app.use('/api/transaction', transactionRouter);

async function start() {
  try {
    await sequelize.authenticate();
    console.log('Database connection established.');
    // Bind to 0.0.0.0 so the server is reachable from other devices on the LAN
    app.listen(port, '0.0.0.0', () => console.log(`Server running on http://192.168.137.1:${port}`));
  } catch (err) {
    console.error('Unable to connect to DB:', err);
    process.exit(1);
  }
}

start();
