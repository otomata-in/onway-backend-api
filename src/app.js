const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');

const errorHandler = require('./middleware/errorHandler');
const { generalLimiter } = require('./middleware/rateLimiter');
const config = require('./config');
const swaggerUi = require('swagger-ui-express');
const swaggerSpec = require('./config/swagger');

// Import route modules
const authRoutes = require('./modules/auth/auth.routes');
const userRoutes = require('./modules/user/user.routes');
const sellerRoutes = require('./modules/seller/seller.routes');
const vendorRoutes = require('./modules/vendor/vendor.routes');
const inventoryRoutes = require('./modules/inventory/inventory.routes');
const orderRoutes = require('./modules/order/order.routes');
const routeRoutes = require('./modules/route/route.routes');

// Create Express app
const app = express();

// ─── Global Middleware ───────────────────────────────────────────

// Security headers
app.use(helmet({
  crossOriginOpenerPolicy: false, // Prevents untrustworthy origin warnings on HTTP IPs
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      scriptSrc: ["'self'", "'unsafe-inline'", "cdnjs.cloudflare.com"],
      styleSrc: ["'self'", "'unsafe-inline'", "cdnjs.cloudflare.com", "fonts.googleapis.com"],
      imgSrc: ["'self'", "data:", "validator.swagger.io"],
      fontSrc: ["'self'", "fonts.gstatic.com"],
      upgradeInsecureRequests: null, // Critical: Prevents ERR_SSL_PROTOCOL_ERROR on HTTP server
    },
  },
}));

// CORS
app.use(cors({
  origin: '*',  // TODO: Restrict in production
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH'],
  allowedHeaders: ['Content-Type', 'Authorization'],
}));

// Body parsing
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// HTTP request logging (skip in test)
if (config.nodeEnv !== 'test') {
  app.use(morgan('dev'));
}

// General rate limiting
app.use(generalLimiter);

// ─── Routes ─────────────────────────────────────────────────────

// Health check
app.get('/', (req, res) => {
  res.json({
    success: true,
    message: 'OnWay API is running',
    version: '1.0.0',
    environment: config.nodeEnv,
    docs: '/api-docs',
  });
});

// Health check / root endpoint for Render & monitoring
app.get(['/', '/health'], (req, res) => {
  res.status(200).json({
    status: 'ok',
    service: 'OnWay API',
    uptime: process.uptime(),
    timestamp: new Date().toISOString()
  });
});

// API Documentation (Swagger UI)
app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerSpec, {
  customCss: '.swagger-ui .topbar { display: none }',
  customSiteTitle: 'OnWay API Documentation',
}));
app.get('/api-docs.json', (req, res) => {
  res.setHeader('Content-Type', 'application/json');
  res.send(swaggerSpec);
});

// API routes
app.use('/auth', authRoutes);
app.use('/me', userRoutes);
app.use('/seller', sellerRoutes);
app.use('/seller/items', inventoryRoutes);
app.use('/seller/routes', routeRoutes);
app.use('/vendors', vendorRoutes);
app.use('/orders', orderRoutes);

// Version 1 Prisma & Twilio API Routes
const v1AuthRoutes = require('./routes/authRoutes');
const v1VendorRoutes = require('./routes/vendorRoutes');
const v1OrderRoutes = require('./routes/orderRoutes');
const v1VendorProfileRoutes = require('./routes/vendorProfileRoutes');
const v1BuyerRoutes = require('./routes/buyerRoutes');
const v1BuyerProfileRoutes = require('./routes/buyerProfileRoutes');
const v1BuyerBookingRoutes = require('./routes/buyerBookingRoutes');

app.use('/api/v1/auth', v1AuthRoutes);
app.use('/api/v1/vendor', v1VendorRoutes);
app.use('/api/v1/vendor', v1VendorProfileRoutes);
app.use('/api/v1/orders', v1OrderRoutes);
app.use('/api/v1/buyer', v1BuyerRoutes);
app.use('/api/v1/user', v1BuyerProfileRoutes);
app.use('/api/v1/bookings', v1BuyerBookingRoutes);

// FCM token route (mounted separately as per API spec: POST /users/fcm-token)
const { authenticate } = require('./middleware/authenticate');
const validate = require('./middleware/validate');
const userValidator = require('./modules/user/user.validator');
const userController = require('./modules/user/user.controller');
const vendorController = require('./modules/vendor/vendor.controller');

app.post(
  '/users/fcm-token',
  authenticate,
  validate(userValidator.saveFcmToken),
  userController.saveFcmToken
);

// Admin endpoint
app.get(
  '/admin/active-vendors',
  authenticate,
  vendorController.getActiveVendors
);

// ─── 404 Handler ────────────────────────────────────────────────

app.use((req, res) => {
  res.status(404).json({
    error: true,
    message: `Route ${req.method} ${req.originalUrl} not found`,
    code: 'ROUTE_NOT_FOUND',
  });
});

// ─── Global Error Handler (must be last) ────────────────────────

app.use(errorHandler);

module.exports = app;
