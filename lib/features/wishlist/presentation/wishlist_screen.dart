import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/utils/responsive_helper.dart';
import '../../../shared/widgets/product_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/shimmer_loading.dart';
import '../bloc/wishlist_cubit.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  @override
  void initState() {
    super.initState();
    context.read<WishlistCubit>().loadWishlist();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isLargeScreen(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('WISHLIST', style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, letterSpacing: 1.5)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
      ),
      body: BlocBuilder<WishlistCubit, WishlistState>(
        builder: (context, state) {
          if (state.isLoading) {
            return ShimmerLoading.productGrid();
          }
          if (state.products.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.favorite_border,
              title: 'Your Wishlist is Empty',
              subtitle: 'Save items you love to your wishlist',
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
                  return ProductCard(
                    product: product,
                    isInWishlist: true,
                    onTap: () => context.push('/product/${product.id}'),
                    onWishlistTap: () =>
                        context.read<WishlistCubit>().toggleWishlist(product.id),
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
