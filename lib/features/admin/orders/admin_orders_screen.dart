import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/utils/extensions.dart';
import '../../../data/models/order.dart';
import '../../../data/repositories/order_repository.dart';
import '../../../shared/widgets/status_chip.dart';


class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  final _repo = OrderRepository();
  List<Order> _orders = [];
  bool _isLoading = true;
  String _statusFilter = 'all';

  final _statuses = [
    'all', 'pending', 'confirmed', 'processing', 'shipped', 'delivered', 'cancelled',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final orders = await _repo.getAllOrders(
      status: _statusFilter == 'all' ? null : _statusFilter,
    );
    setState(() {
      _orders = orders;
      _isLoading = false;
    });
  }

  Future<void> _updateStatus(String orderId, String newStatus) async {
    await _repo.updateOrderStatus(orderId, newStatus);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Orders')),
      body: Column(
        children: [
          // Filter chips
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: _statuses.map((s) {
                final isSelected = s == _statusFilter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    selected: isSelected,
                    label: Text(s.capitalize),
                    onSelected: (_) {
                      setState(() => _statusFilter = s);
                      _load();
                    },
                    selectedColor:
                        Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                    checkmarkColor: Theme.of(context).colorScheme.primary,
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _orders.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final order = _orders[index];
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: context.isDarkMode
                                ? Colors.white.withValues(alpha: 0.04)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '#${order.id.substring(0, 8).toUpperCase()}',
                                    style: context.textTheme.titleSmall,
                                  ),
                                  StatusChip(label: order.status.label),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${order.items.length} items · ${order.finalAmount.toCurrency}',
                                style: context.textTheme.bodySmall,
                              ),
                              Text(
                                order.createdAt.formattedWithTime,
                                style: context.textTheme.labelSmall,
                              ),
                              if (!order.status.isTerminal) ...[
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    const Text('Update: ',
                                        style: TextStyle(fontSize: 12)),
                                    ..._getNextStatuses(order.status.name)
                                        .map(
                                      (s) => Padding(
                                        padding:
                                            const EdgeInsets.only(right: 6),
                                        child: GestureDetector(
                                          onTap: () =>
                                              _updateStatus(order.id, s),
                                          child: Chip(
                                            label: Text(
                                              s.capitalize,
                                              style:
                                                  const TextStyle(fontSize: 11),
                                            ),
                                            materialTapTargetSize:
                                                MaterialTapTargetSize
                                                    .shrinkWrap,
                                            visualDensity:
                                                VisualDensity.compact,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Payment: ${order.paymentMethod.toUpperCase()}',
                                    style: context.textTheme.labelSmall,
                                  ),
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    onPressed: () => _showOrderDetailsDialog(context, order),
                                    icon: const Icon(Icons.info_outline, size: 14),
                                    label: const Text('View Details', style: TextStyle(fontSize: 12)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _showOrderDetailsDialog(BuildContext context, Order order) async {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600, maxHeight: 800),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Order #${order.id.substring(0, 8).toUpperCase()}',
                        style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                
                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Status and Time
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            StatusChip(label: order.status.label),
                            Text(
                              order.createdAt.formattedWithTime,
                              style: context.textTheme.bodySmall,
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Registered User Profile
                        Text(
                          'REGISTERED CUSTOMER PROFILE',
                          style: context.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        FutureBuilder<Map<String, dynamic>>(
                          future: Supabase.instance.client
                              .from('profiles')
                              .select()
                              .eq('id', order.userId)
                              .single(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              );
                            }
                            if (snapshot.hasError || !snapshot.hasData) {
                              return const Text('Failed to load registered profile details');
                            }
                            final profile = snapshot.data!;
                            return Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: context.isDarkMode
                                    ? Colors.white.withValues(alpha: 0.03)
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Name: ${profile['name'] ?? 'N/A'}', style: const TextStyle(fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 4),
                                  Text('Email: ${profile['email'] ?? 'N/A'}'),
                                  const SizedBox(height: 4),
                                  Text('Contact No: ${profile['phone'] ?? 'N/A'}'),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 20),

                        // Shipping Address (from Checkout)
                        Text(
                          'SHIPPING DETAILS (CHECKOUT)',
                          style: context.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: context.isDarkMode
                                ? Colors.white.withValues(alpha: 0.03)
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Recipient Name: ${order.shippingAddress['full_name'] ?? 'N/A'}', style: const TextStyle(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              Text('Street Address: ${order.shippingAddress['street'] ?? 'N/A'}'),
                              const SizedBox(height: 4),
                              Text('City/State: ${order.shippingAddress['city'] ?? ''}, ${order.shippingAddress['state'] ?? ''} - ${order.shippingAddress['pincode'] ?? ''}'),
                              const SizedBox(height: 4),
                              Text('Phone (Shipping): ${order.shippingAddress['phone'] ?? 'N/A'}'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Ordered Items
                        Text(
                          'ORDER ITEMS',
                          style: context.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: order.items.length,
                          separatorBuilder: (_, _) => const Divider(),
                          itemBuilder: (context, idx) {
                            final item = order.items[idx];
                            return Row(
                              children: [
                                if (item.productImage != null && item.productImage!.isNotEmpty)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: Image.network(
                                      item.productImage!,
                                      width: 45,
                                      height: 45,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) => const Icon(Icons.image_not_supported),
                                    ),
                                  )
                                else
                                  Container(
                                    width: 45,
                                    height: 45,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Icon(Icons.image, color: Colors.grey),
                                  ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.productName,
                                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (item.variant != null && item.variant!.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 2),
                                          child: Text(
                                            'Variant: ${item.variant}',
                                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('₹${item.price.toStringAsFixed(0)} x ${item.quantity}'),
                                    Text(
                                      '₹${(item.price * item.quantity).toStringAsFixed(0)}',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                        ),
                        const Divider(height: 32),

                        // Totals Summary
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Items Total:'),
                            Text('₹${order.totalAmount.toStringAsFixed(2)}'),
                          ],
                        ),
                        if (order.discountAmount > 0) ...[
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Discount (${order.couponCode ?? ''}):', style: const TextStyle(color: Colors.green)),
                              Text('-₹${order.discountAmount.toStringAsFixed(2)}', style: const TextStyle(color: Colors.green)),
                            ],
                          ),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Final Amount Paid:', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(
                              '₹${order.finalAmount.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Payment Method: ${order.paymentMethod.toUpperCase()}',
                          style: context.textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<String> _getNextStatuses(String current) {
    const flow = ['pending', 'confirmed', 'processing', 'shipped', 'delivered'];
    final idx = flow.indexOf(current);
    if (idx < 0 || idx >= flow.length - 1) return ['cancelled'];
    return [flow[idx + 1], 'cancelled'];
  }
}

