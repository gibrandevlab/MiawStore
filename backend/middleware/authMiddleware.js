const jwt = require('jsonwebtoken');

const JWT_SECRET = process.env.JWT_SECRET || 'change_this_secret';

exports.isAdmin = (req, res, next) => {
  const authHeader = req.headers.authorization || '';
  const token = authHeader.startsWith('Bearer ') ? authHeader.slice(7) : null;
  if (!token) return res.status(401).json({ message: 'Authorization token required' });

  try {
    const payload = jwt.verify(token, JWT_SECRET);
    if (payload.role && payload.role === 'admin') {
      req.user = payload;
      return next();
    }
    return res.status(403).json({ message: 'Forbidden: admin access required' });
  } catch (err) {
    return res.status(401).json({ message: 'Invalid or expired token' });
  }
};

exports.isAuthenticated = (req, res, next) => {
  const authHeader = req.headers.authorization || '';
  const token = authHeader.startsWith('Bearer ') ? authHeader.slice(7) : null;
  if (!token) return res.status(401).json({ message: 'Authorization token required' });

  try {
    const payload = jwt.verify(token, JWT_SECRET);
    req.user = payload;
    return next();
  } catch (err) {
    return res.status(401).json({ message: 'Invalid or expired token' });
  }
};
