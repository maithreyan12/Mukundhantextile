import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/models/product.dart';
import '../../../data/repositories/product_repository.dart';

// ── State ───────────────────────────────────────────────
class ProductListState extends Equatable {
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final List<Product> products;
  final int page;
  final bool hasReachedEnd;
  final String? categoryId;
  final String? searchQuery;
  final String sortBy;
  final double? maxPrice;

  const ProductListState({
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.products = const [],
    this.page = 0,
    this.hasReachedEnd = false,
    this.categoryId,
    this.searchQuery,
    this.sortBy = 'created_at',
    this.maxPrice,
  });

  ProductListState copyWith({
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    List<Product>? products,
    int? page,
    bool? hasReachedEnd,
    String? categoryId,
    String? searchQuery,
    String? sortBy,
    double? maxPrice,
  }) {
    return ProductListState(
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error,
      products: products ?? this.products,
      page: page ?? this.page,
      hasReachedEnd: hasReachedEnd ?? this.hasReachedEnd,
      categoryId: categoryId ?? this.categoryId,
      searchQuery: searchQuery ?? this.searchQuery,
      sortBy: sortBy ?? this.sortBy,
      maxPrice: maxPrice ?? this.maxPrice,
    );
  }

  @override
  List<Object?> get props =>
      [isLoading, isLoadingMore, error, products, page, hasReachedEnd, categoryId, searchQuery, sortBy, maxPrice];
}

// ── Cubit ───────────────────────────────────────────────
class ProductListCubit extends Cubit<ProductListState> {
  final ProductRepository _repo;

  ProductListCubit({ProductRepository? productRepository})
      : _repo = productRepository ?? ProductRepository(),
        super(const ProductListState());

  Future<void> loadProducts({
    String? categoryId,
    String? searchQuery,
    String? sortBy,
    double? maxPrice,
  }) async {
    emit(ProductListState(
      isLoading: true,
      error: null,
      page: 0,
      hasReachedEnd: false,
      categoryId: categoryId,
      searchQuery: searchQuery,
      sortBy: sortBy ?? 'created_at',
      maxPrice: maxPrice,
    ));

    try {
      final products = await _repo.getProducts(
        page: 0,
        categoryId: categoryId,
        searchQuery: searchQuery,
        sortBy: sortBy ?? 'created_at',
        maxPrice: maxPrice,
      );
      emit(state.copyWith(
        isLoading: false,
        products: products,
        page: 0,
        hasReachedEnd: products.length < 20,
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || state.hasReachedEnd) return;
    emit(state.copyWith(isLoadingMore: true));

    try {
      final nextPage = state.page + 1;
      final products = await _repo.getProducts(
        page: nextPage,
        categoryId: state.categoryId,
        searchQuery: state.searchQuery,
        sortBy: state.sortBy,
        maxPrice: state.maxPrice,
      );
      emit(state.copyWith(
        isLoadingMore: false,
        products: [...state.products, ...products],
        page: nextPage,
        hasReachedEnd: products.length < 20,
      ));
    } catch (e) {
      emit(state.copyWith(isLoadingMore: false, error: e.toString()));
    }
  }
}

