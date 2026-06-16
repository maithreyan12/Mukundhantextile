import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/utils/responsive_helper.dart';
import '../../../shared/widgets/product_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/cached_image.dart';
import '../../wishlist/bloc/wishlist_cubit.dart';
import '../../cart/bloc/cart_cubit.dart';
import '../bloc/product_list_cubit.dart';
import '../../home/bloc/home_cubit.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  final List<Map<String, String>> _recentSearches = [
    {'title': 'Silk Sarees', 'image': 'https://images.unsplash.com/photo-1610030469983-98e550d6193c?w=150'},
    {'title': 'Cotton Sarees', 'image': 'https://images.unsplash.com/photo-1583391733956-3750e0ff4e8b?w=150'},
    {'title': 'Dhotis', 'image': 'https://images.unsplash.com/photo-1607345366928-199ea26cfe3e?w=150'},
    {'title': 'Mens Shirts', 'image': 'https://images.unsplash.com/photo-1596755094514-f87e34085b2c?w=150'},
    {'title': 'Kids Pavadai', 'image': 'https://images.unsplash.com/photo-1518831959646-742c3a14ebf7?w=150'},
  ];

  final List<Map<String, String>> _recommendedStores = [
    {'title': 'Silk Collection', 'image': 'https://images.unsplash.com/photo-1610030469983-98e550d6193c?w=300'},
    {'title': 'Wedding Special', 'image': 'https://images.unsplash.com/photo-1596755094514-f87e34085b2c?w=300'},
    {'title': 'Kids Zone', 'image': 'https://images.unsplash.com/photo-1518831959646-742c3a14ebf7?w=300'},
  ];

  @override
  void initState() {
    super.initState();
    // Ensure home state is loaded for popular products
    context.read<HomeCubit>().loadHome();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.isNotEmpty) {
        context.read<ProductListCubit>().loadProducts(searchQuery: query);
      } else {
        setState(() {});
      }
    });
  }

  void _executeSearch(String query) {
    _searchController.text = query;
    context.read<ProductListCubit>().loadProducts(searchQuery: query);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isLargeScreen(context);
    final isQueryEmpty = _searchController.text.trim().isEmpty;

    return Scaffold(
      backgroundColor: context.isDarkMode ? const Color(0xFF0F0F1A) : Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: context.isDarkMode ? const Color(0xFF1E1E2A) : Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: context.isDarkMode ? Colors.white : Colors.black87),
          onPressed: () => context.pop(),
        ),
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: context.isDarkMode ? Colors.white10 : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(6),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Icon(Icons.search, color: Colors.grey.shade500, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  onChanged: _onSearchChanged,
                  style: const TextStyle(fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: 'Search for sarees, dhotis, ready...',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              if (_searchController.text.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    _searchController.clear();
                    setState(() {});
                  },
                  child: Icon(Icons.clear, color: Colors.grey.shade600, size: 20),
                ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.camera_alt_outlined, color: context.isDarkMode ? Colors.white70 : Colors.black87),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Row(
                    children: [
                      Icon(Icons.camera_alt_rounded, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('Visual Search'),
                    ],
                  ),
                  content: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.image_search, size: 64, color: Colors.grey),
                      SizedBox(height: 12),
                      Text(
                        'Take a photo of a fabric or upload an image to analyze and search for similar sarees/textiles.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _executeSearch('Silk Sarees');
                      },
                      child: const Text('Analyze & Search'),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: isQueryEmpty
          ? _buildRestingView(context)
          : BlocBuilder<ProductListCubit, ProductListState>(
              builder: (context, state) {
                if (state.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state.products.isEmpty) {
                  return const EmptyStateWidget(
                    icon: Icons.search_off,
                    title: 'No Results Found',
                    subtitle: 'Try searching with another term',
                  );
                }

                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1400),
                    child: GridView.builder(
                      padding: EdgeInsets.all(Responsive.horizontalPadding(context)),
                      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: Responsive.productGridMaxExtent(context),
                        childAspectRatio: 0.62,
                        crossAxisSpacing: isDesktop ? 16 : 12,
                        mainAxisSpacing: isDesktop ? 16 : 12,
                      ),
                      itemCount: state.products.length,
                      itemBuilder: (context, index) {
                        final product = state.products[index];
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
                );
              },
            ),
    );
  }

  Widget _buildRestingView(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 1. Recent Searches (Circular Thumbnails) ──────────────────
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Recent Searches',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _recentSearches.length,
              itemBuilder: (context, index) {
                final item = _recentSearches[index];
                return GestureDetector(
                  onTap: () => _executeSearch(item['title']!),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey.shade300, width: 1),
                          ),
                          child: ClipOval(
                            child: CachedImage(
                              imageUrl: item['image']!,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item['title']!,
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const Divider(height: 32),

          // ── 2. Recommended Stores For You ──────────────────────────────
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Recommended Stores For You',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 140,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _recommendedStores.length,
              itemBuilder: (context, index) {
                final store = _recommendedStores[index];
                return GestureDetector(
                  onTap: () => _executeSearch(store['title']!),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Container(
                      width: 120,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: context.isDarkMode ? Colors.white10 : Colors.grey.shade200),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CachedImage(
                              imageUrl: store['image']!,
                              fit: BoxFit.cover,
                            ),
                            Container(
                              color: Colors.black.withValues(alpha: 0.3),
                            ),
                            Center(
                              child: Text(
                                store['title']!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12,
                                  shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const Divider(height: 32),

          // ── 3. Popular Products ─────────────────────────────────────────
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Popular Products',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(height: 12),
          BlocBuilder<HomeCubit, HomeState>(
            builder: (context, homeState) {
              final products = homeState.featured.take(6).toList();
              if (products.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Loading popular products...'),
                );
              }

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 8,
                  childAspectRatio: 0.65,
                ),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  return GestureDetector(
                    onTap: () => context.push('/product/${product.id}'),
                    child: Container(
                      decoration: BoxDecoration(
                        color: context.isDarkMode ? const Color(0xFF1E1E2A) : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: context.isDarkMode ? Colors.white10 : Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                              child: CachedImage(
                                imageUrl: product.images.isNotEmpty ? product.images[0] : '',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(6),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
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
              );
            },
          ),
        ],
      ),
    );
  }
}
