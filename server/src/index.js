const express = require('express');
const cors = require('cors');
const env = require('./config/env');
const healthRoutes = require('./routes/health.routes');
const paymentRoutes = require('./routes/payment.routes');
const orderRoutes = require('./routes/order.routes');
const PaymentController = require('./controllers/payment.controller');

const app = express();

// Configure CORS
const corsOptions = {
  origin:
    env.allowedOrigins === '*'
      ? true
      : env.allowedOrigins.split(',').map((origin) => origin.trim()),
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'stripe-signature'],
};
app.use(cors(corsOptions));

// 1. Webhook Route - Must use express.raw for Stripe signature verification
app.post(
  '/api/webhook',
  express.raw({ type: 'application/json' }),
  PaymentController.handleWebhook
);

// 2. Health routes
app.use('/', healthRoutes);

// 3. Payment & Order API routes (JSON parsed)
app.use('/api', paymentRoutes);
app.use('/api', orderRoutes);

// 404 Handler
app.use((req, res) => {
  res.status(404).json({ error: 'Endpoint not found' });
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error('[Server Error]:', err);
  res.status(500).json({ error: 'Internal server error occurred.' });
});

// Start listening
app.listen(env.port, () => {
  console.log(`===============================================`);
  console.log(`🚀 Savora Payment Server running on port ${env.port}`);
  console.log(`🌐 Health check available at: http://localhost:${env.port}/health`);
  console.log(`💳 Stripe Mode: ${env.stripe.isLiveReady ? 'PRODUCTION/TEST LIVE' : 'PLACEHOLDER MODE'}`);
  console.log(`===============================================`);
});

