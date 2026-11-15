import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/env.dart';
import '../../../core/errors/failure.dart';
import '../../cart/data/models/cart_item.dart';
import 'models/order.dart';

abstract class IOrderRepository {
  Future<OrderModel> createOrder({
    required String userId,
    required List<CartItem> items,
    required String deliveryAddress,
    required String paymentMethod,
    required double subtotal,
    required double deliveryFee,
    required double tax,
    required double total,
  });

  Future<List<OrderModel>> fetchUserOrders(String userId);
  Stream<List<OrderModel>> streamUserOrders(String userId);
  Future<OrderModel?> fetchOrderById(String orderId);
  Stream<OrderModel?> streamOrder(String orderId);
  Future<List<OrderEvent>> fetchOrderEvents(String orderId);
  Future<List<Map<String, dynamic>>> fetchOrderItems(String orderId);
  Stream<List<OrderEvent>> streamOrderEvents(String orderId);

  Future<OrderModel?> confirmDelivery(String orderId);
  Future<OrderModel?> advanceDeliveryStage(String orderId);
  Future<void> startDeliverySimulation(String orderId);
}

class SupabaseOrderRepository implements IOrderRepository {
  final SupabaseClient? client;
  final http.Client httpClient;

  SupabaseOrderRepository({
    this.client,
    http.Client? httpClient,
  }) : httpClient = httpClient ?? http.Client();

  SupabaseClient get _safeClient => client ?? Supabase.instance.client;

  @override
  Future<OrderModel> createOrder({
    required String userId,
    required List<CartItem> items,
    required String deliveryAddress,
    required String paymentMethod,
    required double subtotal,
    required double deliveryFee,
    required double tax,
    required double total,
  }) async {
    try {
      // 1. Insert order
      final orderResponse = await _safeClient
          .from('orders')
          .insert({
            'user_id': userId,
            'status': 'confirmed',
            'subtotal': subtotal,
            'delivery_fee': deliveryFee,
            'tax': tax,
            'total': total,
            'delivery_address': deliveryAddress,
            'payment_method': paymentMethod,
            'payment_status': 'unpaid',
          })
          .select()
          .single();

      final order = OrderModel.fromJson(orderResponse);

      // 2. Insert order items
      final orderItemsData = items.map((cartItem) {
        return {
          'order_id': order.id,
          'food_id': cartItem.food.id,
          'name': cartItem.food.name,
          'price': cartItem.food.price,
          'quantity': cartItem.quantity,
        };
      }).toList();

      await _safeClient.from('order_items').insert(orderItemsData);

      // 3. Insert initial confirmed event (subsequent milestones advance via server/delivery flow)
      try {
        await _safeClient.from('order_events').insert({
          'order_id': order.id,
          'status': 'confirmed',
          'title': 'Order Placed & Confirmed',
          'description': 'Your meal has been sent to the kitchen for preparation.',
        });
      } catch (eventErr) {
        debugPrint('Non-critical: error inserting initial order_events: $eventErr');
      }

      return order;
    } catch (e) {
      throw Failure('Failed to create order: $e');
    }
  }

