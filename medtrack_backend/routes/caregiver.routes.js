const express = require('express');
const db      = require('../db/database');
const auth    = require('../middleware/auth');

const router = express.Router();

// POST /api/caregiver/link — patient links to a caregiver using their code
router.post('/link', auth, (req, res) => {
  const { caregiver_code } = req.body;

  if (!caregiver_code) {
    return res.status(400).json({ error: 'Caregiver code is required' });
  }

  const caregiver = db.prepare(
    "SELECT * FROM users WHERE caregiver_code = ? AND role = 'caregiver'"
  ).get(caregiver_code);

  if (!caregiver) {
    return res.status(404).json({ error: 'Invalid caregiver code. No caregiver found.' });
  }

  if (caregiver.id === req.user.id) {
    return res.status(400).json({ error: 'You cannot link yourself as a caregiver.' });
  }

  const existing = db.prepare(
    'SELECT * FROM caregiver_links WHERE caregiver_id = ? AND patient_id = ?'
  ).get(caregiver.id, req.user.id);

  if (existing) {
    return res.status(409).json({ error: 'Already linked to this caregiver' });
  }

  db.prepare(
    'INSERT INTO caregiver_links (caregiver_id, patient_id) VALUES (?, ?)'
  ).run(caregiver.id, req.user.id);

  // Notify the caregiver
  const patient = db.prepare('SELECT name FROM users WHERE id = ?').get(req.user.id);
  db.prepare(
    'INSERT INTO notifications (user_id, title, body, type) VALUES (?, ?, ?, ?)'
  ).run(
    caregiver.id,
    'New Patient Linked',
    `${patient.name} has linked you as their caregiver.`,
    'info'
  );

  res.json({ message: `Successfully linked to caregiver ${caregiver.name}` });
});

// GET /api/caregiver/patients — caregiver views all their linked patients
router.get('/patients', auth, (req, res) => {
  if (req.user.role !== 'caregiver') {
    return res.status(403).json({ error: 'Access restricted to caregivers only' });
  }

  const patients = db.prepare(`
    SELECT u.id, u.name, u.email, cl.linked_at
    FROM caregiver_links cl
    JOIN users u ON cl.patient_id = u.id
    WHERE cl.caregiver_id = ? AND cl.status = 'active'
  `).all(req.user.id);

  res.json(patients);
});

// GET /api/caregiver/patients/:patientId/adherence — view a patient's daily adherence
router.get('/patients/:patientId/adherence', auth, (req, res) => {
  if (req.user.role !== 'caregiver') {
    return res.status(403).json({ error: 'Access restricted to caregivers only' });
  }

  const link = db.prepare(
    "SELECT * FROM caregiver_links WHERE caregiver_id = ? AND patient_id = ? AND status = 'active'"
  ).get(req.user.id, req.params.patientId);

  if (!link) {
    return res.status(403).json({ error: 'You are not linked to this patient' });
  }

  const date = req.query.date || new Date().toISOString().split('T')[0];

  const logs = db.prepare(`
    SELECT al.*, m.name AS medication_name, m.dosage, m.type
    FROM adherence_logs al
    JOIN medications m ON al.medication_id = m.id
    WHERE al.user_id = ? AND al.date = ?
    ORDER BY al.scheduled_time ASC
  `).all(req.params.patientId, date);

  res.json(logs);
});

module.exports = router;