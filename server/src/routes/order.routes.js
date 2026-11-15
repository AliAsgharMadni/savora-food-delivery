const express = require('express');
const OrderController = require('../controllers/order.controller');

const router = express.Router();

router.post('/orders/:orderId/confirm-delivery', express.json(), OrderController.confirmDelivery);
router.post('/orders/:orderId/advance-status', express.json(), OrderController.advanceStatus);
router.post('/orders/:orderId/simulate-delivery', express.json(), OrderController.simulateDelivery);

module.exports = router;

