import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/models/banner_model.dart';
import '../../../data/models/category.dart';
import '../../../data/models/product.dart';
import '../../../data/repositories/banner_repository.dart';
import '../../../data/repositories/category_repository.dart';
import '../../../data/repositories/product_repository.dart';

// ── State ───────────────────────────────────────────────
class HomeState extends Equatable {
  final bool isLoading;
  final String? error;
  final List<BannerModel> banners;
  final List<Category> categories;
  final List<Product> newArrivals;
  final List<Product> bestSellers;
  final List<Product> featured;

  const HomeState({
    this.isLoading = false,
    this.error,
    this.banners = const [],
    this.categories = const [],
    this.newArrivals = const [],
    this.bestSellers = const [],
    this.featured = const [],
  });

  HomeState copyWith({
    bool? isLoading,
    String? error,
    List<BannerModel>? banners,
    List<Category>? categories,
    List<Product>? newArrivals,
    List<Product>? bestSellers,
    List<Product>? featured,
  }) {
    return HomeState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      banners: banners ?? this.banners,
      categories: categories ?? this.categories,
      newArrivals: newArrivals ?? this.newArrivals,
      bestSellers: bestSellers ?? this.bestSellers,
      featured: featured ?? this.featured,
    );
  }

  @override
  List<Object?> get props =>
      [isLoading, error, banners, categories, newArrivals, bestSellers, featured];
}

// ── Cubit ───────────────────────────────────────────────
class HomeCubit extends Cubit<HomeState> {
  final ProductRepository _productRepo;
  final CategoryRepository _categoryRepo;
  final BannerRepository _bannerRepo;

  HomeCubit({
    ProductRepository? productRepository,
    CategoryRepository? categoryRepository,
    BannerRepository? bannerRepository,
  })  : _productRepo = productRepository ?? ProductRepository(),
        _categoryRepo = categoryRepository ?? CategoryRepository(),
        _bannerRepo = bannerRepository ?? BannerRepository(),
        super(const HomeState());

  Future<void> loadHome() async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final results = await Future.wait([
        _bannerRepo.getActiveBanners(),
        _categoryRepo.getCategories(),
        _productRepo.getNewArrivals(limit: 10),
        _productRepo.getBestSellers(limit: 10),
        _productRepo.getFeaturedProducts(limit: 10),
      ]);

      emit(state.copyWith(
        isLoading: false,
        banners: results[0] as List<BannerModel>,
        categories: results[1] as List<Category>,
        newArrivals: results[2] as List<Product>,
        bestSellers: results[3] as List<Product>,
        featured: results[4] as List<Product>,
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }
}
