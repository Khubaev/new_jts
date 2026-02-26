const express = require('express');
const { v4: uuidv4 } = require('uuid');
const db = require('../db');

const router = express.Router();

function canSeeAll(user) {
  return user.role_code === 'administrator' || user.role_code === 'director';
}

function canEditRequest(user, request) {
  if (canSeeAll(user)) return true;
  return request.requestor_id === user.id;
}

function canChangeStatus(user, request) {
  if (canSeeAll(user)) return true;
  return request.requestor_id === user.id || request.responsible_id === user.id;
}

function canDeleteRequest(user, request) {
  if (canSeeAll(user)) return true;
  return request.requestor_id === user.id;
}

router.get('/', (req, res) => {
  const { show_completed } = req.query;
  const user = req.user;

  let sql = `
    SELECT r.*, s.name as status_name, s.code as status_code, s.color as status_color,
      rm.number as room_number,
      u1.name as requestor_name, u2.name as responsible_name,
      rt.name as request_type_name
    FROM requests r
    JOIN request_statuses s ON r.status_id = s.id
    LEFT JOIN rooms rm ON r.room_id = rm.id
    JOIN users u1 ON r.requestor_id = u1.id
    LEFT JOIN users u2 ON r.responsible_id = u2.id
    LEFT JOIN request_types rt ON r.request_type_id = rt.id
  `;
  const params = [];

  if (!canSeeAll(user)) {
    sql += ' WHERE (r.requestor_id = ? OR r.responsible_id = ?)';
    params.push(user.id, user.id);
  }

  if (show_completed !== 'true') {
    sql += (params.length ? ' AND' : ' WHERE') + " s.code != 'completed'";
  }

  sql += ' ORDER BY r.created_at DESC';

  const rows = params.length
    ? db.prepare(sql).all(...params)
    : db.prepare(sql).all();

  const requests = rows.map(row => ({
    id: row.id,
    title: row.title,
    description: row.description,
    status: { id: row.status_id, name: row.status_name, code: row.status_code, color: row.status_color },
    priority: row.priority,
    roomNumber: row.room_number,
    roomId: row.room_id,
    requestorUserId: row.requestor_id,
    requestorName: row.requestor_name,
    responsibleUserId: row.responsible_id,
    responsibleName: row.responsible_name,
    rating: row.rating,
    requestType: row.request_type_name,
    requestTypeId: row.request_type_id,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  }));

  res.json(requests);
});

router.get('/:id', (req, res) => {
  const user = req.user;
  const row = db.prepare(`
    SELECT r.*, s.name as status_name, s.code as status_code, s.color as status_color,
      rm.number as room_number, rm.id as room_id,
      u1.name as requestor_name, u2.name as responsible_name,
      rt.name as request_type_name, rt.id as request_type_id
    FROM requests r
    JOIN request_statuses s ON r.status_id = s.id
    LEFT JOIN rooms rm ON r.room_id = rm.id
    JOIN users u1 ON r.requestor_id = u1.id
    LEFT JOIN users u2 ON r.responsible_id = u2.id
    LEFT JOIN request_types rt ON r.request_type_id = rt.id
    WHERE r.id = ?
  `).get(req.params.id);

  if (!row) {
    return res.status(404).json({ error: 'Заявка не найдена' });
  }

  if (!canSeeAll(user) && row.requestor_id !== user.id && row.responsible_id !== user.id) {
    return res.status(403).json({ error: 'Нет доступа' });
  }

  const photos = db.prepare('SELECT id, data_base64, sort_order FROM request_photos WHERE request_id = ? ORDER BY sort_order').all(req.params.id);

  res.json({
    id: row.id,
    title: row.title,
    description: row.description,
    status: { id: row.status_id, name: row.status_name, code: row.status_code, color: row.status_color },
    priority: row.priority,
    roomNumber: row.room_number,
    roomId: row.room_id,
    requestorUserId: row.requestor_id,
    requestorName: row.requestor_name,
    responsibleUserId: row.responsible_id,
    responsibleName: row.responsible_name,
    rating: row.rating,
    requestType: row.request_type_name,
    requestTypeId: row.request_type_id,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
    photoBase64: photos.map(p => p.data_base64),
  });
});