  @override
  Future<List<OrderModel>> fetchUserOrders(String userId) async {
    try {
      final response = await _safeClient
          .from('orders')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((item) => OrderModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Failure('Failed to fetch orders: $e');
    }
  }

  @override
  Stream<List<OrderModel>> streamUserOrders(String userId) async* {
    final initial = await fetchUserOrders(userId);
    yield initial;

    try {
      await for (final rows in _safeClient
          .from('orders')
          .stream(primaryKey: ['id'])
          .eq('user_id', userId)
          .order('created_at', ascending: false)) {
        yield rows.map((row) => OrderModel.fromJson(row)).toList();
      }
    } catch (e) {
      debugPrint('Orders stream fallback to polling: $e');
      while (true) {
        await Future.delayed(const Duration(seconds: 4));
        yield await fetchUserOrders(userId);
      }
    }
  }

  @override
  Future<OrderModel?> fetchOrderById(String orderId) async {
    try {
      final response = await _safeClient
          .from('orders')
          .select()
          .eq('id', orderId)
          .maybeSingle();

      if (response == null) return null;
      return OrderModel.fromJson(response);
    } catch (e) {
      throw Failure('Failed to fetch order: $e');
    }
  }

  @override
  Stream<OrderModel?> streamOrder(String orderId) async* {
    OrderModel? initial;
    try {
      initial = await fetchOrderById(orderId);
      yield initial;
    } catch (_) {
      yield null;
      return;
    }

    if (initial == null) return;

    try {
      await for (final rows in _safeClient
          .from('orders')
          .stream(primaryKey: ['id'])
          .eq('id', orderId)) {
        if (rows.isNotEmpty) {
          yield OrderModel.fromJson(rows.first);
        }
      }
    } catch (e) {
      debugPrint('Order stream fallback: $e');
      while (true) {
        await Future.delayed(const Duration(seconds: 4));
        final latest = await fetchOrderById(orderId);
        if (latest != null) yield latest;
      }
    }
  }

  @override
  Future<List<OrderEvent>> fetchOrderEvents(String orderId) async {
    try {
      final response = await _safeClient
          .from('order_events')
          .select()
          .eq('order_id', orderId)
          .order('created_at', ascending: true);

      return (response as List)
          .map((item) => OrderEvent.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchOrderItems(String orderId) async {
    try {
      final response = await _safeClient
          .from('order_items')
          .select()
          .eq('order_id', orderId)
          .order('created_at', ascending: true);
      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      return [];
    }
  }

  @override
  Stream<List<OrderEvent>> streamOrderEvents(String orderId) async* {
    final initial = await fetchOrderEvents(orderId);
    if (initial.isNotEmpty) {
      yield initial;
    } else {
      yield [
        OrderEvent(
          id: '1',
          orderId: orderId,
          status: 'confirmed',
          title: 'Order Placed & Confirmed',
          description: 'Your meal has been received by the kitchen.',
          createdAt: DateTime.now(),
        ),
      ];
    }

    try {
      await for (final rows in _safeClient
          .from('order_events')
          .stream(primaryKey: ['id'])
          .eq('order_id', orderId)
          .order('created_at', ascending: true)) {
        if (rows.isNotEmpty) {
          yield rows.map((row) => OrderEvent.fromJson(row)).toList();
        }
      }
    } catch (e) {
      debugPrint('Realtime events stream fallback to polling: $e');
      while (true) {
        await Future.delayed(const Duration(seconds: 4));
        final events = await fetchOrderEvents(orderId);
        if (events.isNotEmpty) yield events;
      }
    }
  }

  Future<OrderModel?> _postOrderAction(String orderId, String actionPath) async {
    try {
      final url = Uri.parse('${Env.backendUrl}/api/orders/$orderId/$actionPath');
      final response = await httpClient.post(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        final orderJson = decoded['order'];
        if (orderJson is Map<String, dynamic>) {
          return OrderModel.fromJson(orderJson);
        }
        return null;
      }
      throw Failure('Server rejected $actionPath: ${response.body}');
    } catch (e) {
      if (e is Failure) rethrow;
      throw Failure('Could not reach backend for $actionPath: $e');
    }
  }

  @override
  Future<OrderModel?> confirmDelivery(String orderId) {
    return _postOrderAction(orderId, 'confirm-delivery');
  }

  @override
  Future<OrderModel?> advanceDeliveryStage(String orderId) {
    return _postOrderAction(orderId, 'advance-status');
  }

  @override
  Future<void> startDeliverySimulation(String orderId) async {
    try {
      await _postOrderAction(orderId, 'simulate-delivery');
    } catch (e) {
      debugPrint('Non-critical: simulation start skipped: $e');
    }
  }
}
