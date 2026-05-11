const express = require('express');
const db      = require('../db/database');
const auth    = require('../middleware/auth');

const router = express.Router();

// GET /api/adherence?date=YYYY-MM-DD
router.get('/', auth, (req, res) => {
  const date = req.query.date || new Date().toISOString().split('T')[0];

  // 1. Try to fetch existing logs for this date
  let logs = db.prepare(`
    SELECT al.*, m.name AS medication_name, m.dosage, m.type
    FROM adherence_logs al
    JOIN medications m ON al.medication_id = m.id
    WHERE al.user_id = ? AND al.date = ?
    ORDER BY al.scheduled_time ASC
  `).all(req.user.id, date);

  // 2. If no logs exist, generate them automatically from the medications table
  if (logs.length === 0) {
    // Only fetch medications that have already started (or start today)
    const medications = db.prepare(`
      SELECT * FROM medications 
      WHERE user_id = ? AND start_date <= ?
    `).all(req.user.id, date);

    medications.forEach(med => {
      let times = [];
      
      // Determine time slots based on frequency
      // Normalize to lowercase to avoid case-sensitivity issues
      const freq = med.frequency.toLowerCase();
      
      if (freq.includes('thrice')) {
        times = ['08:00', '14:00', '20:00'];
      } else if (freq.includes('twice')) {
        times = ['08:00', '20:00'];
      } else {
        times = ['09:00']; // Default to once daily
      }
      
      // Insert a pending log for each time slot
      const insertStmt = db.prepare(`
        INSERT INTO adherence_logs (user_id, medication_id, date, scheduled_time, status)
        VALUES (?, ?, ?, ?, 'pending')
      `);

      times.forEach(time => {
        insertStmt.run(req.user.id, med.id, date, time);
      });
    });

    // 3. Re-fetch the logs now that they've been generated
    logs = db.prepare(`
      SELECT al.*, m.name AS medication_name, m.dosage, m.type
      FROM adherence_logs al
      JOIN medications m ON al.medication_id = m.id
      WHERE al.user_id = ? AND al.date = ?
      ORDER BY al.scheduled_time ASC
    `).all(req.user.id, date);
  }

  res.json(logs);
});

// GET /api/adherence/stats — last 7 days summary
router.get('/stats', auth, (req, res) => {
  const stats = db.prepare(`
    SELECT
      date,
      COUNT(*) AS total,
      SUM(CASE WHEN status = 'taken'   THEN 1 ELSE 0 END) AS taken,
      SUM(CASE WHEN status = 'skipped' THEN 1 ELSE 0 END) AS skipped,
      SUM(CASE WHEN status = 'pending' THEN 1 ELSE 0 END) AS pending
    FROM adherence_logs
    WHERE user_id = ? AND date >= date('now', '-7 days')
    GROUP BY date
    ORDER BY date ASC
  `).all(req.user.id);

  res.json(stats);
});

// PATCH /api/adherence/:id/take
router.patch('/:id/take', auth, (req, res) => {
  const log = db.prepare(
    'SELECT * FROM adherence_logs WHERE id = ? AND user_id = ?'
  ).get(req.params.id, req.user.id);

  if (!log) return res.status(404).json({ error: 'Adherence log not found' });

  db.prepare(
    'UPDATE adherence_logs SET status = ?, taken_at = CURRENT_TIMESTAMP WHERE id = ?'
  ).run('taken', req.params.id);

  // Notify any linked caregiver
  const links = db.prepare(
    "SELECT * FROM caregiver_links WHERE patient_id = ? AND status = 'active'"
  ).all(req.user.id);

  if (links.length > 0) {
    const patient = db.prepare('SELECT name FROM users WHERE id = ?').get(req.user.id);
    const med     = db.prepare('SELECT name FROM medications WHERE id = ?').get(log.medication_id);

    links.forEach(link => {
      db.prepare(
        'INSERT INTO notifications (user_id, title, body, type) VALUES (?, ?, ?, ?)'
      ).run(
        link.caregiver_id,
        'Dose Confirmed',
        `${patient.name} just took their ${med.name} dose.`,
        'adherence'
      );
    });
  }

  res.json({ message: 'Dose marked as taken' });
});

// PATCH /api/adherence/:id/skip
router.patch('/:id/skip', auth, (req, res) => {
  const log = db.prepare(
    'SELECT * FROM adherence_logs WHERE id = ? AND user_id = ?'
  ).get(req.params.id, req.user.id);

  if (!log) return res.status(404).json({ error: 'Adherence log not found' });

  db.prepare(
    'UPDATE adherence_logs SET status = ? WHERE id = ?'
  ).run('skipped', req.params.id);

  res.json({ message: 'Dose marked as skipped' });
});

module.exports = router;