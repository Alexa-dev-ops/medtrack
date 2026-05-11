require('dotenv').config();
const express = require('express');
const cors = require('cors');

const authRoutes         = require('./routes/auth.routes');
const medicationRoutes   = require('./routes/medication.routes');
const adherenceRoutes    = require('./routes/adherence.routes');
const caregiverRoutes    = require('./routes/caregiver.routes');
const notificationRoutes = require('./routes/notification.routes');

const app = express();

app.use(cors());
app.use(express.json());

// ─── ROUTES ───────────────────────────────────────────────────────────────────
app.use('/api/auth',          authRoutes);
app.use('/api/medications',   medicationRoutes);
app.use('/api/adherence',     adherenceRoutes);
app.use('/api/caregiver',     caregiverRoutes);
app.use('/api/notifications', notificationRoutes);

// ─── HEALTH CHECK ─────────────────────────────────────────────────────────────
app.get('/api/health', (req, res) => {
  res.json({ status: 'MedTrack API is running', timestamp: new Date().toISOString() });
});

module.exports = app;