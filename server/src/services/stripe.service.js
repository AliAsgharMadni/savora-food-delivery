const Stripe = require('stripe');
const env = require('../config/env');

const stripe = env.stripe.isLiveReady ? new Stripe(env.stripe.secretKey) : null;

class StripeService {
  /**
   * Creates a Stripe PaymentIntent for a food delivery order
   * @param {Object} params
   * @param {number} params.amountInCents - Order total in smallest currency unit (cents)
   * @param {string} params.currency - e.g. 'usd'
   * @param {string} params.orderId - Internal order reference ID
   * @param {string} params.userId - Authenticated customer ID
   * @param {string} [params.customerEmail] - Customer email
   */
  static async createPaymentIntent({
    amountInCents,
    currency = 'usd',
    orderId,
    userId,
    customerEmail,
  }) {
    if (!env.stripe.isLiveReady || !stripe) {
      console.warn(
        '[StripeService] Operating in placeholder mode. Generating simulated PaymentIntent for order:',
        orderId
      );
      return {
        id: `pi_simulated_${Date.now()}`,
        client_secret: `pi_simulated_${Date.now()}_secret_${Math.random().toString(36).substring(7)}`,
        amount: amountInCents,
        currency,
        status: 'requires_payment_method',
        metadata: { orderId, userId },
      };
    }

    try {
      const paymentIntent = await stripe.paymentIntents.create({
        amount: Math.round(amountInCents),
        currency: currency.toLowerCase(),
        metadata: {
          orderId,
          userId,
        },
        receipt_email: customerEmail || undefined,
        automatic_payment_methods: {
          enabled: true,
        },
      });

      return paymentIntent;
    } catch (error) {
      console.error('[StripeService] Error creating PaymentIntent:', error);
      throw error;
    }
  }

  /**
   * Confirms a PaymentIntent with a payment method (e.g. pm_card_visa in test mode)
   */
  static async confirmPaymentIntent({ paymentIntentId, paymentMethodId = 'pm_card_visa' }) {
    if (!env.stripe.isLiveReady || !stripe) {
      return { id: paymentIntentId, status: 'succeeded' };
    }

    try {
      const confirmed = await stripe.paymentIntents.confirm(paymentIntentId, {
        payment_method: paymentMethodId,
        return_url: 'http://localhost:5000/payment-success',
      });
      return confirmed;
    } catch (error) {
      console.error('[StripeService] Error confirming PaymentIntent:', error);
      throw error;
    }
  }

  /**
   * Constructs and verifies a Stripe Webhook Event using the raw request buffer and signature header
   */
  static constructWebhookEvent(payload, signature) {
    if (!env.stripe.isLiveReady || !stripe) {
      console.warn(
        '[StripeService] Webhook in placeholder mode. Parsing payload directly without signature check.'
      );
      if (Buffer.isBuffer(payload)) {
        return JSON.parse(payload.toString('utf8'));
      }
      return typeof payload === 'string' ? JSON.parse(payload) : payload;
    }

    return stripe.webhooks.constructEvent(
      payload,
      signature,
      env.stripe.webhookSecret
    );
  }
}

module.exports = StripeService;

