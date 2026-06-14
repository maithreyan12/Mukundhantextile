import 'package:flutter/material.dart';
import '../../../shared/widgets/responsive_wrapper.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/extensions.dart';
import '../../../data/models/order.dart';
import '../../../data/repositories/order_repository.dart';
import '../../../shared/widgets/cached_image.dart';
import '../../../shared/widgets/status_chip.dart';
import '../../../shared/widgets/error_widget.dart';

class OrderDetailScreen extends StatefulWidget {
  final String orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final _repo = OrderRepository();
  Order? _order;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    setState(() => _isLoading = true);
    try {
      final order = await _repo.getOrder(widget.orderId);
      setState(() {
        _order = order;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ORDER DETAILS', style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, letterSpacing: 1.5)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: ResponsiveWrapper(
        maxWidth: 800,
        child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? AppErrorWidget(message: _error!, onRetry: _loadOrder)
              : _order == null
                  ? const SizedBox.shrink()
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Order ID & Status
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Order #${_order!.id.substring(0, 8).toUpperCase()}',
                                style: context.textTheme.headlineSmall,
                              ),
                              StatusChip(label: _order!.status.label),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _order!.createdAt.formattedWithTime,
                            style: context.textTheme.bodySmall,
                          ),

                          const SizedBox(height: 24),

                          // ── Order Timeline ──────────────────
                          Text('ORDER STATUS',
                              style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, letterSpacing: 1.0)),
                          const SizedBox(height: 12),
                          _buildTimeline(),

                          const SizedBox(height: 32),

                          // ── Items ───────────────────────────
                          Text('ITEMS (${_order!.items.length})',
                              style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, letterSpacing: 1.0)),
                          const SizedBox(height: 16),
                          ...(_order!.items.map((item) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius:
                                          BorderRadius.circular(10),
                                      child: CachedImage(
                                        imageUrl: item.productImage,
                                        width: 60,
                                        height: 60,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(item.productName,
                                              style: context
                                                  .textTheme.titleSmall),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Qty: ${item.quantity} × ${item.price.toCurrency}',
                                            style:
                                                context.textTheme.bodySmall,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      item.totalPrice.toCurrency,
                                      style:
                                          context.textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ))),

                          const Divider(height: 32),

                          // ── Price Breakdown ─────────────────
                          _priceRow('Subtotal', _order!.totalAmount.toCurrency),
                          if (_order!.discountAmount > 0)
                            _priceRow(
                              'Discount',
                              '-${_order!.discountAmount.toCurrency}',
                              valueColor: const Color(0xFF2ED573),
                            ),
                          _priceRow('Shipping', 'Free'),
                          const Divider(height: 24),
                          _priceRow(
                            'Total',
                            _order!.finalAmount.toCurrency,
                            isBold: true,
                          ),

                          const SizedBox(height: 24),

                          // ── Payment & Address ───────────────
                          Text('PAYMENT METHOD',
                              style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, letterSpacing: 1.0)),
                          const SizedBox(height: 8),
                          Text(_order!.paymentMethod.toUpperCase(),
                              style: context.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),

                          if (_order!.shippingAddress.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            Text('SHIPPING ADDRESS',
                                style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, letterSpacing: 1.0)),
                            const SizedBox(height: 8),
                            Text(
                              '${_order!.shippingAddress['full_name'] ?? ''}\n${_order!.shippingAddress['street'] ?? ''}, ${_order!.shippingAddress['city'] ?? ''}\n${_order!.shippingAddress['state'] ?? ''} - ${_order!.shippingAddress['pincode'] ?? ''}\n${_order!.shippingAddress['phone'] ?? ''}',
                              style: context.textTheme.bodySmall?.copyWith(
                                height: 1.5,
                              ),
                            ),
                          ],
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
      ),
    );
  }

  Widget _buildTimeline() {
    final statuses = [
      'Pending',
      'Confirmed',
      'Processing',
      'Shipped',
      'Delivered',
    ];
    final currentIndex = _order!.status == OrderStatus.cancelled
        ? -1
        : _order!.status.index;

    return Column(
      children: List.generate(statuses.length, (i) {
        final isActive = i <= currentIndex;
        final isCurrent = i == currentIndex;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isActive
                        ? context.isDarkMode ? Colors.white : Colors.black
                        : context.isDarkMode ? Colors.white24 : Colors.black12,
                    border: isCurrent
                        ? Border.all(
                            color: context.isDarkMode ? Colors.white : Colors.black, width: 3)
                        : null,
                  ),
                  child: isActive
                      ? Icon(Icons.check, size: 14, color: context.isDarkMode ? Colors.black : Colors.white)
                      : null,
                ),
                if (i < statuses.length - 1)
                  Container(
                    width: 2,
                    height: 30,
                    color: isActive
                        ? (context.isDarkMode ? Colors.white : Colors.black)
                        : (context.isDarkMode ? Colors.white24 : Colors.black12),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                statuses[i],
                style: context.textTheme.bodyMedium?.copyWith(
                  fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
                  color: isActive ? null : Colors.grey,
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _priceRow(String label, String value,
      {bool isBold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: isBold
                  ? context.textTheme.titleMedium
                  : context.textTheme.bodyMedium),
          Text(
            value,
            style: (isBold
                    ? context.textTheme.titleMedium
                    : context.textTheme.bodyMedium)
                ?.copyWith(
              fontWeight: isBold ? FontWeight.w700 : null,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