router.post('/', (req, res) => {
  const user = req.user;
  const { title, description, priority, roomId, responsibleUserId, requestTypeId, photoBytes } = req.body;

  if (!title || !description) {
    return res.status(400).json({ error: 'Заголовок и описание обязательны' });
  }

  const statusNew = db.prepare("SELECT id FROM request_statuses WHERE code = 'new'").get();
  if (!statusNew) {
    return res.status(500).json({ error: 'Статус "Новая" не найден' });
  }

  const id = uuidv4();
  const now = new Date().toISOString();

  db.prepare(`
    INSERT INTO requests (id, title, description, status_id, priority, room_id, requestor_id, responsible_id, request_type_id, created_at, updated_at)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  `).run(id, title, description, statusNew.id, priority || null, roomId || null, user.id, responsibleUserId || null, requestTypeId || null, now, now);

  if (photoBytes && Array.isArray(photoBytes) && photoBytes.length > 0) {
    const insertPhoto = db.prepare('INSERT INTO request_photos (id, request_id, data_base64, sort_order) VALUES (?, ?, ?, ?)');
    photoBytes.forEach((b, i) => {
      let base64;
      if (typeof b === 'string') base64 = b;
      else if (Array.isArray(b) || Buffer.isBuffer(b)) base64 = Buffer.from(b).toString('base64');
      else base64 = Buffer.from(b).toString('base64');
      insertPhoto.run(uuidv4(), id, base64, i);
    });
  }

  const row = db.prepare(`
    SELECT r.*, s.name as status_name, s.code as status_code, rm.number as room_number,
      u1.name as requestor_name, u2.name as responsible_name, rt.name as request_type_name
    FROM requests r
    JOIN request_statuses s ON r.status_id = s.id
    LEFT JOIN rooms rm ON r.room_id = rm.id
    JOIN users u1 ON r.requestor_id = u1.id
    LEFT JOIN users u2 ON r.responsible_id = u2.id
    LEFT JOIN request_types rt ON r.request_type_id = rt.id
    WHERE r.id = ?
  `).get(id);

  res.status(201).json({
    id: row.id,
    title: row.title,
    description: row.description,
    status: { id: row.status_id, name: row.status_name, code: row.status_code },
    roomNumber: row.room_number,
    roomId: row.room_id,
    requestorUserId: row.requestor_id,
    requestorName: row.requestor_name,
    responsibleUserId: row.responsible_id,
    responsibleName: row.responsible_name,
    requestType: row.request_type_name,
    requestTypeId: row.request_type_id,
    createdAt: row.created_at,
  });
});

router.put('/:id', (req, res) => {
  const user = req.user;
  const request = db.prepare('SELECT * FROM requests WHERE id = ?').get(req.params.id);
  if (!request) {
    return res.status(404).json({ error: 'Заявка не найдена' });
  }
  if (!canEditRequest(user, request)) {
    return res.status(403).json({ error: 'Только постановщик может редактировать заявку' });
  }

  const { title, description, priority, roomId, responsibleUserId, requestTypeId, photoBytes } = req.body;
  const now = new Date().toISOString();

  db.prepare(`
    UPDATE requests SET title = ?, description = ?, priority = ?, room_id = ?, responsible_id = ?, request_type_id = ?, updated_at = ?
    WHERE id = ?
  `).run(
    title ?? request.title,
    description ?? request.description,
    priority ?? request.priority,
    roomId ?? request.room_id,
    responsibleUserId ?? request.responsible_id,
    requestTypeId ?? request.request_type_id,
    now,
    req.params.id
  );

  db.prepare('DELETE FROM request_photos WHERE request_id = ?').run(req.params.id);
  if (photoBytes && Array.isArray(photoBytes) && photoBytes.length > 0) {
    const insertPhoto = db.prepare('INSERT INTO request_photos (id, request_id, data_base64, sort_order) VALUES (?, ?, ?, ?)');
    photoBytes.forEach((b, i) => {
      let base64;
      if (typeof b === 'string') base64 = b;
      else base64 = Buffer.from(b).toString('base64');
      insertPhoto.run(uuidv4(), req.params.id, base64, i);
    });
  }

  res.json({ ok: true });
});

router.patch('/:id/status', (req, res) => {
  const user = req.user;
  const request = db.prepare('SELECT * FROM requests WHERE id = ?').get(req.params.id);
  if (!request) {
    return res.status(404).json({ error: 'Заявка не найдена' });
  }
  if (!canChangeStatus(user, request)) {
    return res.status(403).json({ error: 'Нет прав на изменение статуса' });
  }

  const { statusId } = req.body;
  if (!statusId) {
    return res.status(400).json({ error: 'statusId обязателен' });
  }

  const status = db.prepare('SELECT id FROM request_statuses WHERE id = ?').get(statusId);
  if (!status) {
    return res.status(400).json({ error: 'Статус не найден' });
  }

  const now = new Date().toISOString();
  db.prepare('UPDATE requests SET status_id = ?, updated_at = ? WHERE id = ?').run(statusId, now, req.params.id);
  res.json({ ok: true });
});

router.patch('/:id/rating', (req, res) => {
  const user = req.user;
  if (!canSeeAll(user)) {
    return res.status(403).json({ error: 'Только администратор или директор может оценивать' });
  }
  const { rating } = req.body;
  const now = new Date().toISOString();
  db.prepare('UPDATE requests SET rating = ?, updated_at = ? WHERE id = ?').run(rating ?? null, now, req.params.id);
  res.json({ ok: true });
});

router.delete('/:id', (req, res) => {
  const user = req.user;
  const request = db.prepare('SELECT * FROM requests WHERE id = ?').get(req.params.id);
  if (!request) {
    return res.status(404).json({ error: 'Заявка не найдена' });
  }
  if (!canDeleteRequest(user, request)) {
    return res.status(403).json({ error: 'Только постановщик может удалить заявку' });
  }
  db.prepare('DELETE FROM request_photos WHERE request_id = ?').run(req.params.id);
  db.prepare('DELETE FROM requests WHERE id = ?').run(req.params.id);
  res.status(204).send();
});

module.exports = router;
