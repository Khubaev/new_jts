const Database = require('better-sqlite3');
const path = require('path');

const dbPath = path.join(__dirname, 'data', 'requests.db');
const db = new Database(dbPath);

module.exports = db;
