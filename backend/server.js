require('dotenv').config();
const express = require('express');
const cors = require('cors');
const rateLimit = require('express-rate-limit');
const path = require('path');
const fs = require('fs');

const config = require('./config');

const dataDir = path.join(__dirname, 'data');
if (!fs.existsSync(dataDir)) {
  fs.mkdirSync(dataDir, { recursive: true });
}

const db = require('./db');
const auth = require('./middleware/auth');
const routes = require('./routes');

const app = express();
const PORT = process.env.PORT || 3000;

const corsOptions = process.env.CORS_ORIGINS
  ? {
      origin: (origin, cb) => {
        if (!origin) return cb(null, true);
        const allowed = process.env.CORS_ORIGINS.split(',').map(s => s.trim());
        cb(null, allowed.includes(origin));
      },
    }
  : {};

app.use(cors(corsOptions));

app.use(express.json({ limit: config.BODY_LIMIT }));

app.use('/api/auth/login', rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 5,
  handler: (req, res) => {
    res.status(429).json({ error: 'Слишком много попыток. Попробуйте через 15 минут.' });
  },
}));

app.use('/api/auth', routes.auth);
app.use('/api/rooms', auth, routes.rooms);
app.use('/api/statuses', auth, routes.statuses);
app.use('/api/types', auth, routes.types);
app.use('/api/users', auth, routes.users);
app.use('/api/requests', auth, routes.requests);

app.get('/api/health', (req, res) => {
  res.json({ ok: true });
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`Server running on http://0.0.0.0:${PORT}`);
});
