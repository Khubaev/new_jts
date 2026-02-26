const db = require('../db');

function auth(req, res, next) {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Требуется авторизация' });
  }
  const token = authHeader.slice(7);
  try {
    const userId = Buffer.from(token, 'base64').toString('utf8');
    const user = db.prepare('SELECT u.*, r.code as role_code, r.name as role_name FROM users u JOIN roles r ON u.role_id = r.id WHERE u.id = ?').get(userId);
    if (!user) {
      return res.status(401).json({ error: 'Неверный токен' });
    }
    req.user = user;
    next();
  } catch (e) {
    return res.status(401).json({ error: 'Неверный токен' });
  }
}

module.exports = auth;
