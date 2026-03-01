const config = require('../config');
const db = require('../db');

function validateRequestCreate(req, res, next) {
  const { title, description, priority, roomId, responsibleUserId, requestTypeId, photoBytes } = req.body;
  const err = [];

  if (!title || typeof title !== 'string') {
    err.push('Заголовок обязателен');
  } else if (title.length > config.TITLE_MAX_LENGTH) {
    err.push(`Заголовок не более ${config.TITLE_MAX_LENGTH} символов`);
  }

  if (!description || typeof description !== 'string') {
    err.push('Описание обязательно');
  } else if (description.length > config.DESCRIPTION_MAX_LENGTH) {
    err.push(`Описание не более ${config.DESCRIPTION_MAX_LENGTH} символов`);
  }

  if (priority && !config.PRIORITY_VALUES.includes(priority)) {
    err.push('Недопустимый приоритет');
  }

  if (roomId) {
    const room = db.prepare('SELECT id FROM rooms WHERE id = ?').get(roomId);
    if (!room) err.push('Комната не найдена');
  }

  if (responsibleUserId) {
    const user = db.prepare('SELECT id FROM users WHERE id = ?').get(responsibleUserId);
    if (!user) err.push('Ответственный не найден');
  }

  if (requestTypeId) {
    const rt = db.prepare('SELECT id FROM request_types WHERE id = ?').get(requestTypeId);
    if (!rt) err.push('Тип заявки не найден');
  }

  if (photoBytes && Array.isArray(photoBytes)) {
    if (photoBytes.length > config.MAX_PHOTOS_PER_REQUEST) {
      err.push(`Не более ${config.MAX_PHOTOS_PER_REQUEST} фото`);
    }
    for (let i = 0; i < photoBytes.length; i++) {
      const b = photoBytes[i];
      let buf;
      if (typeof b === 'string') {
        buf = Buffer.from(b, 'base64');
      } else if (Buffer.isBuffer(b) || Array.isArray(b)) {
        buf = Buffer.from(b);
      } else {
        err.push(`Фото ${i + 1}: неверный формат`);
        break;
      }
      if (buf.length > config.MAX_PHOTO_SIZE) {
        err.push(`Фото ${i + 1}: размер не более 5 MB`);
        break;
      }
      const jpeg = buf[0] === 0xFF && buf[1] === 0xD8;
      const png = buf[0] === 0x89 && buf[1] === 0x50 && buf[2] === 0x4E;
      if (!jpeg && !png) {
        err.push(`Фото ${i + 1}: только JPEG или PNG`);
        break;
      }
    }
  }

  if (err.length > 0) {
    return res.status(400).json({ error: err.join('; ') });
  }
  next();
}

function validateRequestUpdate(req, res, next) {
  const { title, description, priority, roomId, responsibleUserId, requestTypeId, photoBytes } = req.body;

  if (title !== undefined) {
    if (typeof title !== 'string' || title.length > config.TITLE_MAX_LENGTH) {
      return res.status(400).json({ error: `Заголовок не более ${config.TITLE_MAX_LENGTH} символов` });
    }
  }
  if (description !== undefined) {
    if (typeof description !== 'string' || description.length > config.DESCRIPTION_MAX_LENGTH) {
      return res.status(400).json({ error: `Описание не более ${config.DESCRIPTION_MAX_LENGTH} символов` });
    }
  }
  if (priority !== undefined && priority !== null && !config.PRIORITY_VALUES.includes(priority)) {
    return res.status(400).json({ error: 'Недопустимый приоритет' });
  }
  if (roomId !== undefined && roomId !== null) {
    const room = db.prepare('SELECT id FROM rooms WHERE id = ?').get(roomId);
    if (!room) return res.status(400).json({ error: 'Комната не найдена' });
  }
  if (responsibleUserId !== undefined && responsibleUserId !== null) {
    const user = db.prepare('SELECT id FROM users WHERE id = ?').get(responsibleUserId);
    if (!user) return res.status(400).json({ error: 'Ответственный не найден' });
  }
  if (requestTypeId !== undefined && requestTypeId !== null) {
    const rt = db.prepare('SELECT id FROM request_types WHERE id = ?').get(requestTypeId);
    if (!rt) return res.status(400).json({ error: 'Тип заявки не найден' });
  }

  if (photoBytes && Array.isArray(photoBytes)) {
    if (photoBytes.length > config.MAX_PHOTOS_PER_REQUEST) {
      return res.status(400).json({ error: `Не более ${config.MAX_PHOTOS_PER_REQUEST} фото` });
    }
    for (let i = 0; i < photoBytes.length; i++) {
      const b = photoBytes[i];
      let buf;
      if (typeof b === 'string') buf = Buffer.from(b, 'base64');
      else if (Buffer.isBuffer(b) || Array.isArray(b)) buf = Buffer.from(b);
      else return res.status(400).json({ error: `Фото ${i + 1}: неверный формат` });
      if (buf.length > config.MAX_PHOTO_SIZE) {
        return res.status(400).json({ error: `Фото ${i + 1}: размер не более 5 MB` });
      }
      const jpeg = buf[0] === 0xFF && buf[1] === 0xD8;
      const png = buf[0] === 0x89 && buf[1] === 0x50 && buf[2] === 0x4E;
      if (!jpeg && !png) {
        return res.status(400).json({ error: `Фото ${i + 1}: только JPEG или PNG` });
      }
    }
  }

  next();
}

module.exports = { validateRequestCreate, validateRequestUpdate };
