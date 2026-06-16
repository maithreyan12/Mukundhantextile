import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/constants.dart';
import 'core/theme.dart';
import 'core/router.dart';
import 'features/auth/bloc/auth_cubit.dart';
import 'features/home/bloc/home_cubit.dart';
import 'features/product/bloc/product_list_cubit.dart';
import 'features/product/bloc/product_detail_cubit.dart';
import 'features/cart/bloc/cart_cubit.dart';
import 'features/wishlist/bloc/wishlist_cubit.dart';
import 'features/orders/bloc/orders_cubit.dart';
import 'features/notifications/bloc/notification_cubit.dart';
import 'core/theme_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables from .env file
  try {
    await dotenv.load(fileName: 'env_file');
  } catch (e) {
    debugPrint('⚠️ Warning: Could not load env_file: $e');
  }

  if (AppConstants.supabaseUrl.isEmpty || AppConstants.supabaseAnonKey.isEmpty) {
    debugPrint('❌ Error: Supabase URL or Anon Key is missing in .env file.');
  }

  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );

  // Load theme settings from SharedPreferences
  int colorIndex = 0;
  ThemeMode themeMode = ThemeMode.dark;
  try {
    final prefs = await SharedPreferences.getInstance();
    colorIndex = prefs.getInt('color_theme_index') ?? 0;
    final modeIndex = prefs.getInt('theme_mode_index') ?? 2;
    themeMode = ThemeMode.values[modeIndex.clamp(0, 2)];
  } catch (e) {
    debugPrint('⚠️ SharedPreferences load error: $e');
  }

  runApp(ECommerceApp(initialColorIndex: colorIndex, initialThemeMode: themeMode));
}

class ECommerceApp extends StatefulWidget {
  final int initialColorIndex;
  final ThemeMode initialThemeMode;

  const ECommerceApp({
    super.key,
    required this.initialColorIndex,
    required this.initialThemeMode,
  });

  @override
  State<ECommerceApp> createState() => _ECommerceAppState();
}

class _ECommerceAppState extends State<ECommerceApp> {
  late final AuthCubit _authCubit;
  late final AppRouter _appRouter;

  @override
  void initState() {
    super.initState();
    _authCubit = AuthCubit();
    _appRouter = AppRouter(authCubit: _authCubit);
  }

  @override
  void dispose() {
    _authCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _authCubit),
        BlocProvider(create: (_) => HomeCubit()),
        BlocProvider(create: (_) => ProductListCubit()),
        BlocProvider(create: (_) => ProductDetailCubit()),
        BlocProvider(create: (_) => CartCubit()),
        BlocProvider(create: (_) => WishlistCubit()..loadWishlistIds()),
        BlocProvider(create: (_) => OrdersCubit()),
        BlocProvider(create: (_) => NotificationCubit()),
        BlocProvider(create: (_) => ThemeCubit(
          initialColorIndex: widget.initialColorIndex,
          initialMode: widget.initialThemeMode,
        )),
      ],
      child: BlocBuilder<ThemeCubit, ThemeState>(
        builder: (context, themeState) {
          final ct = themeState.colorTheme;
          return MaterialApp.router(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme(ct),
            darkTheme: AppTheme.darkTheme(ct),
            themeMode: themeState.themeMode,
            routerConfig: _appRouter.router,
          );
        },
      ),
    );
  }
}
