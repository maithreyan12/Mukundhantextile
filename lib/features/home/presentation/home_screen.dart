import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/utils/responsive_helper.dart';
import '../../../core/constants.dart';
import '../../../data/models/product.dart';
import '../../../shared/widgets/cached_image.dart';
import '../../../shared/widgets/product_card.dart';
import '../../../shared/widgets/shimmer_loading.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../wishlist/bloc/wishlist_cubit.dart';
import '../bloc/home_cubit.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    context.read<HomeCubit>().loadHome();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isLargeScreen(context);

    return Scaffold(
      body: BlocBuilder<HomeCubit, HomeState>(
        builder: (context, state) {
          if (state.error != null && state.banners.isEmpty) {
            return AppErrorWidget(
              message: state.error!,
              onRetry: () => context.read<HomeCubit>().loadHome(),
            );
          }

          return RefreshIndicator(
            onRefresh: () => context.read<HomeCubit>().loadHome(),
            child: CustomScrollView(
              slivers: [
                // ── App Bar (mobile only — desktop has top nav from shell) ──
                if (!isDesktop)
                  SliverAppBar(
                    title: Text(
                      AppConstants.appName.toUpperCase(),
                      style: context.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 3.0,
                        color: context.isDarkMode ? Colors.white : const Color(0xFF1A1A1A),
                      ),
                    ),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.notifications_none_rounded),
                        onPressed: () => context.push('/notifications'),
                      ),
                    ],
                  ),

                // ── Search Bar (mobile only — desktop has search in top nav) ──
                if (!isDesktop)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                      child: GestureDetector(
                        onTap: () => context.push('/search'),
                        child: Container(
                          height: 48,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: context.isDarkMode
                                ? Colors.white.withValues(alpha: 0.06)
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.search,
                                  color: Colors.grey.shade500, size: 20),
                              const SizedBox(width: 12),
                              Text(
                                'Search products...',
                                style: TextStyle(color: Colors.grey.shade500),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                // ── Banner Carousel ─────────────────────
                if (state.isLoading)
                  SliverToBoxAdapter(child: ShimmerLoading.banner())
                else if (state.banners.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1400),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: isDesktop ? 24 : 0,
                            vertical: isDesktop ? 16 : 0,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(isDesktop ? 12 : 0),
                            child: CarouselSlider.builder(
                              itemCount: state.banners.length,
                              options: CarouselOptions(
                                height: isDesktop ? 360 : 400,
                                autoPlay: true,
                                enlargeCenterPage: false,
                                viewportFraction: 1.0,
                                autoPlayInterval: const Duration(seconds: 8),
                              ),
                              itemBuilder: (_, index, _) {
                                final banner = state.banners[index];
                                return GestureDetector(
                                  onTap: () {
                                    if (banner.targetType == 'product' &&
                                        banner.targetId != null) {
                                      context.push('/product/${banner.targetId}');
                                    } else if (banner.targetType == 'category' &&
                                        banner.targetId != null) {
                                      context.push(
                                          '/products?category=${banner.targetId}');
                                    }
                                  },
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      CachedImage(
                                        imageUrl: banner.imageUrl,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        placeholderIcon: Icons.camera_alt_outlined,
                                      ),
                                      Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              Colors.transparent,
                                              Colors.black.withValues(alpha: 0.7),
                                            ]
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 40,
                                        left: 24,
                                        child: Text(
                                          (banner.title != null && banner.title!.isNotEmpty)
                                              ? banner.title!.replaceAll('\\n', '\n')
                                              : 'LIMITED\nDROP',
                                          style: context.textTheme.displayLarge?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w900,
                                            height: 1.1,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 32)),

                // ── Categories ──────────────────────────
                if (state.isLoading)
                  SliverToBoxAdapter(
                      child: ShimmerLoading.horizontalList(height: 90))
                else if (state.categories.isNotEmpty) ...[
                  _sectionHeader('CATEGORIES', onSeeAll: () {}),
                  SliverToBoxAdapter(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1400),
                        child: SizedBox(
                          height: 100,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: EdgeInsets.symmetric(
                              horizontal: Responsive.horizontalPadding(context),
                            ),
                            itemCount: state.categories.length,
                            separatorBuilder: (_, _) => SizedBox(
                              width: isDesktop ? 24 : 16,
                            ),
                            itemBuilder: (_, i) {
                              final cat = state.categories[i];
                              return GestureDetector(
                                onTap: () => context
                                    .push('/products?category=${cat.id}'),
                                child: Column(
                                  children: [
                                    Container(
                                      width: isDesktop ? 68 : 60,
                                      height: isDesktop ? 68 : 60,
                                      decoration: BoxDecoration(
                                        color: context.isDarkMode ? const Color(0xFF1A1A1A) : Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: context.isDarkMode ? const Color(0xFF333333) : Colors.grey.shade300,
                                        ),
                                      ),
                                      child: cat.imageUrl != null
                                          ? ClipRRect(
                                              borderRadius: BorderRadius.circular(8),
                                              child: CachedImage(
                                                imageUrl: cat.imageUrl,
                                                width: isDesktop ? 68 : 60,
                                                height: isDesktop ? 68 : 60,
                                              ),
                                            )
                                          : Icon(Icons.category_outlined,
                                              color: Theme.of(context).colorScheme.primary),
                                    ),
                                    const SizedBox(height: 8),
                                    SizedBox(
                                      width: isDesktop ? 80 : 70,
                                      child: Text(
                                        cat.name,
                                        style: context.textTheme.labelSmall?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.5,
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ],

                const SliverToBoxAdapter(child: SizedBox(height: 8)),

                // ── New Arrivals ────────────────────────
                if (state.isLoading)
                  SliverToBoxAdapter(
                      child: ShimmerLoading.horizontalList(height: 220))
                else if (state.newArrivals.isNotEmpty) ...[
                  _sectionHeader('NEW DROPS',
                      onSeeAll: () => context.push('/products?sort=new')),
                  isDesktop
                      ? _desktopProductGrid(state.newArrivals)
                      : _horizontalProductList(state.newArrivals),
                ],

                const SliverToBoxAdapter(child: SizedBox(height: 8)),

                // ── Best Sellers ────────────────────────
                if (state.isLoading)
                  SliverToBoxAdapter(
                      child: ShimmerLoading.horizontalList(height: 220))
                else if (state.bestSellers.isNotEmpty) ...[
                  _sectionHeader('TRENDING',
                      onSeeAll: () => context.push('/products?sort=popular')),
                  isDesktop
                      ? _desktopProductGrid(state.bestSellers)
                      : _horizontalProductList(state.bestSellers),
                ],

                const SliverToBoxAdapter(child: SizedBox(height: 8)),

                // ── Featured ────────────────────────────
                if (state.isLoading)
                  SliverToBoxAdapter(child: ShimmerLoading.productGrid())
                else if (state.featured.isNotEmpty) ...[
                  _sectionHeader('FEATURED',
                      onSeeAll: () => context.push('/products')),
                  SliverToBoxAdapter(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1400),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: Responsive.horizontalPadding(context),
                          ),
                          child: GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: Responsive.productGridMaxExtent(context),
                              childAspectRatio: 0.62,
                              crossAxisSpacing: isDesktop ? 16 : 12,
                              mainAxisSpacing: isDesktop ? 16 : 12,
                            ),
                            itemCount: state.featured.length,
                            itemBuilder: (context, index) {
                              final product = state.featured[index];
                              return BlocBuilder<WishlistCubit, WishlistState>(
                                builder: (context, wishState) {
                                  return ProductCard(
                                    product: product,
                                    isInWishlist:
                                        wishState.wishlistIds.contains(product.id),
                                    onTap: () =>
                                        context.push('/product/${product.id}'),
                                    onWishlistTap: () => context
                                        .read<WishlistCubit>()
                                        .toggleWishlist(product.id),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ],

                const SliverToBoxAdapter(child: SizedBox(height: 32)),

                // ── Footer (desktop only) ──────────────
                if (isDesktop)
                  SliverToBoxAdapter(child: _buildDesktopFooter(context)),
              ],
            ),
          );
        },
      ),
    );
  }

  SliverToBoxAdapter _sectionHeader(String title, {VoidCallback? onSeeAll}) {
    return SliverToBoxAdapter(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1400),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              Responsive.horizontalPadding(context), 16,
              Responsive.horizontalPadding(context), 12,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: context.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                )),
                if (onSeeAll != null)
                  GestureDetector(
                    onTap: onSeeAll,
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Text(
                        'VIEW ALL',
                        style: context.textTheme.labelLarge?.copyWith(
                          color: context.isDarkMode ? Colors.white70 : const Color(0xFF1A1A1A),
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Mobile: Horizontal scrollable product list ──────────
  SliverToBoxAdapter _horizontalProductList(List<Product> products) {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 240,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: products.length,
          separatorBuilder: (_, _) => const SizedBox(width: 12),
          itemBuilder: (_, index) {
            final product = products[index];
            return SizedBox(
              width: 160,
              child: BlocBuilder<WishlistCubit, WishlistState>(
                builder: (context, wishState) {
                  return ProductCard(
                    product: product,
                    isInWishlist: wishState.wishlistIds.contains(product.id),
                    onTap: () => context.push('/product/${product.id}'),
                    onWishlistTap: () =>
                        context.read<WishlistCubit>().toggleWishlist(product.id),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  // ── Desktop: Full-width product grid for sections ───────
  SliverToBoxAdapter _desktopProductGrid(List<Product> products) {
    return SliverToBoxAdapter(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1400),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: Responsive.horizontalPadding(context),
            ),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: Responsive.productGridMaxExtent(context),
                childAspectRatio: 0.62,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: products.length > 5 ? 5 : products.length,
              itemBuilder: (_, index) {
                final product = products[index];
                return BlocBuilder<WishlistCubit, WishlistState>(
                  builder: (context, wishState) {
                    return ProductCard(
                      product: product,
                      isInWishlist: wishState.wishlistIds.contains(product.id),
                      onTap: () => context.push('/product/${product.id}'),
                      onWishlistTap: () =>
                          context.read<WishlistCubit>().toggleWishlist(product.id),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // ── Desktop Footer ──────────────────────────────────────
  Widget _buildDesktopFooter(BuildContext context) {
    return Container(
      color: context.isDarkMode ? const Color(0xFF0D0D0D) : const Color(0xFF1A1A1A),
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1400),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Brand
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppConstants.appName.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          AppConstants.appTagline,
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          AppConstants.contactAddress,
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 13,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Quick Links
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'SHOP',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...[
                          'All Products',
                          'New Arrivals',
                          'Best Sellers',
                          'Categories',
                        ].map((item) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Text(
                                item,
                                style: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontSize: 13,
                                ),
                              ),
                            )),
                      ],
                    ),
                  ),
                  // Support
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'SUPPORT',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...[
                          'My Orders',
                          'My Wishlist',
                          'Contact Us',
                          'Return Policy',
                        ].map((item) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Text(
                                item,
                                style: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontSize: 13,
                                ),
                              ),
                            )),
                      ],
                    ),
                  ),
                  // Contact
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'CONTACT',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Icon(Icons.phone, size: 14, color: Colors.grey.shade400),
                            const SizedBox(width: 8),
                            Text(
                              AppConstants.contactPhone,
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(Icons.email_outlined, size: 14, color: Colors.grey.shade400),
                            const SizedBox(width: 8),
                            Text(
                              AppConstants.adminEmail,
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Divider(color: Colors.grey.shade800),
              const SizedBox(height: 16),
              Text(
                '© 2025 ${AppConstants.appName}. All rights reserved.',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
