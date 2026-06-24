import 'package:flutter/material.dart';
import '../../../core/utils/responsive_helper.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/extensions.dart';
import '../../../shared/widgets/cached_image.dart';
import '../../../shared/widgets/price_text.dart';
import '../../../shared/widgets/rating_stars.dart';
import '../../../shared/widgets/shimmer_loading.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../wishlist/bloc/wishlist_cubit.dart';
import '../../cart/bloc/cart_cubit.dart';
import '../bloc/product_detail_cubit.dart';
import '../../../data/models/product.dart';

import '../../../shared/widgets/size_selector.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();
  String? _selectedSize;

  @override
  void initState() {
    super.initState();
    context.read<ProductDetailCubit>().loadProduct(widget.productId);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);

    return Scaffold(
      appBar: isDesktop
          ? AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                onPressed: () => context.pop(),
              ),
              title: Text('Product Details',
                  style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            )
          : null,
      body: BlocBuilder<ProductDetailCubit, ProductDetailState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.error != null && state.product == null) {
            return AppErrorWidget(
              message: state.error!,
              onRetry: () => context
                  .read<ProductDetailCubit>()
                  .loadProduct(widget.productId),
            );
          }
          final product = state.product;
          if (product == null) {
            return const ShimmerLoading(height: double.infinity);
          }

          if (isDesktop) {
            return _buildDesktopLayout(context, product, state);
          }
          return _buildMobileLayout(context, product, state);
        },
      ),
      bottomNavigationBar: Responsive.isDesktop(context)
          ? null
          : _buildMobileBottomBar(context),
    );
  }

  // ═══════════════════════════════════════════════════════
  // DESKTOP LAYOUT — Side by side (Image | Info)
  // ═══════════════════════════════════════════════════════
  Widget _buildDesktopLayout(BuildContext context, Product product, ProductDetailState state) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Left: Image Gallery ──
                  Expanded(
                    flex: 5,
                    child: Column(
                      children: [
                        // Main image
                        Container(
                          height: 500,
                          decoration: BoxDecoration(
                            color: context.isDarkMode
                                ? const Color(0xFF1A1A1A)
                                : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: context.isDarkMode
                                  ? Colors.white10
                                  : Colors.grey.shade200,
                            ),
                          ),
                          child: Stack(
                            children: [
                              PageView.builder(
                                controller: _pageController,
                                itemCount: product.images.isEmpty
                                    ? 1
                                    : product.images.length,
                                onPageChanged: (i) =>
                                    setState(() => _currentImageIndex = i),
                                itemBuilder: (_, i) {
                                  return ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: CachedImage(
                                      imageUrl: product.images.isNotEmpty
                                          ? product.images[i]
                                          : null,
                                      fit: BoxFit.contain,
                                      placeholderIcon:
                                          Icons.shopping_bag_outlined,
                                    ),
                                  );
                                },
                              ),
                              if (product.hasDiscount)
                                Positioned(
                                  top: 16,
                                  left: 16,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFF6B6B),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '-${product.discountPercent}% OFF',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        // Thumbnail strip
                        if (product.images.length > 1)
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: SizedBox(
                              height: 72,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: product.images.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(width: 8),
                                itemBuilder: (_, i) {
                                  final isSelected = i == _currentImageIndex;
                                  return GestureDetector(
                                    onTap: () {
                                      _pageController.animateToPage(i,
                                          duration:
                                              const Duration(milliseconds: 300),
                                          curve: Curves.easeInOut);
                                    },
                                    child: Container(
                                      width: 72,
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(8),
                                        border: Border.all(
                                          color: isSelected
                                              ? Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                              : Colors.grey.shade300,
                                          width: isSelected ? 2 : 1,
                                        ),
                                      ),
                                      child: ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(7),
                                        child: CachedImage(
                                          imageUrl: product.images[i],
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 40),

                  // ── Right: Product Info ──
                  Expanded(
                    flex: 5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (product.categoryName != null)
                          Text(
                            product.categoryName!.toUpperCase(),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1,
                            ),
                          ),
                        const SizedBox(height: 8),
                        Text(product.name,
                            style: context.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            )),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            RatingStars(rating: product.rating),
                            const SizedBox(width: 8),
                            Text(
                              '${product.rating} (${product.reviewCount} reviews)',
                              style: context.textTheme.bodySmall,
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        PriceText(
                          price: product.price,
                          discountPrice: product.discountPrice,
                          priceStyle:
                              context.textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: context.isDarkMode
                                ? Colors.white
                                : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Size
                        Text('Size',
                            style: context.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            )),
                        const SizedBox(height: 12),
                        SizeSelector(
                          sizes: const ['S', 'M', 'L', 'XL', 'OVERSIZED'],
                          initialSize: _selectedSize,
                          onSizeSelected: (size) => _selectedSize = size,
                        ),
                        const SizedBox(height: 28),

                        // Stock info
                        Row(
                          children: [
                            Icon(
                              product.inStock
                                  ? Icons.check_circle_outline
                                  : Icons.cancel_outlined,
                              size: 18,
                              color: product.inStock
                                  ? (context.isDarkMode
                                      ? Colors.white
                                      : Colors.black)
                                  : const Color(0xFFFF6B6B),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              product.inStock
                                  ? 'In Stock (${product.stock})'
                                  : 'Out of Stock',
                              style: TextStyle(
                                color: product.inStock
                                    ? (context.isDarkMode
                                        ? Colors.white
                                        : Colors.black)
                                    : const Color(0xFFFF6B6B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),

                        // Action buttons (Flipkart style)
                        Row(
                          children: [
                            // Add to Cart
                            Expanded(
                              child: SizedBox(
                                height: 52,
                                child: OutlinedButton(
                                  onPressed: product.inStock
                                      ? () {
                                          context.read<CartCubit>().addToCart(
                                                productId: product.id,
                                                variant: _selectedSize != null
                                                    ? {'size': _selectedSize}
                                                    : null,
                                              );
                                          context.showSuccessSnackBar('Added to cart!');
                                        }
                                      : null,
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                        color: context.isDarkMode
                                            ? Colors.white24
                                            : Colors.grey.shade400),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(26)),
                                  ),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.add_shopping_cart_rounded, size: 18,
                                          color: context.isDarkMode ? Colors.white : Colors.black87),
                                        const SizedBox(width: 8),
                                        Text('ADD TO CART',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 14,
                                            letterSpacing: 0.5,
                                            color: context.isDarkMode ? Colors.white : Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Buy Now with price
                            Expanded(
                              child: SizedBox(
                                height: 52,
                                child: GestureDetector(
                                  onTap: product.inStock
                                      ? () {
                                          context.read<CartCubit>().addToCart(
                                                productId: product.id,
                                                variant: _selectedSize != null
                                                    ? {'size': _selectedSize}
                                                    : null,
                                              );
                                          context.push('/checkout');
                                        }
                                      : null,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: product.inStock
                                          ? LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: [
                                                Theme.of(context).colorScheme.primary,
                                                Color.lerp(Theme.of(context).colorScheme.primary, Colors.black, 0.15) ?? Theme.of(context).colorScheme.primary,
                                              ],
                                            )
                                          : null,
                                      color: product.inStock ? null : Colors.grey.shade400,
                                      borderRadius: BorderRadius.circular(26),
                                      boxShadow: product.inStock
                                          ? [
                                              BoxShadow(
                                                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                                                blurRadius: 8,
                                                offset: const Offset(0, 3),
                                              ),
                                            ]
                                          : null,
                                    ),
                                    alignment: Alignment.center,
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 12),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.bolt_rounded, size: 18, color: Colors.white),
                                            const SizedBox(width: 6),
                                            Text(
                                              product.inStock
                                                  ? 'BUY NOW  ${product.effectivePrice.toCurrency}'
                                                  : 'OUT OF STOCK',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w900,
                                                fontSize: 14,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Wishlist button
                        const SizedBox(height: 12),
                        BlocBuilder<WishlistCubit, WishlistState>(
                          builder: (context, wishState) {
                            final inWishlist =
                                wishState.wishlistIds.contains(product.id);
                            return SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () => context
                                    .read<WishlistCubit>()
                                    .toggleWishlist(product.id),
                                icon: Icon(
                                  inWishlist
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  size: 18,
                                  color: inWishlist
                                      ? const Color(0xFFFF6B6B)
                                      : null,
                                ),
                                label: Text(inWishlist
                                    ? 'ADDED TO WISHLIST'
                                    : 'ADD TO WISHLIST'),
                                style: OutlinedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(26)),
                                ),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 32),
                        const Divider(),
                        const SizedBox(height: 20),

                        // Description
                        Text('Description',
                            style: context.textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Text(product.description,
                            style: context.textTheme.bodyMedium?.copyWith(
                              height: 1.6,
                            )),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),
              const Divider(),
              const SizedBox(height: 20),

              // Reviews section — full width
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Reviews (${state.reviews.length})',
                  style: context.textTheme.titleMedium,
                ),
              ),
              const SizedBox(height: 12),
              ...state.reviews.take(5).map((review) => _buildReviewCard(review)),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // MOBILE LAYOUT — Stacked vertical (original)
  // ═══════════════════════════════════════════════════════
  Widget _buildMobileLayout(BuildContext context, Product product, ProductDetailState state) {
    return CustomScrollView(
      slivers: [
        // ── Image Gallery ──────────────────────────
        SliverAppBar(
          expandedHeight: MediaQuery.of(context).size.height * 0.70,
          pinned: true,
          leading: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  size: 18, color: Colors.black),
            ),
            onPressed: () => context.pop(),
          ),
          actions: [
            BlocBuilder<WishlistCubit, WishlistState>(
              builder: (context, wishState) {
                final inWishlist =
                    wishState.wishlistIds.contains(product.id);
                return IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      inWishlist
                          ? Icons.favorite
                          : Icons.favorite_border,
                      size: 18,
                      color: inWishlist
                          ? const Color(0xFFFF6B6B)
                          : Colors.black,
                    ),
                  ),
                  onPressed: () => context
                      .read<WishlistCubit>()
                      .toggleWishlist(product.id),
                );
              },
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              children: [
                PageView.builder(
                  controller: _pageController,
                  itemCount:
                      product.images.isEmpty ? 1 : product.images.length,
                  onPageChanged: (i) =>
                      setState(() => _currentImageIndex = i),
                  itemBuilder: (_, i) {
                    return Hero(
                      tag: 'product-${product.id}',
                      child: CachedImage(
                        imageUrl: product.images.isNotEmpty
                            ? product.images[i]
                            : null,
                        fit: BoxFit.cover,
                        placeholderIcon: Icons.shopping_bag_outlined,
                      ),
                    );
                  },
                ),
                if (product.images.length > 1)
                  Positioned(
                    bottom: 16,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        product.images.length,
                        (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: i == _currentImageIndex ? 24 : 8,
                          height: 8,
                          margin:
                              const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            color: i == _currentImageIndex
                                ? Theme.of(context).colorScheme.primary
                                : Colors.white54,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ),
                if (product.hasDiscount)
                  Positioned(
                    top: 100,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6B6B),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '-${product.discountPercent}% OFF',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        // ── Product Info ───────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (product.categoryName != null)
                  Text(
                    product.categoryName!.toUpperCase(),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                  ),
                const SizedBox(height: 8),
                Text(product.name,
                    style: context.textTheme.headlineMedium),
                const SizedBox(height: 12),
                Row(
                  children: [
                    RatingStars(rating: product.rating),
                    const SizedBox(width: 8),
                    Text(
                      '${product.rating} (${product.reviewCount} reviews)',
                      style: context.textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                PriceText(
                  price: product.price,
                  discountPrice: product.discountPrice,
                  priceStyle: context.textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: context.isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 24),

                // ── Size Selector ──────────────────────
                Text('Size', style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                )),
                const SizedBox(height: 12),
                SizeSelector(
                  sizes: const ['S', 'M', 'L', 'XL', 'OVERSIZED'],
                  initialSize: _selectedSize,
                  onSizeSelected: (size) => _selectedSize = size,
                ),
                const SizedBox(height: 32),
                Text('Description',
                    style: context.textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(product.description,
                    style: context.textTheme.bodyMedium?.copyWith(
                      height: 1.6,
                    )),
                const SizedBox(height: 16),
                // Stock info
                Row(
                  children: [
                    Icon(
                      product.inStock
                          ? Icons.check_circle_outline
                          : Icons.cancel_outlined,
                      size: 18,
                      color: product.inStock
                          ? (context.isDarkMode ? Colors.white : Colors.black)
                          : const Color(0xFFFF6B6B),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      product.inStock
                          ? 'In Stock (${product.stock})'
                          : 'Out of Stock',
                      style: TextStyle(
                        color: product.inStock
                            ? (context.isDarkMode ? Colors.white : Colors.black)
                            : const Color(0xFFFF6B6B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),

                // ── Reviews ────────────────────────
                Text(
                  'Reviews (${state.reviews.length})',
                  style: context.textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                ...state.reviews.take(5).map((review) => _buildReviewCard(review)),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Review Card (shared) ────────────────────────────────
  Widget _buildReviewCard(dynamic review) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.isDarkMode
              ? Colors.white.withValues(alpha: 0.04)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor:
                      Theme.of(context).colorScheme.primary
                          .withValues(alpha: 0.1),
                  child: Text(
                    (review.userName ?? 'U')[0].toUpperCase(),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.userName ?? 'User',
                        style: context.textTheme.labelLarge,
                      ),
                      RatingStars(
                        rating: review.rating.toDouble(),
                        size: 14,
                      ),
                    ],
                  ),
                ),
                Text(
                  review.createdAt.timeAgo,
                  style: context.textTheme.labelSmall,
                ),
              ],
            ),
            if (review.comment != null &&
                review.comment!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(review.comment!,
                  style: context.textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }

  // ── Mobile Bottom Bar (Flipkart Style) ─────────────────
  Widget _buildMobileBottomBar(BuildContext context) {
    return BlocBuilder<ProductDetailCubit, ProductDetailState>(
      builder: (context, state) {
        if (state.product == null) return const SizedBox.shrink();
        final product = state.product!;
        final primaryColor = Theme.of(context).colorScheme.primary;

        return Container(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          decoration: BoxDecoration(
            color: context.isDarkMode
                ? Theme.of(context).colorScheme.surface
                : Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, -4),
              ),
            ],
            border: Border(
              top: BorderSide(
                color: context.isDarkMode ? Colors.white10 : const Color(0xFFEEEEEE),
              ),
            ),
          ),
          child: SafeArea(
            minimum: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                // Cart icon button
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: context.isDarkMode ? Colors.white24 : Colors.grey.shade300,
                    ),
                    borderRadius: BorderRadius.circular(26),
                  ),
                  child: IconButton(
                    onPressed: () => context.go('/cart'),
                    icon: Icon(
                      Icons.shopping_cart_outlined,
                      color: context.isDarkMode ? Colors.white70 : Colors.black87,
                    ),
                    tooltip: 'Go to Cart',
                  ),
                ),
                const SizedBox(width: 10),

                // Add to Cart button
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: OutlinedButton(
                      onPressed: product.inStock
                          ? () {
                              context.read<CartCubit>().addToCart(
                                    productId: product.id,
                                    variant: _selectedSize != null
                                        ? {'size': _selectedSize}
                                        : null,
                                  );
                              context.showSuccessSnackBar('Added to cart!');
                            }
                          : null,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: context.isDarkMode ? Colors.white24 : Colors.grey.shade400,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26),
                        ),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.add_shopping_cart_rounded,
                              size: 18,
                              color: context.isDarkMode ? Colors.white : Colors.black87,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'ADD TO CART',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                letterSpacing: 0.5,
                                color: context.isDarkMode ? Colors.white : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Buy Now button with price
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: GestureDetector(
                      onTap: product.inStock
                          ? () {
                              context.read<CartCubit>().addToCart(
                                    productId: product.id,
                                    variant: _selectedSize != null
                                        ? {'size': _selectedSize}
                                        : null,
                                  );
                              context.push('/checkout');
                            }
                          : null,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: product.inStock
                              ? LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    primaryColor,
                                    Color.lerp(primaryColor, Colors.black, 0.15) ?? primaryColor,
                                  ],
                                )
                              : null,
                          color: product.inStock ? null : Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(26),
                          boxShadow: product.inStock
                              ? [
                                  BoxShadow(
                                    color: primaryColor.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ]
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  product.inStock ? 'BUY NOW' : 'OUT OF STOCK',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 13,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                if (product.inStock)
                                  Text(
                                    product.effectivePrice.toCurrency,
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.9),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 11,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
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
}
