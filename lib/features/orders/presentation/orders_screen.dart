import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/extensions.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/cached_image.dart';
import '../bloc/orders_cubit.dart';
import '../../cart/bloc/cart_cubit.dart';
import '../../../data/models/order.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedTab = 'All';
  final Map<String, int> _orderRatings = {};

  @override
  void initState() {
    super.initState();
    context.read<OrdersCubit>().loadOrders();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.isDarkMode ? const Color(0xFF0F0F1A) : Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: context.isDarkMode ? const Color(0xFF1E1E2A) : Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: context.isDarkMode ? Colors.white : Colors.black87),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
        title: Text(
          'My Orders',
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w900,
            color: context.isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: context.isDarkMode ? Colors.white70 : Colors.black87),
            onPressed: () {},
          ),
          BlocBuilder<CartCubit, CartState>(
            builder: (context, cartState) {
              return IconButton(
                icon: Badge(
                  isLabelVisible: cartState.itemCount > 0,
                  label: Text('${cartState.itemCount}'),
                  child: Icon(Icons.shopping_cart_outlined, color: context.isDarkMode ? Colors.white70 : Colors.black87),
                ),
                onPressed: () => context.go('/cart'),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: BlocBuilder<OrdersCubit, OrdersState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.orders.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.receipt_long_outlined,
              title: 'No Orders Yet',
              subtitle: 'Place your first order!',
            );
          }

          // Filter by Tab and Search Query
          final query = _searchController.text.toLowerCase().trim();
          final filteredOrders = state.orders.where((order) {
            final matchesSearch = order.id.toLowerCase().contains(query) ||
                order.items.any((item) => item.productName.toLowerCase().contains(query));

            if (!matchesSearch) return false;

            if (_selectedTab == 'All') return true;
            if (_selectedTab == 'Handloom') return order.paymentMethod == 'cod';
            if (_selectedTab == 'Readymades') return order.paymentMethod != 'cod';
            return true;
          }).toList();

          return Column(
            children: [

              // ── 2. Search & Filter Bar ──────────────────────────────
              Container(
                color: context.isDarkMode ? const Color(0xFF1E1E2A) : Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: context.isDarkMode ? Colors.white10 : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.grey.shade300, width: 0.8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          children: [
                            Icon(Icons.search, color: Colors.grey.shade500, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                onChanged: (_) => setState(() {}),
                                decoration: const InputDecoration(
                                  hintText: 'Search your order here',
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      icon: Icon(Icons.filter_list, color: context.isDarkMode ? Colors.white70 : Colors.black87, size: 18),
                      label: Text(
                        'Filters',
                        style: TextStyle(color: context.isDarkMode ? Colors.white70 : Colors.black87, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),

              // ── 3. Filter Tabs ─────────────────────────────────────
              Container(
                color: context.isDarkMode ? const Color(0xFF1E1E2A) : Colors.white,
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  children: ['All', 'Mugundhan Tex', 'Handloom', 'Readymades'].map((tab) {
                    final isSelected = _selectedTab == tab;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        label: Text(
                          tab,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? Colors.white
                                : (context.isDarkMode ? Colors.white70 : Colors.black87),
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: context.isDarkMode ? Theme.of(context).colorScheme.primary : Colors.black,
                        backgroundColor: context.isDarkMode ? Colors.white10 : Colors.grey.shade100,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        onSelected: (val) {
                          if (val) {
                            setState(() {
                              _selectedTab = tab;
                            });
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),

              // ── 4. Order List ──────────────────────────────────────
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => context.read<OrdersCubit>().loadOrders(),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: filteredOrders.length,
                    itemBuilder: (context, index) {
                      final order = filteredOrders[index];
                      final isFailed = order.status == OrderStatus.cancelled;
                      final isDelivered = order.status == OrderStatus.delivered;

                      // Display values
                      final titleText = isFailed
                          ? 'Order Not Placed'
                          : isDelivered
                              ? 'Delivered on ${order.createdAt.formatted}'
                              : '${order.status.label} on ${order.createdAt.formatted}';

                      // Get first item info
                      final firstItem = order.items.isNotEmpty ? order.items[0] : null;
                      final itemImage = firstItem?.productImage ?? '';
                      final itemName = firstItem?.productName ?? 'Saree Item';

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        elevation: 0.5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: context.isDarkMode ? Colors.white10 : Colors.grey.shade200),
                        ),
                        color: context.isDarkMode ? const Color(0xFF1E1E2A) : Colors.white,
                        child: InkWell(
                          onTap: () => context.push('/order/${order.id}'),
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Title / Delivery status header
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        titleText,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 14,
                                          color: isFailed
                                              ? Colors.red.shade700
                                              : (isDelivered ? Colors.green.shade700 : Colors.blue.shade700),
                                        ),
                                      ),
                                    ),
                                    const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                // Product info row
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: CachedImage(
                                        imageUrl: itemImage,
                                        width: 50,
                                        height: 50,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            itemName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Mugundhan Basket (${order.items.length} ${order.items.length == 1 ? "item" : "items"})',
                                            style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                                // Payment failed warning box
                                if (isFailed) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.shade50,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: Colors.amber.shade200, width: 0.8),
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Icon(Icons.warning_amber_rounded, color: Colors.amber.shade800, size: 16),
                                        const SizedBox(width: 8),
                                        const Expanded(
                                          child: Text(
                                            'Payment not successful. Please contact your bank for any money deducted.',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Color(0xFF664D03),
                                              height: 1.4,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],

                                // Rating & review widgets (for delivered orders)
                                if (isDelivered) ...[
                                  const Divider(height: 24),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: List.generate(5, (starIdx) {
                                          final currentRating = _orderRatings[order.id] ?? 0;
                                          final isFilled = starIdx < currentRating;
                                          return GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                _orderRatings[order.id] = starIdx + 1;
                                              });
                                              context.showSnackBar('Thank you for rating this product!');
                                            },
                                            child: Padding(
                                              padding: const EdgeInsets.only(right: 6),
                                              child: Icon(
                                                isFilled ? Icons.star : Icons.star_border,
                                                color: isFilled ? Colors.green : Colors.grey.shade400,
                                                size: 24,
                                              ),
                                            ),
                                          );
                                        }),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          final reviewCtrl = TextEditingController();
                                          showDialog(
                                            context: context,
                                            builder: (ctx) => AlertDialog(
                                              title: const Text('Write a Review'),
                                              content: TextField(
                                                controller: reviewCtrl,
                                                maxLines: 4,
                                                decoration: const InputDecoration(
                                                  hintText: 'Share your experience with this product...',
                                                ),
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(ctx),
                                                  child: const Text('Cancel'),
                                                ),
                                                ElevatedButton(
                                                  onPressed: () {
                                                    Navigator.pop(ctx);
                                                    context.showSuccessSnackBar('Thank you for your review!');
                                                  },
                                                  child: const Text('Submit'),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                        child: const Text(
                                          'Write a Review',
                                          style: TextStyle(
                                            color: Colors.blue,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
