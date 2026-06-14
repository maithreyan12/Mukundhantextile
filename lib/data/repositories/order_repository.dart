import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/order.dart' as model;
import '../models/cart_item.dart';

class OrderRepository {
  final SupabaseClient _client;

  OrderRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  String get _userId => _client.auth.currentUser!.id;

  // ── Place Order ───────────────────────────────────────
  Future<model.Order> placeOrder({
    required List<CartItem> items,
    required double totalAmount,
    required double discountAmount,
    String? couponCode,
    required String paymentMethod,
    required Map<String, dynamic> shippingAddress,
  }) async {
    // Create order
    final orderData = await _client
        .from('orders')
        .insert({
          'user_id': _userId,
          'total_amount': totalAmount,
          'discount_amount': discountAmount,
          'coupon_code': couponCode,
          'status': 'pending',
          'payment_method': paymentMethod,
          'shipping_address': shippingAddress,
        })
        .select()
        .single();

    final orderId = orderData['id'] as String;

    // Create order items
    final orderItems = items.map((item) => {
          'order_id': orderId,
          'product_id': item.productId,
          'product_name': item.product?.name ?? '',
          'product_image': item.product?.primaryImage,
          'quantity': item.quantity,
          'price': item.product?.effectivePrice ?? 0,
          'variant': item.variant,
        }).toList();

    await _client.from('order_items').insert(orderItems);

    // Clear cart
    await _client.from('cart_items').delete().eq('user_id', _userId);

    // Update coupon used count
    if (couponCode != null) {
      await _client.rpc('increment_coupon_usage', params: {'coupon_code_param': couponCode});
    }

    // Fetch complete order
    return getOrder(orderId);
  }

  // ── Get User Orders ───────────────────────────────────
  Future<List<model.Order>> getUserOrders({String? status}) async {
    var query = _client
        .from('orders')
        .select('*, order_items(*)')
        .eq('user_id', _userId);

    if (status != null && status != 'all') {
      query = query.eq('status', status);
    }

    final data = await query.order('created_at', ascending: false);
    return (data as List).map((e) => model.Order.fromJson(e)).toList();
  }

  // ── Get Single Order ──────────────────────────────────
  Future<model.Order> getOrder(String id) async {
    final data = await _client
        .from('orders')
        .select('*, order_items(*)')
        .eq('id', id)
        .single();
    return model.Order.fromJson(data);
  }

  // ── Admin: Get All Orders ─────────────────────────────
  Future<List<model.Order>> getAllOrders({
    String? status,
    int page = 0,
    int pageSize = 20,
  }) async {
    var query = _client.from('orders').select('*, order_items(*)');

    if (status != null && status != 'all') {
      query = query.eq('status', status);
    }

    final data = await query
        .order('created_at', ascending: false)
        .range(page * pageSize, (page + 1) * pageSize - 1);
    return (data as List).map((e) => model.Order.fromJson(e)).toList();
  }

  // ── Admin: Update Order Status ────────────────────────
  Future<void> updateOrderStatus(String orderId, String status) async {
    await _client.from('orders').update({'status': status}).eq('id', orderId);
  }

  // ── Realtime Order Subscription ───────────────────────
  StreamSubscription<List<Map<String, dynamic>>> subscribeToOrderUpdates(
    void Function(Map<String, dynamic> payload) onUpdate,
  ) {
    return _client
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('user_id', _userId)
        .listen((data) {
          for (final item in data) {
            onUpdate(item);
          }
        });
  }

  // ── Admin: Order Stats ────────────────────────────────
  Future<Map<String, dynamic>> getOrderStats() async {
    final orders = await _client.from('orders').select('total_amount, status, created_at');
    final list = orders as List;

    double totalRevenue = 0;
    int totalOrders = list.length;
    Map<String, int> statusCounts = {};

    for (final o in list) {
      totalRevenue += (o['total_amount'] as num?)?.toDouble() ?? 0;
      final s = o['status'] as String? ?? 'pending';
      statusCounts[s] = (statusCounts[s] ?? 0) + 1;
    }

    return {
      'total_revenue': totalRevenue,
      'total_orders': totalOrders,
      'status_counts': statusCounts,
      'orders': list,
    };
  }
}
