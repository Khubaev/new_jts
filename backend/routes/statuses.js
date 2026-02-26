const express = require('express');
const { v4: uuidv4 } = require('uuid');
const db = require('../db');
const auth = require('../middleware/auth');

const router = express.Router();

router.get('/', auth, (req, res) => {
  const statuses = db.prepare('SELECT * FROM request_statuses ORDER BY sort_order, name').all();
  res.json(statuses);
});

router.post('/', auth, (req, res) => {
  if (req.user.role_code !== 'administrator' && req.user.role_code !== 'director') {
    return res.status(403).json({ error: 'Недостаточно прав' });
  }
  const { name, code, color, sort_order } = req.body;
  if (!name || !code) {
    return res.status(400).json({ error: 'Название и код обязательны' });
  }
  const id = uuidv4();
  try {
    db.prepare('INSERT INTO request_statuses (id, name, code, color, sort_order) VALUES (?, ?, ?, ?, ?)')
      .run(id, name, code, color || '#666666', sort_order ?? 0);
    res.status(201).json({ id, name, code, color: color || '#666666', sort_order: sort_order ?? 0 });
  } catch (e) {
    if (e.message.includes('UNIQUE')) {
      return res.status(400).json({ error: 'Статус с таким кодом уже существует' });
    }
    throw e;
  }
});

router.put('/:id', auth, (req, res) => {
  if (req.user.role_code !== 'administrator' && req.user.role_code !== 'director') {
    return res.status(403).json({ error: 'Недостаточно прав' });
  }
  const { name, code, color, sort_order } = req.body;
  const { id } = req.params;
  db.prepare('UPDATE request_statuses SET name = ?, code = ?, color = ?, sort_order = ? WHERE id = ?')
    .run(name || '', code || '', color || '#666666', sort_order ?? 0, id);
  res.json({ id, name, code, color, sort_order });
});

router.delete('/:id', auth, (req, res) => {
  if (req.user.role_code !== 'administrator' && req.user.role_code !== 'director') {
    return res.status(403).json({ error: 'Недостаточно прав' });
  }
  db.prepare('DELETE FROM request_statuses WHERE id = ?').run(req.params.id);
  res.status(204).send();
});

module.exports = router;
