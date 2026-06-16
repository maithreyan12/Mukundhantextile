import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/utils/responsive_helper.dart';
import '../../../shared/widgets/product_card.dart';
import '../../../shared/widgets/shimmer_loading.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/cached_image.dart';
import '../../wishlist/bloc/wishlist_cubit.dart';
import '../../cart/bloc/cart_cubit.dart';
import '../bloc/product_list_cubit.dart';
import '../../home/bloc/home_cubit.dart';
import '../../../data/models/browse_settings.dart';
import '../../../data/repositories/browse_settings_repository.dart';

class ProductListScreen extends StatefulWidget {
  final String? categoryId;
  final String? sort;
  final double? maxPrice;

  const ProductListScreen({super.key, this.categoryId, this.sort, this.maxPrice});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final ScrollController _scrollController = ScrollController();
  int _selectedCategoryIndex = 0;
  BrowseSettings? _browseSettings;


  bool get _shouldShowGrid =>
      widget.categoryId != null || widget.sort != null || widget.maxPrice != null;

  @override
  void initState() {
    super.initState();
    if (_shouldShowGrid) {
      context.read<ProductListCubit>().loadProducts(
            categoryId: widget.categoryId,
            sortBy: widget.sort == 'new'
                ? 'created_at'
                : widget.sort == 'popular'
                    ? 'review_count'
                    : 'created_at',
            maxPrice: widget.maxPrice,
          );
      _scrollController.addListener(_onScroll);
    } else {
      // Browse tab: load categories/home data
      context.read<HomeCubit>().loadHome();
      _loadBrowseSettings();
    }
  }

