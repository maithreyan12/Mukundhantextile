import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/bloc/auth_cubit.dart';
import '../features/auth/bloc/auth_state.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/signup_screen.dart';
import '../features/auth/presentation/forgot_password_screen.dart';
import '../features/auth/presentation/profile_screen.dart';
import '../features/auth/presentation/address_form_screen.dart';
import '../features/customer/customer_shell.dart';
import '../features/product/presentation/product_list_screen.dart';
import '../features/product/presentation/product_detail_screen.dart';
import '../features/product/presentation/search_screen.dart';
import '../features/cart/presentation/cart_screen.dart';
import '../features/cart/presentation/checkout_screen.dart';
import '../features/cart/presentation/order_success_screen.dart';
import '../features/orders/presentation/orders_screen.dart';
import '../features/orders/presentation/order_detail_screen.dart';
import '../features/wishlist/presentation/wishlist_screen.dart';
import '../features/notifications/presentation/notifications_screen.dart';
import '../features/admin/admin_shell.dart';
import '../features/admin/dashboard/admin_dashboard_screen.dart';
import '../features/admin/products/admin_products_screen.dart';
import '../features/admin/products/admin_product_form_screen.dart';
import '../features/admin/categories/admin_categories_screen.dart';
import '../features/admin/orders/admin_orders_screen.dart';
import '../features/admin/users/admin_users_screen.dart';
import '../features/admin/coupons/admin_coupons_screen.dart';
import '../features/admin/banners/admin_banners_screen.dart';
import '../features/admin/theme/theme_settings_screen.dart';
import '../features/admin/browse_settings/admin_browse_settings_screen.dart';


class AppRouter {
  final AuthCubit authCubit;

  AppRouter({required this.authCubit});

  late final GoRouter router = GoRouter(
    initialLocation: '/',
    refreshListenable: GoRouterRefreshStream(authCubit.stream),
    redirect: (context, state) {
      final authState = authCubit.state;
      final isAuth = authState is AuthAuthenticated;
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/signup' ||
          state.matchedLocation == '/forgot-password';

      debugPrint('🧭 Router redirect: state=$authState, isAuth=$isAuth, '
          'location=${state.matchedLocation}, isAuthRoute=$isAuthRoute');

      if (!isAuth && !isAuthRoute) return '/login';
      if (isAuth && isAuthRoute) return '/';
      return null;
    },
    routes: [
      // Auth Routes
      GoRoute(
        path: '/login',
        builder: (_, _) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (_, _) => const SignupScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (_, _) => const ForgotPasswordScreen(),
      ),

      // Customer Shell
      GoRoute(
        path: '/',
        builder: (_, _) => const CustomerShell(),
      ),

      // Product Routes
      GoRoute(
        path: '/products',
        builder: (_, state) => ProductListScreen(
          categoryId: state.uri.queryParameters['category'],
          sort: state.uri.queryParameters['sort'],
          maxPrice: state.uri.queryParameters['maxPrice'] != null
              ? double.tryParse(state.uri.queryParameters['maxPrice']!)
              : null,
        ),
      ),
      GoRoute(
        path: '/product/:id',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: ProductDetailScreen(productId: state.pathParameters['id']!),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.05, 0.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: child,
              ),
            );
          },
        ),
      ),
      GoRoute(
        path: '/search',
        builder: (_, _) => const SearchScreen(),
      ),

      // Cart & Checkout
      GoRoute(
        path: '/cart',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const CartScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.0, 0.05),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: child,
              ),
            );
          },
        ),
      ),
      GoRoute(
        path: '/checkout',
        builder: (_, _) => const CheckoutScreen(),
      ),
      GoRoute(
        path: '/order-success',
        builder: (_, _) => const OrderSuccessScreen(),
      ),

      // Orders
      GoRoute(
        path: '/orders',
        builder: (_, _) => const OrdersScreen(),
      ),
      GoRoute(
        path: '/order/:id',
        builder: (_, state) => OrderDetailScreen(
          orderId: state.pathParameters['id']!,
        ),
      ),

      // Wishlist
      GoRoute(
        path: '/wishlist',
        builder: (_, _) => const WishlistScreen(),
      ),

      // Profile & Address
      GoRoute(
        path: '/profile',
        builder: (_, _) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/address-form',
        builder: (_, _) => const AddressFormScreen(),
      ),

      // Notifications
      GoRoute(
        path: '/notifications',
        builder: (_, _) => const NotificationsScreen(),
      ),

      // Admin Routes — wrapped in AdminShell for sidebar navigation
      ShellRoute(
        builder: (_, _, child) => AdminShell(child: child),
        routes: [
          GoRoute(
            path: '/admin',
            builder: (_, _) => const AdminDashboardScreen(),
          ),
          GoRoute(
            path: '/admin/products',
            builder: (_, _) => const AdminProductsScreen(),
          ),
          GoRoute(
            path: '/admin/products/new',
            builder: (_, _) => const AdminProductFormScreen(),
          ),
          GoRoute(
            path: '/admin/products/:id',
            builder: (_, state) => AdminProductFormScreen(
              productId: state.pathParameters['id'],
            ),
          ),
          GoRoute(
            path: '/admin/categories',
            builder: (_, _) => const AdminCategoriesScreen(),
          ),
          GoRoute(
            path: '/admin/orders',
            builder: (_, _) => const AdminOrdersScreen(),
          ),
          GoRoute(
            path: '/admin/users',
            builder: (_, _) => const AdminUsersScreen(),
          ),
          GoRoute(
            path: '/admin/coupons',
            builder: (_, _) => const AdminCouponsScreen(),
          ),
          GoRoute(
            path: '/admin/banners',
            builder: (_, _) => const AdminBannersScreen(),
          ),
          GoRoute(
            path: '/admin/theme',
            builder: (_, _) => const ThemeSettingsScreen(),
          ),
          GoRoute(
            path: '/admin/browse-settings',
            builder: (_, _) => const AdminBrowseSettingsScreen(),
          ),
        ],
      ),
    ],
  );
}

/// Converts a Cubit/Bloc Stream into a Listenable for GoRouter's refreshListenable
class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.listen((_) {
      debugPrint('🔄 GoRouter: Auth state changed, refreshing routes');
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
