const express = require('express');
const db      = require('../db/database');
const auth    = require('../middleware/auth');

const router = express.Router();

// GET /api/medications
router.get('/', auth, (req, res) => {
  const meds = db.prepare(
    'SELECT * FROM medications WHERE user_id = ? ORDER BY created_at DESC'
  ).all(req.user.id);

  res.json(meds);
});

// POST /api/medications
router.post('/', auth, (req, res) => {
  const { name, dosage, type, frequency, times, start_date, end_date, notes } = req.body;

  if (!name || !dosage || !type || !frequency || !times || !start_date) {
    return res.status(400).json({ error: 'Missing required fields' });
  }

  const result = db.prepare(
    `INSERT INTO medications (user_id, name, dosage, type, frequency, times, start_date, end_date, notes)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`
  ).run(
    req.user.id, name, dosage, type, frequency,
    JSON.stringify(times), start_date, end_date || null, notes || null
  );

  // Auto-create today's adherence logs for each reminder time
  const today = new Date().toISOString().split('T')[0];
  const logStmt = db.prepare(
    'INSERT INTO adherence_logs (medication_id, user_id, scheduled_time, date, status) VALUES (?, ?, ?, ?, ?)'
  );
  const parsedTimes = Array.isArray(times) ? times : JSON.parse(times);
  parsedTimes.forEach(t => logStmt.run(result.lastInsertRowid, req.user.id, t, today, 'pending'));

  // Notify user
  db.prepare(
    'INSERT INTO notifications (user_id, title, body, type) VALUES (?, ?, ?, ?)'
  ).run(req.user.id, 'Medication Added', `${name} has been added to your schedule.`, 'info');

  res.status(201).json({ id: result.lastInsertRowid, message: 'Medication added successfully' });
});

// PUT /api/medications/:id
router.put('/:id', auth, (req, res) => {
  const { name, dosage, type, frequency, times, start_date, end_date, notes } = req.body;

  const med = db.prepare(
    'SELECT * FROM medications WHERE id = ? AND user_id = ?'
  ).get(req.params.id, req.user.id);

  if (!med) return res.status(404).json({ error: 'Medication not found' });

  db.prepare(
    `UPDATE medications
     SET name=?, dosage=?, type=?, frequency=?, times=?, start_date=?, end_date=?, notes=?
     WHERE id=?`
  ).run(name, dosage, type, frequency, JSON.stringify(times), start_date, end_date || null, notes || null, req.params.id);

  res.json({ message: 'Medication updated successfully' });
});

// DELETE /api/medications/:id
router.delete('/:id', auth, (req, res) => {
  const med = db.prepare(
    'SELECT * FROM medications WHERE id = ? AND user_id = ?'
  ).get(req.params.id, req.user.id);

  if (!med) return res.status(404).json({ error: 'Medication not found' });

  db.prepare('DELETE FROM adherence_logs WHERE medication_id = ?').run(req.params.id);
  db.prepare('DELETE FROM medications WHERE id = ?').run(req.params.id);

  res.json({ message: 'Medication deleted successfully' });
});

module.exports = router;