const express = require('express');
const env = require('../config/env');

const router = express.Router();

router.get('/', (req, res) => {
  res.status(200).json({
    name: 'Savora Payment & Order Backend API',
    status: 'running',
    version: '1.0.0',
    timestamp: new Date().toISOString(),
    endpoints: {
      health: '/health',
      createPaymentIntent: 'POST /api/create-payment-intent',
      confirmPaymentIntent: 'POST /api/confirm-payment-intent',
      webhook: 'POST /api/webhook',
    },
  });
});

router.get('/health', (req, res) => {
  res.status(200).json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    environment: env.nodeEnv,
    services: {
      supabase: Boolean(env.supabase.url && env.supabase.serviceRoleKey),
      stripe: env.stripe.isLiveReady ? 'live' : 'placeholder_mode',
    },
  });
});

module.exports = router;

