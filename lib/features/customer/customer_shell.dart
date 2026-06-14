import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../core/utils/responsive_helper.dart';
import '../../core/utils/extensions.dart';
import '../../core/constants.dart';
import '../cart/bloc/cart_cubit.dart';
import '../cart/presentation/cart_screen.dart';
import '../home/presentation/home_screen.dart';
import '../wishlist/presentation/wishlist_screen.dart';
import '../auth/presentation/profile_screen.dart';
import '../product/presentation/product_list_screen.dart';

class CustomerShell extends StatefulWidget {
  const CustomerShell({super.key});

  @override
  State<CustomerShell> createState() => _CustomerShellState();
}

class _CustomerShellState extends State<CustomerShell> {
  int _currentIndex = 0;

  final _pages = const [
    HomeScreen(),
    ProductListScreen(),
    CartScreen(),
    WishlistScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isLargeScreen(context);

    return Scaffold(
      appBar: isDesktop ? _buildDesktopAppBar(context) : null,
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: isDesktop ? null : _buildMobileBottomNav(context),
    );
  }

  // ── Desktop Top Navigation Bar (Flipkart-style) ─────────
  PreferredSizeWidget _buildDesktopAppBar(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(64),
      child: Container(
        decoration: BoxDecoration(
          color: context.isDarkMode
              ? Theme.of(context).colorScheme.surface
              : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1400),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    // ── Logo & Brand ──
                    GestureDetector(
                      onTap: () => setState(() => _currentIndex = 0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.asset(
                              'ios/logo.jpeg',
                              width: 36,
                              height: 36,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            AppConstants.appName.toUpperCase(),
                            style: context.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2.0,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 32),

                    // ── Search Bar (expanded center) ──
                    Expanded(
                      child: GestureDetector(
                        onTap: () => context.push('/search'),
                        child: Container(
                          height: 42,
                          constraints: const BoxConstraints(maxWidth: 600),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: context.isDarkMode
                                ? Colors.white.withValues(alpha: 0.06)
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: context.isDarkMode
                                  ? Colors.white12
                                  : Colors.grey.shade300,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.search,
                                  color: Colors.grey.shade500, size: 20),
                              const SizedBox(width: 10),
                              Text(
                                'Search for products, brands and more...',
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 24),

                    // ── Nav Links ──
                    _DesktopNavItem(
                      icon: Icons.home_outlined,
                      activeIcon: Icons.home_rounded,
                      label: 'Home',
                      isActive: _currentIndex == 0,
                      onTap: () => setState(() => _currentIndex = 0),
                    ),
                    _DesktopNavItem(
                      icon: Icons.grid_view_outlined,
                      activeIcon: Icons.grid_view_rounded,
                      label: 'Browse',
                      isActive: _currentIndex == 1,
                      onTap: () => setState(() => _currentIndex = 1),
                    ),
                    BlocBuilder<CartCubit, CartState>(
                      builder: (context, cartState) {
                        return _DesktopNavItem(
                          icon: Icons.shopping_cart_outlined,
                          activeIcon: Icons.shopping_cart_rounded,
                          label: 'Cart',
                          isActive: _currentIndex == 2,
                          badgeCount: cartState.itemCount,
                          onTap: () => setState(() => _currentIndex = 2),
                        );
                      },
                    ),
                    _DesktopNavItem(
                      icon: Icons.favorite_border,
                      activeIcon: Icons.favorite_rounded,
                      label: 'Wishlist',
                      isActive: _currentIndex == 3,
                      onTap: () => setState(() => _currentIndex = 3),
                    ),
                    _DesktopNavItem(
                      icon: Icons.person_outline,
                      activeIcon: Icons.person_rounded,
                      label: 'Profile',
                      isActive: _currentIndex == 4,
                      onTap: () => setState(() => _currentIndex = 4),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Mobile Bottom Navigation Bar ────────────────────────
  Widget _buildMobileBottomNav(BuildContext context) {
    return BlocBuilder<CartCubit, CartState>(
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
    );
  }
}

// ── Desktop Nav Item Widget ─────────────────────────────
class _DesktopNavItem extends StatefulWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final int badgeCount;
  final VoidCallback onTap;

  const _DesktopNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    this.badgeCount = 0,
    required this.onTap,
  });

  @override
  State<_DesktopNavItem> createState() => _DesktopNavItemState();
}

class _DesktopNavItemState extends State<_DesktopNavItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final isActive = widget.isActive;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: isActive
                ? primaryColor.withValues(alpha: 0.1)
                : _isHovered
                    ? (context.isDarkMode
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.grey.shade100)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Badge(
                isLabelVisible: widget.badgeCount > 0,
                label: Text(
                  '${widget.badgeCount}',
                  style: const TextStyle(fontSize: 10),
                ),
                child: Icon(
                  isActive ? widget.activeIcon : widget.icon,
                  size: 20,
                  color: isActive
                      ? primaryColor
                      : (context.isDarkMode ? Colors.white70 : Colors.black54),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive
                      ? primaryColor
                      : (context.isDarkMode ? Colors.white70 : Colors.black54),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
