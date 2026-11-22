const express = require('express');
const path = require('path');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');

const errorHandler = require('./middleware/errorHandler');

// Route modules
const authRoutes = require('./modules/auth/auth.routes');
const usersRoutes = require('./modules/users/users.routes');
const flagsRoutes = require('./modules/flags/flags.routes');
const clansRoutes = require('./modules/clans/clans.routes');
const communitiesRoutes = require('./modules/communities/communities.routes');
const tripsRoutes = require('./modules/trips/trips.routes');
const ralliesRoutes = require('./modules/rallies/rallies.routes');
const rankingsRoutes = require('./modules/rankings/rankings.routes');
const servicesRoutes = require('./modules/services/services.routes');
const notificationsRoutes = require('./modules/notifications/notifications.routes');
const uploadRoutes = require('./modules/upload/upload.routes');
const searchRoutes = require('./modules/search/search.routes');

const app = express();

// Security & utilities
app.use(helmet());
app.use(cors({ origin: '*' }));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

if (process.env.NODE_ENV !== 'test') {
  app.use(morgan('dev'));
}

// Serve uploaded files
app.use('/uploads', express.static(path.join(__dirname, '../uploads')));

// Root & Health check
app.get(['/', '/health'], (req, res) => {
  res.status(200).json({
    status: 'ok',
    service: 'Teritory Standalone API',
    version: '1.0.0',
    timestamp: new Date().toISOString(),
    endpoints: {
      auth: '/v1/auth',
      users: '/v1/users',
      flags: '/v1/flags',
      clans: '/v1/clans',
      communities: '/v1/communities',
      trips: '/v1/trips',
      rallies: '/v1/rallies',
      rankings: '/v1/rankings',
      services: '/v1/services',
      notifications: '/v1/notifications',
      upload: '/v1/upload',
    },
  });
});

// Mount V1 Teritory routes
app.use('/v1/auth', authRoutes);
app.use('/v1/users', usersRoutes);
app.use('/v1/flags', flagsRoutes);
app.use('/v1/clans', clansRoutes);
app.use('/v1/communities', communitiesRoutes);
app.use('/v1/trips', tripsRoutes);
app.use('/v1/rallies', ralliesRoutes);
app.use('/v1/rankings', rankingsRoutes);
app.use('/v1/services', servicesRoutes);
app.use('/v1/notifications', notificationsRoutes);
app.use('/v1/upload', uploadRoutes);
app.use('/v1/search', searchRoutes);

// 404 Route Handler
app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: `Route ${req.method} ${req.originalUrl} not found`,
    code: 'ROUTE_NOT_FOUND',
  });
});

// Central Error Handler
app.use(errorHandler);

module.exports = app;