  Future<void> _loadBrowseSettings() async {
    if (!mounted) return;
    try {
      final settings = await BrowseSettingsRepository().getSettings();
      if (mounted) {
        setState(() {
          _browseSettings = settings;
        });
      }
    } catch (_) {
      // ignore
    }
  }



  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<ProductListCubit>().loadMore();
    }
  }

  @override
  void didUpdateWidget(covariant ProductListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.categoryId != oldWidget.categoryId ||
        widget.sort != oldWidget.sort ||
        widget.maxPrice != oldWidget.maxPrice) {
      if (_shouldShowGrid) {
        context.read<ProductListCubit>().loadProducts(
              categoryId: widget.categoryId,
              sortBy: widget.sort == 'new'
                  ? 'created_at'
                  : widget.sort == 'popular'
                      ? 'review_count'
                      : 'created_at',
              maxPrice: widget.maxPrice,
            );
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isLargeScreen(context);

    // If a categoryId is provided, show standard Product Grid
    if (_shouldShowGrid) {
      return Scaffold(
        appBar: isDesktop
            ? null
            : AppBar(
                title: Text('PRODUCTS',
                    style: context.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                centerTitle: true,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  onPressed: () => context.pop(),
                ),
              ),
        body: BlocBuilder<ProductListCubit, ProductListState>(
          builder: (context, state) {
            if (state.isLoading) {
              return ShimmerLoading.productGrid();
            }
            if (state.error != null && state.products.isEmpty) {
              return AppErrorWidget(
                message: state.error!,
                onRetry: () => context.read<ProductListCubit>().loadProducts(
                      categoryId: widget.categoryId,
                      sortBy: widget.sort == 'new'
                          ? 'created_at'
                          : widget.sort == 'popular'
                              ? 'review_count'
                              : 'created_at',
                      maxPrice: widget.maxPrice,
                    ),
              );
            }

            if (state.products.isEmpty) {
              return const EmptyStateWidget(
                icon: Icons.inventory_2_outlined,
                title: 'No Products Found',
                subtitle: 'Try adjusting your filters',
              );
            }

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1400),
                child: GridView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.all(Responsive.horizontalPadding(context)),
                  gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: Responsive.productGridMaxExtent(context),
                    childAspectRatio: 0.60,
                    crossAxisSpacing: isDesktop ? 16 : 8,
                    mainAxisSpacing: isDesktop ? 16 : 16,
                  ),
                  itemCount:
                      state.products.length + (state.isLoadingMore ? 2 : 0),
                  itemBuilder: (context, index) {
                    if (index >= state.products.length) {
                      return const ShimmerLoading(height: 250);
                    }
                    final product = state.products[index];
                    return BlocBuilder<WishlistCubit, WishlistState>(
                      builder: (context, wishState) {
                        return ProductCard(
                          product: product,
                          isInWishlist:
                              wishState.wishlistIds.contains(product.id),
                          onTap: () => context.push('/product/${product.id}'),
                          onWishlistTap: () => context
                              .read<WishlistCubit>()
                              .toggleWishlist(product.id),
                          onBuyNow: () {
                            context
                                .read<CartCubit>()
                                .addToCart(productId: product.id);
                            context.showSuccessSnackBar('Added to cart!');
                            context.go('/cart');
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            );
          },
        ),
      );
    }

    // Otherwise, show the premium Flipkart split Browse Categories layout
    return Scaffold(
      backgroundColor: context.isDarkMode ? const Color(0xFF0F0F1A) : Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: context.isDarkMode ? const Color(0xFF1E1E2A) : Colors.white,
        title: Text(
          'All Categories',
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w900,
            fontSize: 18,
            color: context.isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: context.isDarkMode ? Colors.white70 : Colors.black87),
            onPressed: () => context.push('/search'),
          ),
          IconButton(
            icon: Icon(Icons.camera_alt_outlined, color: context.isDarkMode ? Colors.white70 : Colors.black87),
            onPressed: () => context.push('/search'),
          ),
          BlocBuilder<CartCubit, CartState>(
            builder: (context, cartState) {
              return IconButton(
                icon: Badge(
                  isLabelVisible: cartState.itemCount > 0,
                  label: Text('${cartState.itemCount}'),
                  child: Icon(Icons.shopping_cart_outlined, color: context.isDarkMode ? Colors.white70 : Colors.black87),
                ),
                onPressed: () {
                  context.read<CartCubit>().loadCart();
                  context.go('/cart');
                },
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: BlocBuilder<HomeCubit, HomeState>(
        builder: (context, homeState) {
          if (homeState.isLoading && homeState.categories.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (homeState.error != null && homeState.categories.isEmpty) {
            return AppErrorWidget(
              message: homeState.error!,
              onRetry: () => context.read<HomeCubit>().loadHome(),
            );
          }
          if (homeState.categories.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.category_outlined,
              title: 'No Categories Available',
              subtitle: 'Check back later!',
            );
          }

          final categories = homeState.categories;
          if (_selectedCategoryIndex >= categories.length) {
            _selectedCategoryIndex = 0;
          }
          final selectedCategory = categories[_selectedCategoryIndex];

          // Filter launches or featured products for selected category if possible
          final categoryLaunches = homeState.featured
              .where((p) => p.categoryId == selectedCategory.id)
              .toList();
          final displayLaunches = categoryLaunches.isNotEmpty
              ? categoryLaunches
              : homeState.featured.take(6).toList();

          return Row(
            children: [
              // ── 1. Left Vertical Navigation Sidebar ──────────────────
              Container(
                width: isDesktop ? 220 : 95,
                color: context.isDarkMode ? const Color(0xFF141420) : const Color(0xFFF1F2F4),
                child: ListView.builder(
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final cat = categories[index];
                    final isSelected = index == _selectedCategoryIndex;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedCategoryIndex = index;
                        });
                      },
                      child: Container(
                        width: double.infinity,
                        padding: isDesktop
                            ? const EdgeInsets.symmetric(vertical: 14, horizontal: 16)
                            : const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (context.isDarkMode ? const Color(0xFF1E1E2A) : Colors.white)
                              : Colors.transparent,
                          border: isSelected
                              ? Border(
                                  left: BorderSide(
                                    color: Theme.of(context).colorScheme.primary,
                                    width: 4,
                                  ),
                                )
                              : null,
                        ),
                        child: isDesktop
                            ? Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isSelected
                                          ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                                          : (context.isDarkMode ? Colors.white.withValues(alpha: 0.05) : Colors.white),
                                      border: Border.all(
                                        color: isSelected
                                            ? Theme.of(context).colorScheme.primary
                                            : Colors.transparent,
                                        width: 1.5,
                                      ),
                                    ),
                                    padding: const EdgeInsets.all(2),
                                    child: ClipOval(
                                      child: CachedImage(
                                        imageUrl: cat.imageUrl ?? '',
                                        width: 36,
                                        height: 36,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      cat.name,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: isSelected ? FontWeight.w900 : FontWeight.w500,
                                        color: isSelected
                                            ? Theme.of(context).colorScheme.primary
                                            : (context.isDarkMode ? Colors.white70 : Colors.black87),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Circular Category Avatar
                                  Container(
                                    width: 52,
                                    height: 52,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isSelected
                                          ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                                          : (context.isDarkMode ? Colors.white.withValues(alpha: 0.05) : Colors.white),
                                      border: Border.all(
                                        color: isSelected
                                            ? Theme.of(context).colorScheme.primary
                                            : Colors.transparent,
                                        width: 1.5,
                                      ),
                                    ),
                                    padding: const EdgeInsets.all(2),
                                    child: ClipOval(
                                      child: CachedImage(
                                        imageUrl: cat.imageUrl ?? '',
                                        width: 48,
                                        height: 48,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    cat.name,
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: isSelected ? FontWeight.w900 : FontWeight.w500,
                                      color: isSelected
                                          ? Theme.of(context).colorScheme.primary
                                          : (context.isDarkMode ? Colors.white70 : Colors.black87),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    );
                  },
                ),
              ),

              // ── 2. Right Main Scrollable Content Panel ────────────────
              Expanded(
                child: Container(
                  color: context.isDarkMode ? const Color(0xFF0F0F1A) : Colors.white,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: isDesktop ? 1200 : double.infinity),
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(isDesktop ? 24 : 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        // Promo Banner at top
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            context.push('/products?category=${selectedCategory.id}');
                          },
                          child: Container(
                            width: double.infinity,
                            height: 100,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              gradient: const LinearGradient(
                                colors: [Color(0xFF2196F3), Color(0xFF00BCD4)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'LATEST TRENDS',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 16,
                                          letterSpacing: 1.0,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Everyday • Click to View',
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.9),
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.arrow_forward_rounded, color: Color(0xFF2196F3), size: 16),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Popular Store Section
                        const Text(
                          'Popular Store',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Builder(
                          builder: (context) {
                            final settings = _browseSettings ?? const BrowseSettings(id: 'popular_store_settings');
                            final items = <Widget>[];

                            if (settings.liveNowEnabled) {
                              items.add(
                                _buildPopularStoreItem(
                                  context,
                                  icon: Icons.flash_on_rounded,
                                  bgColor: Colors.amber.shade100,
                                  iconColor: Colors.amber.shade800,
                                  label: settings.liveNowLabel,
                                  onTap: () => context.push('/products?sort=${settings.liveNowSort}'),
                                ),
                              );
                            }

                            if (settings.dealsEnabled) {
                              items.add(
                                _buildPopularStoreItem(
                                  context,
                                  icon: Icons.percent_rounded,
                                  bgColor: Colors.red.shade100,
                                  iconColor: Colors.red.shade800,
                                  label: settings.dealsLabel,
                                  onTap: () => context.push('/products?maxPrice=${settings.dealsPrice.toStringAsFixed(0)}'),
                                ),
                              );
                            }

                            if (settings.saleComingEnabled) {
                              items.add(
                                _buildPopularStoreItem(
                                  context,
                                  icon: Icons.calendar_month_rounded,
                                  bgColor: Colors.purple.shade100,
                                  iconColor: Colors.purple.shade800,
                                  label: settings.saleComingLabel,
                                  onTap: () => context.push('/products?sort=${settings.saleComingSort}'),
                                ),
                              );
                            }

                            items.add(
                              _buildPopularStoreItem(
                                context,
                                icon: Icons.local_mall_rounded,
                                bgColor: Colors.green.shade100,
                                iconColor: Colors.green.shade800,
                                label: selectedCategory.name,
                                onTap: () => context.push('/products?category=${selectedCategory.id}'),
                              ),
                            );

                            return GridView.count(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisCount: 3,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 8,
                              childAspectRatio: 0.82,
                              children: items,
                            );
                          },
                        ),


                        const SizedBox(height: 24),

                        // New & Upcoming Launches Section
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'New & Upcoming Launches',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => context.push('/products?category=${selectedCategory.id}'),
                              child: Text(
                                'View All',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: isDesktop ? 6 : 3,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 8,
                            childAspectRatio: isDesktop ? 0.72 : 0.62,
                          ),
                          itemCount: displayLaunches.length,
                          itemBuilder: (context, index) {
                            final product = displayLaunches[index];
                            final badgeTexts = ['BUY NOW', 'SHOP NOW', 'NOTIFY ME', 'SALE LIVE'];
                            final badgeColor = [Colors.teal, Colors.blue, Colors.orange, Colors.red][index % 4];

                            return GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => context.push('/product/${product.id}'),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: context.isDarkMode ? const Color(0xFF1E1E2A) : Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: context.isDarkMode ? Colors.white10 : Colors.grey.shade200,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          ClipRRect(
                                            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                                            child: CachedImage(
                                              imageUrl: product.images.isNotEmpty ? product.images[0] : '',
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                          Positioned(
                                            bottom: 0,
                                            left: 0,
                                            right: 0,
                                            child: Container(
                                              color: badgeColor,
                                              padding: const EdgeInsets.symmetric(vertical: 2.5),
                                              child: Text(
                                                badgeTexts[index % badgeTexts.length],
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w900,
                                                  fontSize: 8,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(6.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            product.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            product.price.toCurrency,
                                            style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w900,
                                              color: Theme.of(context).colorScheme.primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
        },
      ),
    );
  }

  Widget _buildPopularStoreItem(
    BuildContext context, {
    required IconData icon,
    required Color bgColor,
    required Color iconColor,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
