import 'package:flutter/material.dart';
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

  List<String> _getNextStatuses(String current) {
    const flow = ['pending', 'confirmed', 'processing', 'shipped', 'delivered'];
    final idx = flow.indexOf(current);
    if (idx < 0 || idx >= flow.length - 1) return ['cancelled'];
    return [flow[idx + 1], 'cancelled'];
  }
}
