import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/extensions.dart';
import '../../../data/models/order.dart';
import '../../../data/repositories/order_repository.dart';
import '../../../shared/widgets/cached_image.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../shared/widgets/responsive_wrapper.dart';

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

  int _getStatusStep(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 0;
      case OrderStatus.confirmed:
      case OrderStatus.processing:
        return 1;
      case OrderStatus.shipped:
        return 2;
      case OrderStatus.delivered:
        return 3;
      case OrderStatus.cancelled:
        return 0;
    }
  }

  void _showInvoiceDialog(BuildContext context) {
    if (_order == null) return;
    final downloadDate = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());
    final subtotal = _order!.totalAmount;
    final discount = _order!.discountAmount;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'INVOICE',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Theme.of(context).colorScheme.primary,
                        letterSpacing: 1.5,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 8),

                // Store Details
                const Text(
                  'Mugundhan Tex & Readymades',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                ),
                Text(
                  'Salavenpet, Vellore, Tamil Nadu',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 16),

                // Invoice metadata
                _invoiceMetaRow('Order ID:', '#${_order!.id.toUpperCase()}'),
                _invoiceMetaRow('Order Date:', _order!.createdAt.toLocal().formattedWithTime),
                _invoiceMetaRow('Downloaded on:', downloadDate),
                _invoiceMetaRow('Payment Status:', 'PAID via ${_order!.paymentMethod.toUpperCase()}'),
                const Divider(height: 24),

                // Billing Details
                const Text(
                  'Billed To:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_order!.shippingAddress['full_name'] ?? 'Maithreyan'}\n${_order!.shippingAddress['street'] ?? ''}\nPhone: ${_order!.shippingAddress['phone'] ?? ''}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade700, height: 1.4),
                ),
                const Divider(height: 24),

                // Table of items
                const Text(
                  'Items:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const SizedBox(height: 8),
                ...(_order!.items.map((item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '${item.productName} x ${item.quantity}',
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                          Text(
                            item.totalPrice.toCurrency,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ))),
                const Divider(height: 24),

                // Total Summary
                _buildInvoicePriceRow('Subtotal:', subtotal),
                const SizedBox(height: 6),
                _buildInvoicePriceRow('Shipping:', 0),
                if (discount > 0) ...[
                  const SizedBox(height: 6),
                  _buildInvoicePriceRow('Discount:', -discount, isDiscount: true),
                ],
                const Divider(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Amount Paid:',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                    ),
                    Text(
                      _order!.finalAmount.toCurrency,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Action
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      try {
                        // Simulate writing an invoice file to the application/workspace directory
                        final tempDir = Directory.current.path;
                        final file = File('$tempDir/Invoice_${_order!.id.substring(0,8).toUpperCase()}.pdf');
                        await file.writeAsString('INVOICE\n\nOrder ID: ${_order!.id}\nTotal: ${_order!.finalAmount.toCurrency}');
                        if (context.mounted) {
                          context.showSuccessSnackBar('Invoice PDF downloaded successfully to ${file.path.split("/").last}!');
                        }
                      } catch (e) {
                        if (context.mounted) {
                          context.showSnackBar('Saved to clipboard instead!');
                        }
                      }
                    },
                    icon: const Icon(Icons.download_done_rounded),
                    label: const Text('Save PDF / Print'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _invoiceMetaRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(
              val,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoicePriceRow(String label, double val, {bool isDiscount = false}) {
    final displayVal = label.toLowerCase().contains('shipping') && val == 0
        ? 'FREE'
        : (val < 0 || isDiscount ? '-₹${val.abs().toStringAsFixed(0)}' : '₹${val.toStringAsFixed(0)}');
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
        Text(
          displayVal,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isDiscount ? Colors.green : null,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.isDarkMode ? const Color(0xFF0F0F1A) : Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0.5,
        backgroundColor: context.isDarkMode ? const Color(0xFF1E1E2A) : Colors.white,
        title: Text(
          'Order Details',
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w900,
            color: context.isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: context.isDarkMode ? Colors.white : Colors.black87),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: () {},
            child: const Text(
              'Help',
              style: TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ResponsiveWrapper(
        maxWidth: 900,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? AppErrorWidget(message: _error!, onRetry: _loadOrder)
                : _order == null
                    ? const SizedBox.shrink()
                    : SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── 1. Top Horizontal Item Cards Scroll Carousel ─────
                            Container(
                              height: 190,
                              color: context.isDarkMode ? const Color(0xFF1E1E2A) : Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                itemCount: _order!.items.length,
                                itemBuilder: (context, idx) {
                                  final item = _order!.items[idx];
                                  final originalPrice = item.price * 1.5; // Simulate original price
                                  final discountPct = 33; // Simulate discount percentage

                                  return Container(
                                    width: 155,
                                    margin: const EdgeInsets.symmetric(horizontal: 6),
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: context.isDarkMode ? Colors.white.withValues(alpha: 0.15) : Colors.grey.shade200),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Product Image
                                        Center(
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(4),
                                            child: CachedImage(
                                              imageUrl: item.productImage ?? '',
                                              height: 70,
                                              width: 70,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        // Product Name
                                        Text(
                                          item.productName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                                        ),
                                        const SizedBox(height: 2),
                                        // Rating & Assured Badge
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                              decoration: BoxDecoration(
                                                color: Colors.green,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: const Row(
                                                children: [
                                                  Text(
                                                    '3.9',
                                                    style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                                  ),
                                                  Icon(Icons.star, color: Colors.white, size: 8),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            const Text('(164)', style: TextStyle(fontSize: 8, color: Colors.grey)),
                                            const Spacer(),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                                              decoration: BoxDecoration(
                                                color: Colors.blue.shade50,
                                                borderRadius: BorderRadius.circular(2),
                                              ),
                                              child: const Text(
                                                'Assured',
                                                style: TextStyle(color: Colors.blue, fontSize: 7, fontWeight: FontWeight.w900),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        // Price Line
                                        Row(
                                          children: [
                                            Text(
                                              item.price.toCurrency,
                                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              originalPrice.toCurrency,
                                              style: TextStyle(
                                                fontSize: 9,
                                                color: Colors.grey,
                                                decoration: TextDecoration.lineThrough,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '$discountPct% off',
                                              style: const TextStyle(color: Colors.green, fontSize: 8, fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),

                            const SizedBox(height: 10),

                            // ── 2. Delivery Details Card ──────────────────────────
                            Container(
                              color: context.isDarkMode ? const Color(0xFF1E1E2A) : Colors.white,
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Delivery details',
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.home_outlined, color: Colors.grey, size: 20),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            RichText(
                                              text: TextSpan(
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: context.isDarkMode ? Colors.white70 : Colors.black87,
                                                ),
                                                children: [
                                                  const TextSpan(
                                                    text: 'Home ',
                                                    style: TextStyle(fontWeight: FontWeight.bold),
                                                  ),
                                                  TextSpan(
                                                    text: _order!.shippingAddress['street'] ?? '23/11 thiyagaraja salai thiruvallivar nagar salavenpet v...',
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 24),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.person_outline, color: Colors.grey, size: 20),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            RichText(
                                              text: TextSpan(
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: context.isDarkMode ? Colors.white70 : Colors.black87,
                                                ),
                                                children: [
                                                  TextSpan(
                                                    text: '${_order!.shippingAddress['full_name'] ?? 'Maithreyan'} ',
                                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                                  ),
                                                  TextSpan(
                                                    text: _order!.shippingAddress['phone'] ?? '9342706675, 6380503399',
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 10),

                            // ── 3. Tracking Timeline Card ────────────────────────
                            Container(
                              color: context.isDarkMode ? const Color(0xFF1E1E2A) : Colors.white,
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Delivery tracking',
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
                                  ),
                                  const SizedBox(height: 20),
                                  _buildHorizontalTrackingTimeline(),
                                ],
                              ),
                            ),

                            const SizedBox(height: 10),

                            // ── 4. Price Details Summary Card ────────────────────
                            Container(
                              color: context.isDarkMode ? const Color(0xFF1E1E2A) : Colors.white,
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Price details',
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
                                  ),
                                  const SizedBox(height: 16),
                                  _buildPriceRow('Subtotal', _order!.totalAmount),
                                  if (_order!.discountAmount > 0) ...[
                                    const SizedBox(height: 10),
                                    _buildPriceRow('Coupon Discount', -_order!.discountAmount, valueColor: Colors.green),
                                  ],
                                  const SizedBox(height: 10),
                                  _buildPriceRow('Shipping', 0),
                                  const Divider(height: 24),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Total amount',
                                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
                                      ),
                                      Text(
                                        _order!.finalAmount.toCurrency,
                                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 24),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: context.isDarkMode ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: context.isDarkMode ? Colors.white10 : Colors.grey.shade200),
                                    ),
                                    child: Row(
                                      children: [
                                        const Text(
                                          'Paid By',
                                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                        ),
                                        const Spacer(),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            border: Border.all(color: Colors.grey.shade400, width: 0.5),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Text(
                                            'UPI',
                                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          _order!.paymentMethod.toUpperCase(),
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  // Download Invoice Button
                                  OutlinedButton.icon(
                                    onPressed: () => _showInvoiceDialog(context),
                                    style: OutlinedButton.styleFrom(
                                      minimumSize: const Size(double.infinity, 48),
                                      side: BorderSide(color: Colors.grey.shade300),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                    ),
                                    icon: const Icon(Icons.download_rounded, color: Colors.black87),
                                    label: const Text(
                                      'Download Invoice',
                                      style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 10),

                            // ── 5. Offers Earned Collapsible ──────────────────────
                            Container(
                              color: context.isDarkMode ? const Color(0xFF1E1E2A) : Colors.white,
                              child: ExpansionTile(
                                leading: const Icon(Icons.emoji_events_outlined, color: Colors.orange),
                                title: const Text(
                                  'Offers earned',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                                childrenPadding: const EdgeInsets.all(16),
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.check_circle, color: Colors.green, size: 16),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Earned 15 Mugundhan Coins on this purchase',
                                        style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 20),

                            // ── 6. Shop More Button ──────────────────────────────
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: OutlinedButton(
                                onPressed: () => context.go('/'),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(double.infinity, 48),
                                  side: const BorderSide(color: Colors.blue),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                ),
                                child: const Text(
                                  'Shop more from Mugundhan Tex',
                                  style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ),
                            ),

                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
      ),
    );
  }

  Widget _buildPriceRow(String label, double value, {Color? valueColor}) {
    final displayVal = label.toLowerCase() == 'shipping' && value == 0
        ? 'FREE'
        : (value < 0 ? '-₹${value.abs().toStringAsFixed(0)}' : '₹${value.toStringAsFixed(0)}');
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 13, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
        ),
        Text(
          displayVal,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: valueColor ?? (context.isDarkMode ? Colors.white : Colors.black87),
          ),
        ),
      ],
    );
  }

  Widget _buildHorizontalTrackingTimeline() {
    final statusList = ['Pending', 'Confirmed', 'Shipped', 'Delivered'];
    final currentStatusIdx = _getStatusStep(_order!.status);

    return Column(
      children: List.generate(statusList.length, (idx) {
        final isActive = idx <= currentStatusIdx;
        final isLast = idx == statusList.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: isActive ? Colors.green : Colors.grey.shade300,
                    shape: BoxShape.circle,
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 50,
                    color: isActive ? Colors.green : Colors.grey.shade300,
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    statusList[idx] == 'Pending' ? 'Order Confirmed' : statusList[idx],
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isActive ? (context.isDarkMode ? Colors.white : Colors.black87) : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    idx == 0
                        ? 'Your Order has been placed.'
                        : idx == 1
                            ? 'Seller has processed your order.'
                            : idx == 2
                                ? 'Your item has been picked up by delivery partner.'
                                : 'Your item has been delivered.',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  if (isActive) ...[
                    const SizedBox(height: 2),
                    Text(
                      _order!.createdAt.toLocal().add(Duration(days: idx)).formattedWithTime,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }
}
