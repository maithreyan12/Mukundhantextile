import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../../../core/utils/extensions.dart';
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
                // ── App Bar ─────────────────────────────
                SliverAppBar(
                  title: Text(
                    AppConstants.appName.toUpperCase(),
                    style: context.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3.0,
                      color: Colors.white,
                    ),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.notifications_none_rounded),
                      onPressed: () => context.push('/notifications'),
                    ),
                  ],
                ),

                // ── Search Bar ──────────────────────────
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
                    child: CarouselSlider.builder(
                      itemCount: state.banners.length,
                      options: CarouselOptions(
                        height: 400,
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

                const SliverToBoxAdapter(child: SizedBox(height: 32)),

                // ── Categories ──────────────────────────
                if (state.isLoading)
                  SliverToBoxAdapter(
                      child: ShimmerLoading.horizontalList(height: 90))
                else if (state.categories.isNotEmpty) ...[
                  _sectionHeader('CATEGORIES', onSeeAll: () {}),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 100,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: state.categories.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 16),
                        itemBuilder: (_, i) {
                          final cat = state.categories[i];
                          return GestureDetector(
                            onTap: () => context
                                .push('/products?category=${cat.id}'),
                            child: Column(
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
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
                                            width: 60,
                                            height: 60,
                                          ),
                                        )
                                      : const Icon(Icons.category_outlined,
                                          color: Color(0xFF2979FF)),
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: 70,
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
                ],

                const SliverToBoxAdapter(child: SizedBox(height: 8)),

                // ── New Arrivals ────────────────────────
                if (state.isLoading)
                  SliverToBoxAdapter(
                      child: ShimmerLoading.horizontalList(height: 220))
                else if (state.newArrivals.isNotEmpty) ...[
                  _sectionHeader('NEW DROPS',
                      onSeeAll: () => context.push('/products?sort=new')),
                  _horizontalProductList(state.newArrivals),
                ],

                const SliverToBoxAdapter(child: SizedBox(height: 8)),

                // ── Best Sellers ────────────────────────
                if (state.isLoading)
                  SliverToBoxAdapter(
                      child: ShimmerLoading.horizontalList(height: 220))
                else if (state.bestSellers.isNotEmpty) ...[
                  _sectionHeader('TRENDING',
                      onSeeAll: () => context.push('/products?sort=popular')),
                  _horizontalProductList(state.bestSellers),
                ],

                const SliverToBoxAdapter(child: SizedBox(height: 8)),

                // ── Featured ────────────────────────────
                if (state.isLoading)
                  SliverToBoxAdapter(child: ShimmerLoading.productGrid())
                else if (state.featured.isNotEmpty) ...[
                  _sectionHeader('FEATURED',
                      onSeeAll: () => context.push('/products')),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverGrid(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
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
                        childCount: state.featured.length,
                      ),
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 220,
                        childAspectRatio: 0.62,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                    ),
                  ),
                ],

                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ),
          );
        },
      ),
    );
  }

  SliverToBoxAdapter _sectionHeader(String title, {VoidCallback? onSeeAll}) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
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
                child: Text(
                  'VIEW ALL',
                  style: context.textTheme.labelLarge?.copyWith(
                    color: const Color(0xFFEAEAEA),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

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
}
