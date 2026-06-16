import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/utils/responsive_helper.dart';
import '../../../shared/widgets/cached_image.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/premium_button.dart';
import '../../../data/repositories/address_repository.dart';
import '../../../data/models/address.dart';
import '../bloc/cart_cubit.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _couponController = TextEditingController();
  final _addressRepo = AddressRepository();
  Address? _selectedAddress;

  @override
  void initState() {
    super.initState();
    context.read<CartCubit>().loadCart();
    _loadDefaultAddress();
  }

  Future<void> _loadDefaultAddress() async {
    try {
      final addr = await _addressRepo.getDefaultAddress();
      setState(() {
        _selectedAddress = addr;
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);

    return Scaffold(
      appBar: AppBar(title: const Text('My Cart')),
      body: BlocListener<CartCubit, CartState>(
        listener: (context, state) {
          if (!state.isLoading && state.error == null) {
            _loadDefaultAddress();
          }
        },
        child: BlocBuilder<CartCubit, CartState>(
          builder: (context, state) {
            if (state.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.error != null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        'Failed to load cart',
                        style: context.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        state.error!,
                        style: const TextStyle(color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () => context.read<CartCubit>().loadCart(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }
            if (state.items.isEmpty) {
              return EmptyStateWidget(
                icon: Icons.shopping_cart_outlined,
                title: 'Your Cart is Empty',
                subtitle: 'Add some products to get started',
                actionLabel: 'Shop Now',
                onAction: () => context.go('/'),
              );
            }

            if (isDesktop) {
              return _buildDesktopLayout(context, state);
            }
            return _buildMobileLayout(context, state);
          },
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // DESKTOP LAYOUT — Cart Items (left) | Summary (right)
  // ═══════════════════════════════════════════════════════
  Widget _buildDesktopLayout(BuildContext context, CartState state) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Left: Cart Items ──
              Expanded(
                flex: 6,
                child: ListView.separated(
                  itemCount: state.items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = state.items[index];
                    return _buildCartItem(context, item);
                  },
                ),
              ),

              const SizedBox(width: 32),

              // ── Right: Order Summary ──
              Expanded(
                flex: 4,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: context.isDarkMode
                        ? Colors.white.withValues(alpha: 0.04)
                        : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: context.isDarkMode
                          ? Colors.white12
                          : Colors.grey.shade200,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ORDER SUMMARY',
                          style: context.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                          )),
                      const SizedBox(height: 20),
                      _buildCouponSection(state),
                      const SizedBox(height: 20),
                      _buildPricingSummary(state),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: PremiumButton(
                          onPressed: () => context.push('/checkout'),
                          backgroundColor: const Color(0xFFEAEAEA),
                          child: const Text('PROCEED TO CHECKOUT',
                              style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w800)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // MOBILE LAYOUT — Flipkart Style
  // ═══════════════════════════════════════════════════════
  Widget _buildMobileLayout(BuildContext context, CartState state) {
    return Column(
      children: [
        // Tab Header
        Container(
          color: Colors.white,
          child: Row(
            children: [
              _buildTabItem('Flipkart (${state.itemCount})', isSelected: true),
              _buildTabItem('Grocery', isSelected: false),
              _buildTabItem('Minutes (2)', isSelected: false),
            ],
          ),
        ),
        
        // Tab indicator underline
        Container(
          height: 2,
          color: Colors.grey.shade200,
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 2,
                  color: Colors.blue,
                ),
              ),
              Expanded(child: const SizedBox.shrink()),
              Expanded(child: const SizedBox.shrink()),
            ],
          ),
        ),

        // Offers promo banner
        Container(
          width: double.infinity,
          color: Colors.blue.shade50.withValues(alpha: 0.5),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: const Row(
            children: [
              Text(
                'View 2 more offers',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        // Address Header at the top
        _buildAddressHeader(context),
        
        // Cart Items & Details scrollable view
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(0),
            children: [
              // Items List
              ...state.items.map((item) => _buildCartItem(context, item)),
              
              const SizedBox(height: 8),
              
              // Price Details Breakdown
              _buildPriceDetailsCard(context, state),
              
              // Safe Payments Badge
              Container(
                color: Colors.grey.shade100,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.verified_user_sharp, size: 24, color: Colors.grey.shade400),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Safe and secure payments. Easy returns.\n100% Authentic products.',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Items You May Have Missed mockup
              _buildItemsMissedSection(context),
              
              const SizedBox(height: 24),
            ],
          ),
        ),
        
        // Bottom Sticky Action Bar
        _buildBottomStickyBar(context, state),
      ],
    );
  }

  Widget _buildTabItem(String title, {required bool isSelected}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        alignment: Alignment.center,
        child: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.blue : Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildItemsMissedSection(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Items you may have missed',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildMissedItemCard('Trendy Kid\'s Dress', '₹350', 'assets/saree_placeholder.jpg'),
                _buildMissedItemCard('Soft Cotton Shirt', '₹450', 'assets/saree_placeholder.jpg'),
                _buildMissedItemCard('Designer Saree Silk', '₹1,250', 'assets/saree_placeholder.jpg'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissedItemCard(String name, String price, String imagePath) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              ),
              child: const Center(
                child: Icon(Icons.shopping_bag_outlined, color: Colors.grey, size: 32),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  price,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Address Header Widget ────────────────────────────────
  Widget _buildAddressHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: context.isDarkMode ? const Color(0xFF1E1E2A) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: context.isDarkMode ? Colors.white12 : Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _selectedAddress != null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Deliver to: ',
                            style: TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                          Text(
                            _selectedAddress!.fullName,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: context.isDarkMode
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _selectedAddress!.isDefault ? 'HOME' : 'WORK',
                              style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade700),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _selectedAddress!.shortAddress,
                        style: TextStyle(
                          fontSize: 12,
                          color: context.isDarkMode
                              ? Colors.white70
                              : Colors.grey.shade700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  )
                : const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Deliver to: ',
                            style: TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                          Text(
                            'Maithreyan, 632001',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 6),
                          Text(
                            'HOME',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                        '23/11 thiyagaraja salai thiruvallivar nagar salavenpet v...',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
          ),
          const SizedBox(width: 12),
          OutlinedButton(
            onPressed: () {
              context.push('/address-form').then((_) => _loadDefaultAddress());
            },
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.grey.shade300),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            child: const Text(
              'Change',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Price Details Card Widget ─────────────────────────────
  Widget _buildPriceDetailsCard(BuildContext context, CartState state) {
    double totalMRP = 0;
    for (var item in state.items) {
      if (item.product != null) {
        totalMRP += (item.product!.price * 1.45) * item.quantity;
      }
    }
    double totalFees = 106.0;
    double totalDiscount = totalMRP - state.total + totalFees;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.isDarkMode ? const Color(0xFF1E1E2A) : Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade200, width: 8),
          bottom: BorderSide(color: Colors.grey.shade200, width: 8),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Price Details',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _priceRow('MRP (incl. of all taxes)', totalMRP.toCurrency),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Fees', style: TextStyle(fontSize: 13)),
              Text(
                totalFees.toCurrency,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _priceRow(
            'Discounts',
            '-${totalDiscount.toCurrency}',
            valueColor: const Color(0xFF2ED573),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Amount',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                state.total.toCurrency,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (totalDiscount > 0) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Divider(height: 1),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF2ED573).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'You will save ${totalDiscount.toCurrency} on this order',
                style: const TextStyle(
                  color: Color(0xFF2ED573),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _priceRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13)),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  // ── Bottom Sticky Action Bar Widget ───────────────────────
  Widget _buildBottomStickyBar(BuildContext context, CartState state) {
    double totalMRP = 0;
    for (var item in state.items) {
      if (item.product != null) {
        totalMRP += (item.product!.price * 1.45) * item.quantity;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: context.isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  totalMRP.toCurrency,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      state.total.toCurrency,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.info_outline, size: 14, color: Colors.grey),
                  ],
                ),
              ],
            ),
            SizedBox(
              width: 160,
              height: 46,
              child: ElevatedButton(
                onPressed: () => context.push('/checkout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFC200),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Place order',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Shared: Cart Item Card ──────────────────────────────
  Widget _buildCartItem(BuildContext context, dynamic item) {
    final product = item.product;
    if (product == null) {
      return Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: context.isDarkMode ? Colors.white.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text('Product information unavailable'),
      );
    }

    final double originalPriceSimulated = product.price * 1.35;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.isDarkMode ? const Color(0xFF1E1E2A) : Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image
              Column(
                children: [
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: CachedImage(
                          imageUrl: product.primaryImage,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          placeholderIcon: Icons.shopping_bag_outlined,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          color: Colors.black.withValues(alpha: 0.6),
                          child: const Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.zoom_in, size: 10, color: Colors.white),
                                SizedBox(width: 2),
                                Text(
                                  'Zoom',
                                  style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Qty Dropdown
                  InkWell(
                    onTap: () => _showQtyPickerDialog(context, item),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Text(
                            'Qty: ${item.quantity}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(Icons.arrow_drop_down, size: 16),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              // Product Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '11.6 Inch, Graphite Grey, 1.23 Kg',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Rating Block
                    Row(
                      children: [
                        Row(
                          children: List.generate(5, (idx) {
                            return const Icon(Icons.star, size: 12, color: Colors.green);
                          }),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '4.0',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '(3,097)',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: const Text(
                            'Assured',
                            style: TextStyle(color: Colors.blue, fontSize: 8, fontWeight: FontWeight.w900),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Price Row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        const Icon(Icons.arrow_downward, size: 12, color: Colors.green),
                        const Text(
                          '26%',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          originalPriceSimulated.toCurrency,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          product.effectivePrice.toCurrency,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(product.effectivePrice - 330).toCurrency} with UPI offer + more',
                      style: const TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '+ ₹106 Protect Promise Fee',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          'Or Pay ${(product.effectivePrice - 500).toCurrency} + ',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                        ),
                        const Icon(Icons.monetization_on, size: 12, color: Colors.amber),
                        const Text(
                          ' 10',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '20 Offers Available',
                      style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Row(
                      children: [
                        Icon(Icons.local_shipping, size: 14, color: Colors.black87),
                        SizedBox(width: 4),
                        Text(
                          'EXPRESS Delivery by tomorrow',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 8),
          // Actions Row
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: () => context.read<CartCubit>().removeItem(item.id),
                  icon: const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
                  label: const Text(
                    'Remove',
                    style: TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              Container(width: 1, height: 24, color: Colors.grey.shade300),
              Expanded(
                child: TextButton.icon(
                  onPressed: () => context.showSnackBar('Saved for later!'),
                  icon: const Icon(Icons.bookmark_border, size: 18, color: Colors.grey),
                  label: const Text(
                    'Save for later',
                    style: TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              Container(width: 1, height: 24, color: Colors.grey.shade300),
              Expanded(
                child: TextButton.icon(
                  onPressed: () => context.showSnackBar('Buying this now!'),
                  icon: const Icon(Icons.flash_on, size: 18, color: Colors.grey),
                  label: const Text(
                    'Buy this now',
                    style: TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showQtyPickerDialog(BuildContext context, dynamic item) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Select Quantity'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(10, (index) {
              final val = index + 1;
              return ListTile(
                title: Text('$val'),
                selected: val == item.quantity,
                onTap: () {
                  context.read<CartCubit>().updateQuantity(item.id, val);
                  Navigator.pop(dialogContext);
                },
              );
            }),
          ),
        );
      },
    );
  }

  // ── Shared: Coupon Section ──────────────────────────────
  Widget _buildCouponSection(CartState state) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _couponController,
                decoration: InputDecoration(
                  hintText: 'Promo code',
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: state.appliedCoupon != null
                  ? null
                  : () async {
                      final applied = await context
                          .read<CartCubit>()
                          .applyCoupon(_couponController.text.trim());
                      if (applied && context.mounted) {
                        context.showSuccessSnackBar('Coupon applied!');
                      }
                    },
              child: const Text('Apply'),
            ),
          ],
        ),
        if (state.appliedCoupon != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.local_offer,
                  size: 16, color: Color(0xFF2ED573)),
              const SizedBox(width: 4),
              Text(
                '${state.appliedCoupon!.code} - ${state.appliedCoupon!.discountLabel}',
                style: const TextStyle(
                  color: Color(0xFF2ED573),
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => context.read<CartCubit>().removeCoupon(),
                child: const Icon(Icons.close, size: 16, color: Colors.grey),
              ),
            ],
          ),
        ],
      ],
    );
  }

  // ── Shared: Pricing Summary ─────────────────────────────
  Widget _buildPricingSummary(CartState state) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Subtotal', style: context.textTheme.bodyMedium),
            Text(state.subtotal.toCurrency,
                style: context.textTheme.bodyMedium),
          ],
        ),
        if (state.discountAmount > 0) ...[
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Discount', style: context.textTheme.bodyMedium),
              Text(
                '-${state.discountAmount.toCurrency}',
                style: const TextStyle(
                    color: Color(0xFF2ED573), fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
        const SizedBox(height: 8),
        const Divider(),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Total', style: context.textTheme.titleLarge),
            Text(
              state.total.toCurrency,
              style: context.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
