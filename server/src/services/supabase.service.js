const { createClient } = require('@supabase/supabase-js');
const env = require('../config/env');

let supabaseAdmin = null;

if (
  env.supabase.url &&
  env.supabase.serviceRoleKey &&
  !env.supabase.serviceRoleKey.includes('placeholder')
) {
  supabaseAdmin = createClient(
    env.supabase.url,
    env.supabase.serviceRoleKey,
    {
      auth: {
        autoRefreshToken: false,
        persistSession: false,
      },
    }
  );
}

const DELIVERY_STAGES = [
  {
    status: 'confirmed',
    title: 'Order Placed & Confirmed',
    description: 'Your meal has been sent to the kitchen for preparation.',
  },
  {
    status: 'preparing',
    title: 'Chef Preparing Your Feast',
    description: 'Fresh ingredients are being slow-cooked to perfection.',
  },
  {
    status: 'out_for_delivery',
    title: 'Rider Bilal On The Way',
    description: 'Your insulated bag is on the scooter heading to your address.',
  },
  {
    status: 'delivered',
    title: 'Delivered to Your Door',
    description: 'Enjoy your fresh meal! Thank you for ordering with Savora.',
  },
];

// Track active simulation timers per orderId so we avoid duplicate schedules
const activeSimulations = new Map();

class SupabaseService {
  /**
   * Idempotently updates an order's payment status to 'paid' upon verified Stripe confirmation/webhook
   */
  static async handlePaymentSucceeded(paymentIntent, fallbackOrderId) {
    const orderId = paymentIntent.metadata?.orderId || fallbackOrderId;
    if (!orderId) {
      console.warn('[SupabaseService] Event missing orderId in metadata:', paymentIntent.id);
      return;
    }

    if (!supabaseAdmin) {
      console.warn(
        `[SupabaseService] Admin client unconfigured. Simulated DB update for order ${orderId}.`
      );
      return;
    }

    try {
      const { data: existing, error: fetchErr } = await supabaseAdmin
        .from('orders')
        .select('id, status, payment_status')
        .eq('id', orderId)
        .maybeSingle();

      if (fetchErr) throw fetchErr;
      if (!existing) {
        console.warn(`[SupabaseService] Order ${orderId} not found.`);
        return;
      }

      if (existing.payment_status === 'paid') {
        return existing;
      }

      const nextStatus = existing.status === 'pending' ? 'confirmed' : existing.status;

      const { data, error } = await supabaseAdmin
        .from('orders')
        .update({
          payment_status: 'paid',
          status: nextStatus,
          updated_at: new Date().toISOString(),
        })
        .eq('id', orderId)
        .select()
        .single();

      if (error) throw error;

      const amountDollars =
        typeof paymentIntent.amount === 'number'
          ? (paymentIntent.amount / 100).toFixed(2)
          : data.total;

      await supabaseAdmin.from('order_events').insert({
        order_id: orderId,
        status: nextStatus,
        title: 'Payment Confirmed by Stripe',
        description: `Verified $${amountDollars} transaction. Kitchen preparing order.`,
      });

      console.log(`[SupabaseService] Order ${orderId} marked as PAID.`);
      return data;
    } catch (err) {
      console.error(`[SupabaseService] Failed to update order ${orderId}:`, err);
      throw err;
    }
  }

  /**
   * Updates an order's payment status to 'failed'
   */
  static async handlePaymentFailed(paymentIntent) {
    const orderId = paymentIntent.metadata?.orderId;
    if (!orderId || !supabaseAdmin) return;

    try {
      await supabaseAdmin
        .from('orders')
        .update({
          payment_status: 'failed',
          updated_at: new Date().toISOString(),
        })
        .eq('id', orderId);

      await supabaseAdmin.from('order_events').insert({
        order_id: orderId,
        status: 'payment_failed',
        title: 'Payment Authorization Failed',
        description: 'Your payment attempt was declined. Please try another card.',
      });
    } catch (err) {
      console.error(`[SupabaseService] Failed to update failed payment for ${orderId}:`, err);
    }
  }

  /**
   * Transitions an order to a specific stage cleanly and records a timeline event if absent
   */
  static async setOrderStage(orderId, targetStatus) {
    if (!supabaseAdmin) {
      throw new Error('Supabase admin client is not configured.');
    }

    const stage = DELIVERY_STAGES.find((s) => s.status === targetStatus);
    if (!stage) {
      throw new Error(`Unsupported order status: ${targetStatus}`);
    }

    const { data: order, error: fetchErr } = await supabaseAdmin
      .from('orders')
      .select('*')
      .eq('id', orderId)
      .maybeSingle();

    if (fetchErr) throw fetchErr;
    if (!order) return null;
    if (order.status === 'cancelled' || order.status === 'delivered') {
      return order;
    }

    const { data: updated, error: updateErr } = await supabaseAdmin
      .from('orders')
      .update({
        status: targetStatus,
        updated_at: new Date().toISOString(),
      })
      .eq('id', orderId)
      .select()
      .single();

    if (updateErr) throw updateErr;

    const { data: existingEvents } = await supabaseAdmin
      .from('order_events')
      .select('id')
      .eq('order_id', orderId)
      .eq('status', targetStatus)
      .limit(1);

    if (!existingEvents || existingEvents.length === 0) {
      await supabaseAdmin.from('order_events').insert({
        order_id: orderId,
        status: stage.status,
        title: stage.title,
        description: stage.description,
      });
    }

    if (targetStatus === 'delivered') {
      this.clearDeliverySimulation(orderId);
    }

    return updated;
  }

  /**
   * Advances an order to the next delivery stage
   */
  static async advanceOrderStage(orderId) {
    if (!supabaseAdmin) {
      throw new Error('Supabase admin client is not configured.');
    }

    const { data: order, error } = await supabaseAdmin
      .from('orders')
      .select('id, status')
      .eq('id', orderId)
      .maybeSingle();

    if (error) throw error;
    if (!order) return null;

    const currentIdx = DELIVERY_STAGES.findIndex((s) => s.status === order.status);
    if (currentIdx === -1) {
      return this.setOrderStage(orderId, 'confirmed');
    }
    if (currentIdx >= DELIVERY_STAGES.length - 1) {
      return order;
    }

    const nextStage = DELIVERY_STAGES[currentIdx + 1];
    return this.setOrderStage(orderId, nextStage.status);
  }

  static clearDeliverySimulation(orderId) {
    const timers = activeSimulations.get(orderId);
    if (timers) {
      timers.forEach((t) => clearTimeout(t));
      activeSimulations.delete(orderId);
    }
  }

  /**
   * Starts automatic background stage progression (preparing -> out_for_delivery -> delivered)
   */
  static startDeliverySimulation(orderId) {
    if (!supabaseAdmin || activeSimulations.has(orderId)) return;

    const schedule = [
      { delayMs: 6000, status: 'preparing' },
      { delayMs: 14000, status: 'out_for_delivery' },
      { delayMs: 25000, status: 'delivered' },
    ];

    const timers = schedule.map(({ delayMs, status }) =>
      setTimeout(async () => {
        try {
          await this.setOrderStage(orderId, status);
        } catch (err) {
          console.error(`[SupabaseService] Simulation error (${orderId} -> ${status}):`, err.message);
        }
      }, delayMs)
    );

    activeSimulations.set(orderId, timers);
  }
}

module.exports = SupabaseService;
