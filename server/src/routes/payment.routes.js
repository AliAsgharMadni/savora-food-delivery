const express = require('express');
const PaymentController = require('../controllers/payment.controller');

const router = express.Router();

router.post('/create-payment-intent', express.json(), PaymentController.createPaymentIntent);
router.post('/confirm-payment-intent', express.json(), PaymentController.confirmPaymentIntent);

module.exports = router;

