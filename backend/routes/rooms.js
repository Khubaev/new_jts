const express = require('express');
const { v4: uuidv4 } = require('uuid');
const db = require('../db');
const auth = require('../middleware/auth');

const router = express.Router();

router.get('/', auth, (req, res) => {
  const rooms = db.prepare('SELECT * FROM rooms ORDER BY number').all();
  res.json(rooms);
});

router.post('/', auth, (req, res) => {
  if (req.user.role_code !== 'administrator' && req.user.role_code !== 'director') {
    return res.status(403).json({ error: 'Недостаточно прав' });
  }
  const { number, description } = req.body;
  if (!number) {
    return res.status(400).json({ error: 'Номер комнаты обязателен' });
  }
  const id = uuidv4();
  try {
    db.prepare('INSERT INTO rooms (id, number, description) VALUES (?, ?, ?)').run(id, number, description || '');
    res.status(201).json({ id, number, description: description || '' });
  } catch (e) {
    if (e.message.includes('UNIQUE')) {
      return res.status(400).json({ error: 'Комната с таким номером уже существует' });
    }
    throw e;
  }
});

router.put('/:id', auth, (req, res) => {
  if (req.user.role_code !== 'administrator' && req.user.role_code !== 'director') {
    return res.status(403).json({ error: 'Недостаточно прав' });
  }
  const { number, description } = req.body;
  const { id } = req.params;
  try {
    db.prepare('UPDATE rooms SET number = ?, description = ? WHERE id = ?').run(number || '', description || '', id);
    res.json({ id, number, description });
  } catch (e) {
    if (e.message.includes('UNIQUE')) {
      return res.status(400).json({ error: 'Комната с таким номером уже существует' });
    }
    throw e;
  }
});

router.delete('/:id', auth, (req, res) => {
  if (req.user.role_code !== 'administrator' && req.user.role_code !== 'director') {
    return res.status(403).json({ error: 'Недостаточно прав' });
  }
  db.prepare('DELETE FROM rooms WHERE id = ?').run(req.params.id);
  res.status(204).send();
});

module.exports = router;
