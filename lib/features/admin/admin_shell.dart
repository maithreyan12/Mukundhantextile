import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/utils/extensions.dart';

class AdminShell extends StatefulWidget {
  final Widget child;
  const AdminShell({super.key, required this.child});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _selectedIndex = 0;

  static const _navItems = [
    _NavItem(icon: Icons.dashboard_rounded, label: 'Dashboard', route: '/admin'),
    _NavItem(icon: Icons.inventory_2_rounded, label: 'Products', route: '/admin/products'),
    _NavItem(icon: Icons.category_rounded, label: 'Categories', route: '/admin/categories'),
    _NavItem(icon: Icons.receipt_long_rounded, label: 'Orders', route: '/admin/orders'),
    _NavItem(icon: Icons.people_rounded, label: 'Users', route: '/admin/users'),
    _NavItem(icon: Icons.local_offer_rounded, label: 'Coupons', route: '/admin/coupons'),
    _NavItem(icon: Icons.image_rounded, label: 'Banners', route: '/admin/banners'),
    _NavItem(icon: Icons.palette_rounded, label: 'Theme', route: '/admin/theme'),
  ];

  void _onNavTap(int index) {
    setState(() => _selectedIndex = index);
    context.go(_navItems[index].route);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Sync selected index with current route
    final location = GoRouterState.of(context).matchedLocation;
    for (int i = 0; i < _navItems.length; i++) {
      if (location == _navItems[i].route) {
        if (_selectedIndex != i) {
          setState(() => _selectedIndex = i);
        }
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = context.screenWidth > 800;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 1,
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'ios/logo.jpeg',
                width: 32,
                height: 32,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Admin Panel',
              style: context.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        leading: isWide
            ? null
            : Builder(
                builder: (ctx) => IconButton(
                  icon: const Icon(Icons.menu_rounded),
                  onPressed: () => Scaffold.of(ctx).openDrawer(),
                ),
              ),
        actions: [
          IconButton(
            icon: const Icon(Icons.storefront_rounded),
            tooltip: 'Go to Store',
            onPressed: () => context.go('/'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: isWide ? null : _buildDrawer(),
      body: Row(
        children: [
          if (isWide) _buildSideNav(),
          Expanded(child: widget.child),
        ],
      ),
    );
  }

  Widget _buildSideNav() {
    return Container(
      width: 230,
      decoration: BoxDecoration(
        color: context.isDarkMode
            ? Theme.of(context).colorScheme.surface
            : const Color(0xFFF5F7FA),
        border: Border(
          right: BorderSide(
            color: context.isDarkMode ? Colors.white10 : Colors.grey.shade200,
          ),
        ),
      ),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 12),
        itemCount: _navItems.length,
        itemBuilder: (_, i) => _buildNavTile(i),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      'ios/logo.jpeg',
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('Admin Panel', style: context.textTheme.titleMedium),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                itemCount: _navItems.length,
                itemBuilder: (_, i) => _buildNavTile(i, inDrawer: true),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavTile(int index, {bool inDrawer = false}) {
    final isSelected = _selectedIndex == index;
    final item = _navItems[index];
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: ListTile(
        selected: isSelected,
        selectedTileColor: primaryColor.withValues(alpha: 0.12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Icon(
          item.icon,
          color: isSelected ? primaryColor : null,
          size: 22,
        ),
        title: Text(
          item.label,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            fontSize: 14,
            color: isSelected ? primaryColor : null,
          ),
        ),
        onTap: () {
          if (inDrawer) Navigator.pop(context);
          _onNavTap(index);
        },
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final String route;

  const _NavItem({required this.icon, required this.label, required this.route});
}
