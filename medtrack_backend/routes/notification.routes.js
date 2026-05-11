const express = require('express');
const db      = require('../db/database');
const auth    = require('../middleware/auth');

const router = express.Router();

// GET /api/notifications
router.get('/', auth, (req, res) => {
  const notifs = db.prepare(
    'SELECT * FROM notifications WHERE user_id = ? ORDER BY created_at DESC LIMIT 50'
  ).all(req.user.id);

  res.json(notifs);
});

// PATCH /api/notifications/read-all  ← must come BEFORE /:id/read
router.patch('/read-all', auth, (req, res) => {
  db.prepare(
    'UPDATE notifications SET is_read = 1 WHERE user_id = ?'
  ).run(req.user.id);

  res.json({ message: 'All notifications marked as read' });
});

// PATCH /api/notifications/:id/read
router.patch('/:id/read', auth, (req, res) => {
  const notif = db.prepare(
    'SELECT * FROM notifications WHERE id = ? AND user_id = ?'
  ).get(req.params.id, req.user.id);

  if (!notif) return res.status(404).json({ error: 'Notification not found' });

  db.prepare(
    'UPDATE notifications SET is_read = 1 WHERE id = ?'
  ).run(req.params.id);

  res.json({ message: 'Notification marked as read' });
});

module.exports = router;