const SupabaseService = require('../services/supabase.service');

class OrderController {
  /**
   * POST /api/orders/:orderId/confirm-delivery
   */
  static async confirmDelivery(req, res) {
    try {
      const { orderId } = req.params;
      if (!orderId) {
        return res.status(400).json({ error: 'orderId is required.' });
      }

      const updated = await SupabaseService.setOrderStage(orderId, 'delivered');
      if (!updated) {
        return res.status(404).json({ error: 'Order not found.' });
      }

      return res.status(200).json({ success: true, order: updated });
    } catch (error) {
      console.error('[OrderController] confirmDelivery error:', error);
      return res.status(500).json({ error: error.message || 'Failed to confirm delivery.' });
    }
  }

  /**
   * POST /api/orders/:orderId/advance-status
   */
  static async advanceStatus(req, res) {
    try {
      const { orderId } = req.params;
      if (!orderId) {
        return res.status(400).json({ error: 'orderId is required.' });
      }

      const updated = await SupabaseService.advanceOrderStage(orderId);
      if (!updated) {
        return res.status(404).json({ error: 'Order not found.' });
      }

      return res.status(200).json({ success: true, order: updated });
    } catch (error) {
      console.error('[OrderController] advanceStatus error:', error);
      return res.status(500).json({ error: error.message || 'Failed to advance status.' });
    }
  }

  /**
   * POST /api/orders/:orderId/simulate-delivery
   */
  static async simulateDelivery(req, res) {
    try {
      const { orderId } = req.params;
      if (!orderId) {
        return res.status(400).json({ error: 'orderId is required.' });
      }

      SupabaseService.startDeliverySimulation(orderId);
      return res.status(200).json({ success: true, message: 'Delivery simulation started.' });
    } catch (error) {
      console.error('[OrderController] simulateDelivery error:', error);
      return res.status(500).json({ error: error.message || 'Failed to start simulation.' });
    }
  }
}

module.exports = OrderController;

