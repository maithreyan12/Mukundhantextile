import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/utils/responsive_helper.dart';
import '../../../core/constants.dart';
import '../../../data/models/product.dart';
import '../../../data/models/banner_model.dart';
import '../../../shared/widgets/cached_image.dart';
import '../../../shared/widgets/product_card.dart';
import '../../../shared/widgets/shimmer_loading.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../wishlist/bloc/wishlist_cubit.dart';
import '../../cart/bloc/cart_cubit.dart';
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
    _checkAppUpdate();
  }

  Future<void> _checkAppUpdate() async {
    try {
      final response = await Supabase.instance.client
          .from('app_settings')
          .select()
          .eq('key', 'app_version_info')
          .maybeSingle();

      if (response != null && mounted) {
        final value = response['value'] as Map<String, dynamic>;
        final serverVersion = value['version'] as String? ?? '1.0.0';
        final apkUrl = value['apk_url'] as String? ?? '';
        final releaseNotes = value['release_notes'] as String? ?? 'New features and updates.';

        if (_isNewerVersion(AppConstants.appVersion, serverVersion) && apkUrl.isNotEmpty) {
          _showUpdateDialog(serverVersion, apkUrl, releaseNotes);
        }
      }
    } catch (e) {
      debugPrint('Error checking for updates: $e');
    }
  }

  bool _isNewerVersion(String current, String latest) {
    try {
      final currParts = current.split('.').map(int.parse).toList();
      final lateParts = latest.split('.').map(int.parse).toList();
      for (var i = 0; i < 3; i++) {
        final c = i < currParts.length ? currParts[i] : 0;
        final l = i < lateParts.length ? lateParts[i] : 0;
        if (l > c) return true;
        if (c > l) return false;
      }
    } catch (_) {}
    return false;
  }

  void _showUpdateDialog(String version, String url, String notes) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.system_update_alt_rounded, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            const Text('Update Available!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'A new version ($version) of Mugundhan Tex & Readymades is available.',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text('Release Notes:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            Text(notes, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Later', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final uri = Uri.parse(url);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            style: ElevatedButton.styleFrom(
               backgroundColor: Theme.of(context).colorScheme.primary,
               foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
            child: const Text('Update Now'),
          ),
        ],
      ),
    );
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
                    title: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.asset(
                            'ios/logo.jpeg',
                            width: 30,
                            height: 30,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'MUGUNDHAN TEX & READYMADES',
                              style: context.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                                fontSize: 16,
                                color: context.isDarkMode ? Colors.white : const Color(0xFF1A1A1A),
                              ),
                            ),
                          ),
                        ),
                      ],
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
                                : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: context.isDarkMode ? Colors.white12 : Colors.grey.shade300,
                              width: 1,
                            ),
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
                else
                  SliverToBoxAdapter(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1400),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: isDesktop ? 24 : 12,
                            vertical: isDesktop ? 16 : 8,
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(isDesktop ? 18 : 14),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(isDesktop ? 18 : 14),
                              child: AspectRatio(
                                aspectRatio: isDesktop ? 2.8 : 16 / 9,
                                child: state.banners.isNotEmpty
                                    ? _buildBannerCarousel(context, state.banners, isDesktop)
                                    : _buildDefaultHeroBanners(context, isDesktop),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                // ── Promo Strip ─────────────────────────
                if (!state.isLoading)
                  SliverToBoxAdapter(child: _buildPromoStrip(context, isDesktop)),

                const SliverToBoxAdapter(child: SizedBox(height: 24)),

                // ── Categories ──────────────────────────
                if (state.isLoading)
                  SliverToBoxAdapter(
                      child: ShimmerLoading.horizontalList(height: 90))
                else if (state.categories.isNotEmpty) ...[
                  _sectionHeader('SHOP BY CATEGORY', onSeeAll: () {}),
                  SliverToBoxAdapter(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1400),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: Responsive.horizontalPadding(context),
                          ),
                          child: isDesktop
                              ? GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: state.categories.length > 6 ? 6 : state.categories.length,
                                    childAspectRatio: 1.0,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
                                  ),
                                  itemCount: state.categories.length,
                                  itemBuilder: (_, i) => _buildCategoryCard(state.categories[i], i, isDesktop),
                                )
                              : SizedBox(
                                  height: 120,
                                  child: ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: state.categories.length,
                                    separatorBuilder: (_, _) => const SizedBox(width: 14),
                                    itemBuilder: (_, i) => SizedBox(
                                      width: 100,
                                      child: _buildCategoryCard(state.categories[i], i, isDesktop),
                                    ),
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                ],

                const SliverToBoxAdapter(child: SizedBox(height: 24)),

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

                const SliverToBoxAdapter(child: SizedBox(height: 16)),

                // ── Mid Banner ──────────────────────────
                if (!state.isLoading)
                  SliverToBoxAdapter(child: _buildMidBanner(context, isDesktop)),

                const SliverToBoxAdapter(child: SizedBox(height: 16)),

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

                const SliverToBoxAdapter(child: SizedBox(height: 16)),

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
                                    onBuyNow: () {
                                      context.read<CartCubit>().addToCart(productId: product.id);
                                      context.showSuccessSnackBar('Added to cart!');
                                      context.go('/cart');
                                    },
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
              Responsive.horizontalPadding(context), 20,
              Responsive.horizontalPadding(context), 14,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 4,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(title, style: context.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                      fontSize: Responsive.isLargeScreen(context) ? 22 : 17,
                    )),
                  ],
                ),
                if (onSeeAll != null)
                  GestureDetector(
                    onTap: onSeeAll,
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: context.isDarkMode ? Colors.white24 : Colors.grey.shade300,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'VIEW ALL',
                              style: context.textTheme.labelSmall?.copyWith(
                                color: context.isDarkMode ? Colors.white70 : const Color(0xFF1A1A1A),
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 10,
                              color: context.isDarkMode ? Colors.white70 : const Color(0xFF1A1A1A),
                            ),
                          ],
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
                    onBuyNow: () {
                      context.read<CartCubit>().addToCart(productId: product.id);
                      context.showSuccessSnackBar('Added to cart!');
                      context.go('/cart');
                    },
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
                      onBuyNow: () {
                        context.read<CartCubit>().addToCart(productId: product.id);
                        context.showSuccessSnackBar('Added to cart!');
                        context.go('/cart');
                      },
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

  // ── Premium Banner Carousel ────────────────────────────
  Widget _buildBannerCarousel(BuildContext context, List<BannerModel> banners, bool isDesktop) {
    return StatefulBuilder(
      builder: (context, setState) {
        final pageController = PageController();
        int currentPage = 0;

        // Auto-play timer
        Future.delayed(Duration.zero, () {
          Future.doWhile(() async {
            await Future.delayed(const Duration(seconds: 5));
            if (!context.mounted) return false;
            if (pageController.hasClients) {
              final nextPage = (pageController.page?.round() ?? 0) + 1;
              await pageController.animateToPage(
                nextPage % banners.length,
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
              );
            }
            return true;
          });
        });

        return Stack(
          fit: StackFit.expand,
          children: [
            // Page View
            PageView.builder(
              controller: pageController,
              itemCount: banners.length,
              onPageChanged: (index) => setState(() => currentPage = index),
              itemBuilder: (_, index) {
                final banner = banners[index];
                return GestureDetector(
                  onTap: () {
                    if (banner.targetType == 'product' && banner.targetId != null) {
                      context.push('/product/${banner.targetId}');
                    } else if (banner.targetType == 'category' && banner.targetId != null) {
                      context.push('/products?category=${banner.targetId}');
                    }
                  },
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Banner image — fits perfectly
                      CachedImage(
                        imageUrl: banner.imageUrl,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholderIcon: Icons.camera_alt_outlined,
                      ),
                      // Bottom gradient for text readability
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        height: isDesktop ? 140 : 90,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.7),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Banner text — stylish bottom position
                      if (banner.title != null && banner.title!.isNotEmpty)
                        Positioned(
                          bottom: isDesktop ? 40 : 24,
                          left: isDesktop ? 48 : 16,
                          right: isDesktop ? 200 : 60,
                          child: Text(
                            banner.title!.replaceAll('\\n', '\n'),
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: isDesktop ? 32 : 18,
                              height: 1.2,
                              letterSpacing: 0.5,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
            // Dot indicators
            if (banners.length > 1)
              Positioned(
                bottom: 8,
                right: 12,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    banners.length,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: currentPage == i ? 18 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: currentPage == i
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  // ── Default Hero Banners (when no admin banners) ────────
  Widget _buildDefaultHeroBanners(BuildContext context, bool isDesktop) {
    final bannerData = [
      {
        'gradient': const [Color(0xFF1A1A2E), Color(0xFF16213E)],
        'accent': const Color(0xFFE94560),
        'title': 'MUGUNDHAN\nTEX & READYMADES',
        'subtitle': 'All Kinds of Clothes Under One Roof',
        'icon': Icons.storefront_rounded,
      },
      {
        'gradient': const [Color(0xFF0F3460), Color(0xFF533483)],
        'accent': const Color(0xFFE94560),
        'title': 'PREMIUM\nSILK SAREES',
        'subtitle': 'Kanchipuram · Banarasi · Mysore Silk',
        'icon': Icons.diamond_rounded,
      },
      {
        'gradient': const [Color(0xFF2C3333), Color(0xFF395B64)],
        'accent': const Color(0xFFF0C38E),
        'title': 'READYMADE\nCOLLECTION',
        'subtitle': 'Men · Women · Kids — Latest Styles',
        'icon': Icons.checkroom_rounded,
      },
    ];

    return CarouselSlider.builder(
      itemCount: bannerData.length,
      options: CarouselOptions(
        height: isDesktop ? 400 : 280,
        autoPlay: true,
        enlargeCenterPage: false,
        viewportFraction: 1.0,
        autoPlayInterval: const Duration(seconds: 5),
      ),
      itemBuilder: (_, index, _) {
        final data = bannerData[index];
        final gradientColors = data['gradient'] as List<Color>;
        final accent = data['accent'] as Color;

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors,
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Decorative pattern overlay
              Positioned(
                right: isDesktop ? -60 : -40,
                top: isDesktop ? -40 : -20,
                child: Container(
                  width: isDesktop ? 500 : 300,
                  height: isDesktop ? 500 : 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.03),
                  ),
                ),
              ),
              Positioned(
                right: isDesktop ? 60 : 20,
                bottom: isDesktop ? -80 : -50,
                child: Container(
                  width: isDesktop ? 350 : 200,
                  height: isDesktop ? 350 : 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.withValues(alpha: 0.08),
                  ),
                ),
              ),
              // Icon on right side
              if (isDesktop)
                Positioned(
                  right: 100,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(
                          color: accent.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        data['icon'] as IconData,
                        size: 80,
                        color: accent.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ),
              // Text content
              Positioned(
                left: isDesktop ? 64 : 24,
                bottom: isDesktop ? 64 : 32,
                right: isDesktop ? 350 : 24,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: accent.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        'VELLORE',
                        style: TextStyle(
                          color: accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      data['title'] as String,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isDesktop ? 44 : 28,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      data['subtitle'] as String,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: isDesktop ? 18 : 14,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isDesktop ? 28 : 20,
                        vertical: isDesktop ? 14 : 10,
                      ),
                      decoration: BoxDecoration(
                        color: accent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'SHOP NOW',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isDesktop ? 14 : 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Promotional Features Strip ──────────────────────────
  Widget _buildPromoStrip(BuildContext context, bool isDesktop) {
    final features = [
      {'icon': Icons.local_shipping_outlined, 'label': 'Free Delivery', 'sub': 'On orders above ₹999'},
      {'icon': Icons.verified_outlined, 'label': '100% Genuine', 'sub': 'Quality fabrics'},
      {'icon': Icons.autorenew_rounded, 'label': 'Easy Returns', 'sub': '7-day return policy'},
      {'icon': Icons.support_agent_rounded, 'label': '24/7 Support', 'sub': 'Call: ${AppConstants.contactPhone}'},
    ];

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1400),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: Responsive.horizontalPadding(context),
            vertical: 8,
          ),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 32 : 16,
              vertical: isDesktop ? 20 : 16,
            ),
            decoration: BoxDecoration(
              color: context.isDarkMode
                  ? Colors.white.withValues(alpha: 0.04)
                  : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: context.isDarkMode ? Colors.white10 : Colors.grey.shade200,
              ),
              boxShadow: context.isDarkMode
                  ? []
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 12,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: isDesktop
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: features.map((f) => _promoFeatureItem(
                      f['icon'] as IconData,
                      f['label'] as String,
                      f['sub'] as String,
                      isDesktop,
                    )).toList(),
                  )
                : Wrap(
                    alignment: WrapAlignment.spaceAround,
                    runSpacing: 16,
                    children: features.map((f) => SizedBox(
                      width: MediaQuery.of(context).size.width / 2 - 40,
                      child: _promoFeatureItem(
                        f['icon'] as IconData,
                        f['label'] as String,
                        f['sub'] as String,
                        isDesktop,
                      ),
                    )).toList(),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _promoFeatureItem(IconData icon, String label, String sub, bool isDesktop) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: isDesktop ? 44 : 36,
          height: isDesktop ? 44 : 36,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: isDesktop ? 22 : 18,
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: isDesktop ? 14 : 12,
                color: context.isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            Text(
              sub,
              style: TextStyle(
                fontSize: isDesktop ? 12 : 10,
                color: context.isDarkMode ? Colors.white54 : Colors.black45,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Premium Category Card ──────────────────────────────
  Widget _buildCategoryCard(dynamic cat, int index, bool isDesktop) {
    // Gradient colors for different categories
    final gradients = [
      [const Color(0xFF667EEA), const Color(0xFF764BA2)],
      [const Color(0xFFF093FB), const Color(0xFFF5576C)],
      [const Color(0xFF4FACFE), const Color(0xFF00F2FE)],
      [const Color(0xFF43E97B), const Color(0xFF38F9D7)],
      [const Color(0xFFF6D365), const Color(0xFFFDA085)],
      [const Color(0xFFA18CD1), const Color(0xFFFBC2EB)],
      [const Color(0xFF89F7FE), const Color(0xFF66A6FF)],
      [const Color(0xFFFCCB90), const Color(0xFFD57EEB)],
    ];

    // Auto-match icon based on category name
    IconData categoryIcon = Icons.category_rounded;
    final name = cat.name.toString().toLowerCase();
    if (name.contains('men') && !name.contains('women')) {
      categoryIcon = Icons.man_rounded;
    } else if (name.contains('women') || name.contains('ladies') || name.contains('girl')) {
      categoryIcon = Icons.woman_rounded;
    } else if (name.contains('kid') || name.contains('child') || name.contains('baby')) {
      categoryIcon = Icons.child_care_rounded;
    } else if (name.contains('saree') || name.contains('sari')) {
      categoryIcon = Icons.dry_cleaning_rounded;
    } else if (name.contains('shirt') || name.contains('top')) {
      categoryIcon = Icons.checkroom_rounded;
    } else if (name.contains('pant') || name.contains('bottom') || name.contains('trouser')) {
      categoryIcon = Icons.straighten_rounded;
    } else if (name.contains('cotton')) {
      categoryIcon = Icons.eco_rounded;
    } else if (name.contains('silk')) {
      categoryIcon = Icons.diamond_rounded;
    } else if (name.contains('access') || name.contains('jewel')) {
      categoryIcon = Icons.watch_rounded;
    } else if (name.contains('foot') || name.contains('shoe') || name.contains('chapp')) {
      categoryIcon = Icons.ice_skating_rounded;
    }

    final colors = gradients[index % gradients.length];

    return GestureDetector(
      onTap: () => context.push('/products?category=${cat.id}'),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colors[0].withValues(alpha: context.isDarkMode ? 0.3 : 0.15),
                colors[1].withValues(alpha: context.isDarkMode ? 0.2 : 0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colors[0].withValues(alpha: context.isDarkMode ? 0.3 : 0.2),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Category image or gradient icon
              cat.imageUrl != null
                  ? Container(
                      width: isDesktop ? 56 : 48,
                      height: isDesktop ? 56 : 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: colors[0].withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedImage(
                          imageUrl: cat.imageUrl,
                          width: isDesktop ? 56 : 48,
                          height: isDesktop ? 56 : 48,
                        ),
                      ),
                    )
                  : Container(
                      width: isDesktop ? 56 : 48,
                      height: isDesktop ? 56 : 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: colors,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: colors[0].withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(
                        categoryIcon,
                        color: Colors.white,
                        size: isDesktop ? 26 : 22,
                      ),
                    ),
              SizedBox(height: isDesktop ? 12 : 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  cat.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: isDesktop ? 13 : 11,
                    color: context.isDarkMode ? Colors.white : Colors.black87,
                    letterSpacing: 0.3,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Mid-page Promotional Banner ─────────────────────────
  Widget _buildMidBanner(BuildContext context, bool isDesktop) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1400),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: Responsive.horizontalPadding(context),
          ),
          child: Container(
            height: isDesktop ? 200 : 140,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0F3460), Color(0xFF533483)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Stack(
              children: [
                // Decorative circles
                Positioned(
                  right: isDesktop ? -30 : -20,
                  top: isDesktop ? -50 : -30,
                  child: Container(
                    width: isDesktop ? 200 : 120,
                    height: isDesktop ? 200 : 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                ),
                Positioned(
                  right: isDesktop ? 80 : 40,
                  bottom: isDesktop ? -40 : -20,
                  child: Container(
                    width: isDesktop ? 160 : 100,
                    height: isDesktop ? 160 : 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFE94560).withValues(alpha: 0.1),
                    ),
                  ),
                ),
                // Text content
                Padding(
                  padding: EdgeInsets.all(isDesktop ? 40 : 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE94560).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'SPECIAL OFFER',
                                style: TextStyle(
                                  color: const Color(0xFFE94560),
                                  fontSize: isDesktop ? 12 : 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 2,
                                ),
                              ),
                            ),
                            SizedBox(height: isDesktop ? 12 : 8),
                            Text(
                              'Festival Collection Available',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isDesktop ? 28 : 18,
                                fontWeight: FontWeight.w900,
                                height: 1.2,
                              ),
                            ),
                            SizedBox(height: isDesktop ? 8 : 4),
                            Text(
                              'Exclusive silk sarees & readymade outfits for every occasion',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: isDesktop ? 15 : 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isDesktop) ...[
                        const SizedBox(width: 40),
                        GestureDetector(
                          onTap: () => context.push('/products'),
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE94560),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'EXPLORE NOW',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                  letterSpacing: 2,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '© 2026 ${AppConstants.appName}. All rights reserved.',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 14, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        'Proudly serving from Vellore, Tamil Nadu',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
