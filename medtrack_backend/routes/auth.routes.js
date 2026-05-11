const express = require('express');
const bcrypt  = require('bcryptjs');
const jwt     = require('jsonwebtoken');
const db      = require('../db/database');
const auth    = require('../middleware/auth');

const router     = express.Router();
const JWT_SECRET = process.env.JWT_SECRET || 'medtrack_secret_key_2025';

// POST /api/auth/register
router.post('/register', (req, res) => {
  const { name, email, password, role } = req.body;

  if (!name || !email || !password) {
    return res.status(400).json({ error: 'Name, email and password are required' });
  }

  const hashed = bcrypt.hashSync(password, 10);
  const caregiverCode = role === 'caregiver'
    ? Math.random().toString(36).substring(2, 8).toUpperCase()
    : null;

  try {
    const result = db.prepare(
      'INSERT INTO users (name, email, password, role, caregiver_code) VALUES (?, ?, ?, ?, ?)'
    ).run(name, email, hashed, role || 'patient', caregiverCode);

    const token = jwt.sign(
      { id: result.lastInsertRowid, email, role: role || 'patient' },
      JWT_SECRET,
      { expiresIn: '30d' }
    );

    res.status(201).json({
      token,
      user: {
        id: result.lastInsertRowid,
        name,
        email,
        role: role || 'patient',
        caregiverCode,
      },
    });
  } catch (e) {
    if (e.message.includes('UNIQUE')) {
      return res.status(409).json({ error: 'Email already registered' });
    }
    res.status(500).json({ error: e.message });
  }
});

// POST /api/auth/login
router.post('/login', (req, res) => {
  const { email, password } = req.body;

  const user = db.prepare('SELECT * FROM users WHERE email = ?').get(email);

  if (!user || !bcrypt.compareSync(password, user.password)) {
    return res.status(401).json({ error: 'Invalid email or password' });
  }

  const token = jwt.sign(
    { id: user.id, email: user.email, role: user.role },
    JWT_SECRET,
    { expiresIn: '30d' }
  );

  res.json({
    token,
    user: {
      id: user.id,
      name: user.name,
      email: user.email,
      role: user.role,
      caregiverCode: user.caregiver_code,
    },
  });
});

// GET /api/auth/me
router.get('/me', auth, (req, res) => {
  const user = db.prepare(
    'SELECT id, name, email, role, caregiver_code, created_at FROM users WHERE id = ?'
  ).get(req.user.id);

  res.json(user);
});

module.exports = router;