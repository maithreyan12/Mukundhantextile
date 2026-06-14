import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/utils/responsive_helper.dart';
import '../../../shared/widgets/cached_image.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/premium_button.dart';
import '../../../shared/widgets/quantity_stepper.dart';
import '../bloc/cart_cubit.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _couponController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<CartCubit>().loadCart();
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
      body: BlocBuilder<CartCubit, CartState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
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
  // MOBILE LAYOUT — Stacked (original)
  // ═══════════════════════════════════════════════════════
  Widget _buildMobileLayout(BuildContext context, CartState state) {
    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: state.items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = state.items[index];
              return _buildCartItem(context, item);
            },
          ),
        ),

        // Bottom summary
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: context.isDarkMode
                ? Theme.of(context).colorScheme.surface
                : Colors.white,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildCouponSection(state),
                const SizedBox(height: 16),
                _buildPricingSummary(state),
                const SizedBox(height: 16),
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
    );
  }

  // ── Shared: Cart Item Card ──────────────────────────────
  Widget _buildCartItem(BuildContext context, dynamic item) {
    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFFF6B6B),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) => context.read<CartCubit>().removeItem(item.id),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.isDarkMode
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedImage(
                imageUrl: item.product?.primaryImage,
                width: 80,
                height: 80,
                placeholderIcon: Icons.shopping_bag_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.product?.name ?? '',
                    style: context.textTheme.titleSmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.totalPrice.toCurrency,
                    style: context.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            QuantityStepper(
              quantity: item.quantity,
              onChanged: (q) =>
                  context.read<CartCubit>().updateQuantity(item.id, q),
            ),
          ],
        ),
      ),
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
