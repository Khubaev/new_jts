const Database = require('better-sqlite3');
const path = require('path');
const fs = require('fs');
const bcrypt = require('bcryptjs');
const { v4: uuidv4 } = require('uuid');

const dataDir = path.join(__dirname, '..', 'data');
if (!fs.existsSync(dataDir)) {
  fs.mkdirSync(dataDir, { recursive: true });
}

const dbPath = path.join(dataDir, 'requests.db');
const db = new Database(dbPath);

db.exec(`
  CREATE TABLE IF NOT EXISTS roles (
    id TEXT PRIMARY KEY,
    name TEXT UNIQUE NOT NULL,
    code TEXT UNIQUE NOT NULL
  );

  CREATE TABLE IF NOT EXISTS rooms (
    id TEXT PRIMARY KEY,
    number TEXT UNIQUE NOT NULL,
    description TEXT
  );

  CREATE TABLE IF NOT EXISTS request_statuses (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    code TEXT UNIQUE NOT NULL,
    color TEXT DEFAULT '#666666',
    sort_order INTEGER DEFAULT 0
  );

  CREATE TABLE IF NOT EXISTS request_types (
    id TEXT PRIMARY KEY,
    name TEXT UNIQUE NOT NULL,
    sort_order INTEGER DEFAULT 0
  );

  CREATE TABLE IF NOT EXISTS users (
    id TEXT PRIMARY KEY,
    login TEXT UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    name TEXT NOT NULL,
    role_id TEXT NOT NULL,
    FOREIGN KEY (role_id) REFERENCES roles(id)
  );

  CREATE TABLE IF NOT EXISTS requests (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    status_id TEXT NOT NULL,
    priority TEXT,
    room_id TEXT,
    requestor_id TEXT NOT NULL,
    responsible_id TEXT,
    rating INTEGER,
    request_type_id TEXT,
    created_at TEXT NOT NULL,
    updated_at TEXT,
    FOREIGN KEY (status_id) REFERENCES request_statuses(id),
    FOREIGN KEY (room_id) REFERENCES rooms(id),
    FOREIGN KEY (requestor_id) REFERENCES users(id),
    FOREIGN KEY (responsible_id) REFERENCES users(id),
    FOREIGN KEY (request_type_id) REFERENCES request_types(id)
  );

  CREATE TABLE IF NOT EXISTS request_photos (
    id TEXT PRIMARY KEY,
    request_id TEXT NOT NULL,
    data_base64 TEXT NOT NULL,
    sort_order INTEGER DEFAULT 0,
    FOREIGN KEY (request_id) REFERENCES requests(id) ON DELETE CASCADE
  );

  CREATE INDEX IF NOT EXISTS idx_requests_status ON requests(status_id);
  CREATE INDEX IF NOT EXISTS idx_requests_requestor ON requests(requestor_id);
  CREATE INDEX IF NOT EXISTS idx_requests_responsible ON requests(responsible_id);
  CREATE INDEX IF NOT EXISTS idx_requests_created ON requests(created_at);
`);

const roles = [
  { id: 'r1', name: 'Администратор', code: 'administrator' },
  { id: 'r2', name: 'Директор', code: 'director' },
  { id: 'r3', name: 'Пользователь', code: 'user' },
];

const statuses = [
  { id: 's1', name: 'Новая', code: 'new', color: '#2196F3', sort_order: 1 },
  { id: 's2', name: 'В работе', code: 'in_progress', color: '#FF9800', sort_order: 2 },
  { id: 's3', name: 'Выполнена', code: 'completed', color: '#4CAF50', sort_order: 3 },
  { id: 's4', name: 'Отменена', code: 'cancelled', color: '#9E9E9E', sort_order: 4 },
];

const requestTypes = [
  { id: 't1', name: 'Ремонт', sort_order: 1 },
  { id: 't2', name: 'Установка ПО', sort_order: 2 },
  { id: 't3', name: 'Настройка', sort_order: 3 },
  { id: 't4', name: 'Консультация', sort_order: 4 },
  { id: 't5', name: 'Закупка', sort_order: 5 },
  { id: 't6', name: 'Другое', sort_order: 6 },
];

const rooms = [
  { id: 'rm1', number: '101', description: 'Бухгалтерия' },
  { id: 'rm2', number: '205', description: 'Отдел кадров' },
  { id: 'rm3', number: '310', description: 'ИТ отдел' },
  { id: 'rm4', number: '102', description: '' },
  { id: 'rm5', number: '201', description: '' },
];

const insertRole = db.prepare('INSERT OR IGNORE INTO roles (id, name, code) VALUES (?, ?, ?)');
const insertStatus = db.prepare('INSERT OR IGNORE INTO request_statuses (id, name, code, color, sort_order) VALUES (?, ?, ?, ?, ?)');
const insertType = db.prepare('INSERT OR IGNORE INTO request_types (id, name, sort_order) VALUES (?, ?, ?)');
const insertRoom = db.prepare('INSERT OR IGNORE INTO rooms (id, number, description) VALUES (?, ?, ?)');

roles.forEach(r => insertRole.run(r.id, r.name, r.code));
statuses.forEach(s => insertStatus.run(s.id, s.name, s.code, s.color, s.sort_order));
requestTypes.forEach(t => insertType.run(t.id, t.name, t.sort_order));
rooms.forEach(r => insertRoom.run(r.id, r.number, r.description || ''));

const userCount = db.prepare('SELECT COUNT(*) as c FROM users').get();
if (userCount.c === 0) {
  const hash1 = bcrypt.hashSync('admin123', 10);
  const hash2 = bcrypt.hashSync('director123', 10);
  const hash3 = bcrypt.hashSync('user123', 10);
  const insertUser = db.prepare('INSERT INTO users (id, login, password_hash, name, role_id) VALUES (?, ?, ?, ?, ?)');
  insertUser.run('u1', 'admin', hash1, 'Администратор', 'r1');
  insertUser.run('u2', 'director', hash2, 'Директор', 'r2');
  insertUser.run('u3', 'ivanov', hash3, 'Иванов И.И.', 'r3');
  insertUser.run('u4', 'petrov', hash3, 'Петров П.П.', 'r3');
  console.log('Users created');
}

console.log('Database initialized at', dbPath);
db.close();
