import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/utils/responsive_helper.dart';
import '../../../shared/widgets/product_card.dart';
import '../../../shared/widgets/shimmer_loading.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../wishlist/bloc/wishlist_cubit.dart';
import '../bloc/product_list_cubit.dart';

class ProductListScreen extends StatefulWidget {
  final String? categoryId;
  final String? sort;

  const ProductListScreen({super.key, this.categoryId, this.sort});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<ProductListCubit>().loadProducts(
          categoryId: widget.categoryId,
          sortBy: widget.sort == 'new'
              ? 'created_at'
              : widget.sort == 'popular'
                  ? 'review_count'
                  : 'created_at',
        );
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<ProductListCubit>().loadMore();
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

    return Scaffold(
      appBar: isDesktop
          ? null
          : AppBar(
              title: Text('PRODUCTS', style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, letterSpacing: 1.5)),
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
              onRetry: () => context.read<ProductListCubit>().loadProducts(),
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
                itemCount: state.products.length + (state.isLoadingMore ? 2 : 0),
                itemBuilder: (context, index) {
                  if (index >= state.products.length) {
                    return const ShimmerLoading(height: 250);
                  }
                  final product = state.products[index];
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
          );
        },
      ),
    );
  }
}
