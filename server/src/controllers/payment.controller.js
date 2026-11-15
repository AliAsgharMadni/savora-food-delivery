const StripeService = require('../services/stripe.service');
const SupabaseService = require('../services/supabase.service');
const env = require('../config/env');

class PaymentController {
  /**
   * POST /api/create-payment-intent
   */
  static async createPaymentIntent(req, res) {
    try {
      const { amount, currency = 'usd', orderId, userId, customerEmail } = req.body;

      if (!amount || !orderId || !userId) {
        return res.status(400).json({
          error: 'Missing required parameters: amount, orderId, and userId are mandatory.',
        });
      }

      const amountInCents = Math.round(Number(amount) * 100);

      const paymentIntent = await StripeService.createPaymentIntent({
        amountInCents,
        currency,
        orderId,
        userId,
        customerEmail,
      });

      return res.status(200).json({
        success: true,
        clientSecret: paymentIntent.client_secret,
        paymentIntentId: paymentIntent.id,
        amount: paymentIntent.amount,
        currency: paymentIntent.currency,
        isSimulated: !env.stripe.isLiveReady,
      });
    } catch (error) {
      console.error('[PaymentController] createPaymentIntent error:', error);
      return res.status(500).json({
        error: error.message || 'Internal Server Error while creating payment intent.',
      });
    }
  }

  /**
   * POST /api/confirm-payment-intent
   * Confirms the PaymentIntent with Stripe and syncs verified success to Supabase
   */
  static async confirmPaymentIntent(req, res) {
    try {
      const { paymentIntentId, orderId, paymentMethodId = 'pm_card_visa' } = req.body;

      if (!paymentIntentId) {
        return res.status(400).json({
          error: 'paymentIntentId is required.',
        });
      }

      const confirmed = await StripeService.confirmPaymentIntent({
        paymentIntentId,
        paymentMethodId,
      });

      if (confirmed.status === 'succeeded') {
        await SupabaseService.handlePaymentSucceeded(confirmed, orderId);
        const targetOrderId = confirmed.metadata?.orderId || orderId;
        if (targetOrderId) {
          SupabaseService.startDeliverySimulation(targetOrderId);
        }
      }

      return res.status(200).json({
        success: true,
        status: confirmed.status,
        paymentIntentId: confirmed.id,
      });
    } catch (error) {
      console.error('[PaymentController] confirmPaymentIntent error:', error);
      return res.status(500).json({
        error: error.message || 'Error confirming payment intent.',
      });
    }
  }

  /**
   * POST /api/webhook
   */
  static async handleWebhook(req, res) {
    const signature = req.headers['stripe-signature'];

    let event;
    try {
      event = StripeService.constructWebhookEvent(req.body, signature);
    } catch (err) {
      console.error('[PaymentController] Webhook signature verification failed:', err.message);
      return res.status(400).send(`Webhook Error: ${err.message}`);
    }

    console.log(`[PaymentController] Webhook event received: ${event.type}`);

    try {
      switch (event.type) {
        case 'payment_intent.succeeded': {
          const paymentIntent = event.data.object;
          await SupabaseService.handlePaymentSucceeded(paymentIntent);
          if (paymentIntent.metadata?.orderId) {
            SupabaseService.startDeliverySimulation(paymentIntent.metadata.orderId);
          }
          break;
        }

        case 'payment_intent.payment_failed': {
          const paymentIntent = event.data.object;
          await SupabaseService.handlePaymentFailed(paymentIntent);
          break;
        }

        default:
          console.log(`[PaymentController] Unhandled event type: ${event.type}`);
      }

      return res.status(200).json({ received: true });
    } catch (err) {
      console.error('[PaymentController] Error processing webhook event:', err);
      return res.status(500).json({ error: 'Failed to process webhook event.' });
    }
  }
}

module.exports = PaymentController;
