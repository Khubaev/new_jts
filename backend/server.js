const express = require('express');
const cors = require('cors');
const path = require('path');
const fs = require('fs');

const dataDir = path.join(__dirname, 'data');
if (!fs.existsSync(dataDir)) {
  fs.mkdirSync(dataDir, { recursive: true });
}

const db = require('./db');
const auth = require('./middleware/auth');
const routes = require('./routes');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json({ limit: '50mb' }));

app.use('/api/auth', routes.auth);
app.use('/api/rooms', auth, routes.rooms);
app.use('/api/statuses', auth, routes.statuses);
app.use('/api/types', auth, routes.types);
app.use('/api/users', auth, routes.users);
app.use('/api/requests', auth, routes.requests);

app.get('/api/health', (req, res) => {
  res.json({ ok: true });
});

app.listen(PORT, () => {
  console.log(`Server running on http://localhost:${PORT}`);
});
