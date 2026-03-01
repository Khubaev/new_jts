const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const db = require('../db');
const config = require('../config');

const router = express.Router();

router.post('/login', (req, res) => {
  const { login, password } = req.body;
  if (!login || !password) {
    return res.status(400).json({ error: 'Логин и пароль обязательны' });
  }
  const user = db.prepare(`
    SELECT u.id, u.login, u.name, u.password_hash, r.code as role_code, r.name as role_name
    FROM users u
    JOIN roles r ON u.role_id = r.id
    WHERE LOWER(u.login) = LOWER(?)
  `).get(login);
  if (!user) {
    return res.status(401).json({ error: 'Неверный логин или пароль' });
  }
  if (!bcrypt.compareSync(password, user.password_hash)) {
    return res.status(401).json({ error: 'Неверный логин или пароль' });
  }
  const token = jwt.sign({ userId: user.id }, config.JWT_SECRET, { expiresIn: config.JWT_EXPIRES_IN });
  res.json({
    user: {
      id: user.id,
      login: user.login,
      name: user.name,
      role: user.role_code,
    },
    token,
  });
});

module.exports = router;
