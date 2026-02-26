const express = require('express');
const bcrypt = require('bcryptjs');
const { v4: uuidv4 } = require('uuid');
const db = require('../db');

const router = express.Router();

router.get('/', (req, res) => {
  if (req.user.role_code !== 'administrator' && req.user.role_code !== 'director') {
    return res.status(403).json({ error: 'Недостаточно прав' });
  }
  const users = db.prepare(`
    SELECT u.id, u.login, u.name, u.role_id, r.code as role_code, r.name as role_name
    FROM users u
    JOIN roles r ON u.role_id = r.id
    ORDER BY u.name
  `).all();
  res.json(users);
});

router.get('/for-responsible', (req, res) => {
  const users = db.prepare(`
    SELECT u.id, u.login, u.name
    FROM users u
    JOIN roles r ON u.role_id = r.id
    WHERE r.code = 'user'
    ORDER BY u.name
  `).all();
  res.json(users);
});

router.post('/', (req, res) => {
  if (req.user.role_code !== 'administrator' && req.user.role_code !== 'director') {
    return res.status(403).json({ error: 'Недостаточно прав' });
  }
  const { login, password, name, role_id } = req.body;
  if (!login || !password || !name || !role_id) {
    return res.status(400).json({ error: 'Все поля обязательны' });
  }
  const id = uuidv4();
  const hash = bcrypt.hashSync(password, 10);
  try {
    db.prepare('INSERT INTO users (id, login, password_hash, name, role_id) VALUES (?, ?, ?, ?, ?)')
      .run(id, login, hash, name, role_id);
    const user = db.prepare('SELECT u.id, u.login, u.name, r.code as role_code FROM users u JOIN roles r ON u.role_id = r.id WHERE u.id = ?').get(id);
    res.status(201).json(user);
  } catch (e) {
    if (e.message.includes('UNIQUE')) {
      return res.status(400).json({ error: 'Пользователь с таким логином уже существует' });
    }
    throw e;
  }
});

module.exports = router;
