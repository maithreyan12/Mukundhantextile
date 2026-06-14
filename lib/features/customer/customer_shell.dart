import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cart/bloc/cart_cubit.dart';
import '../cart/presentation/cart_screen.dart';
import '../home/presentation/home_screen.dart';
import '../wishlist/presentation/wishlist_screen.dart';
import '../auth/presentation/profile_screen.dart';
import '../product/presentation/product_list_screen.dart';
import '../../../shared/widgets/responsive_wrapper.dart';

class CustomerShell extends StatefulWidget {
  const CustomerShell({super.key});

  @override
  State<CustomerShell> createState() => _CustomerShellState();
}

class _CustomerShellState extends State<CustomerShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ResponsiveWrapper(
        maxWidth: 1200,
        child: IndexedStack(
          index: _currentIndex,
          children: const [
            HomeScreen(),
            ProductListScreen(),
            CartScreen(),
            WishlistScreen(),
            ProfileScreen(),
          ],
        ),
      ),
      bottomNavigationBar: BlocBuilder<CartCubit, CartState>(
        builder: (context, cartState) {
          return BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() => _currentIndex = index);
            },
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home_rounded),
                label: 'HOME',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.grid_view_outlined),
                activeIcon: Icon(Icons.grid_view_rounded),
                label: 'BROWSE',
              ),
              BottomNavigationBarItem(
                icon: Badge(
                  isLabelVisible: cartState.itemCount > 0,
                  label: Text('${cartState.itemCount}'),
                  child: const Icon(Icons.shopping_cart_outlined),
                ),
                activeIcon: Badge(
                  isLabelVisible: cartState.itemCount > 0,
                  label: Text('${cartState.itemCount}'),
                  child: const Icon(Icons.shopping_cart_rounded),
                ),
                label: 'CART',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.favorite_border),
                activeIcon: Icon(Icons.favorite_rounded),
                label: 'WISHLIST',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person_rounded),
                label: 'PROFILE',
              ),
            ],
          );
        },
      ),
    );
  }
}

