const express = require('express');
const db = require('../db');
const auth = require('../middleware/auth');

const router = express.Router();

router.get('/', auth, (req, res) => {
  const types = db.prepare('SELECT * FROM request_types ORDER BY sort_order, name').all();
  res.json(types);
});

module.exports = router;
