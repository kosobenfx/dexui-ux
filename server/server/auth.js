const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const { query } = require('./db');

const secret = (process.env.JWT_SECRET || '').trim();

function authConfigError() {
  const err = new Error('Authentication service is not configured. Set JWT_SECRET in Render Environment Variables, then redeploy.');
  err.statusCode = 503;
  err.code = 'JWT_SECRET_MISSING';
  return err;
}

function sign(user) {
  if (!secret) throw authConfigError();
  return jwt.sign(
    { sub: user.id, role: user.role, name: user.name, email: user.email },
    secret,
    { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
  );
}

async function hash(password) { return bcrypt.hash(password, 12); }
async function compare(password, hashValue) { return bcrypt.compare(password, hashValue); }

function requireAuth(req, res, next) {
  if (!secret) return res.status(503).json({ error: 'Authentication service is not configured. Set JWT_SECRET in Render Environment Variables, then redeploy.' });
  try {
    const h = req.headers.authorization || '';
    if (!h.startsWith('Bearer ')) return res.status(401).json({ error: 'Authentication required' });
    req.user = jwt.verify(h.slice(7), secret);
    next();
  } catch (err) {
    return res.status(401).json({ error: 'Invalid or expired token' });
  }
}

function requireRole(...roles) {
  return (req, res, next) => roles.includes(req.user.role)
    ? next()
    : res.status(403).json({ error: 'Insufficient permissions' });
}

module.exports = { sign, hash, compare, requireAuth, requireRole };
