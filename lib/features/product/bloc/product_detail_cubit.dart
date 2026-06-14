import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/models/product.dart';
import '../../../data/models/review.dart';
import '../../../data/repositories/product_repository.dart';
import '../../../data/repositories/review_repository.dart';

class ProductDetailState extends Equatable {
  final bool isLoading;
  final String? error;
  final Product? product;
  final List<Review> reviews;
  final Review? userReview;

  const ProductDetailState({
    this.isLoading = false,
    this.error,
    this.product,
    this.reviews = const [],
    this.userReview,
  });

  ProductDetailState copyWith({
    bool? isLoading,
    String? error,
    Product? product,
    List<Review>? reviews,
    Review? userReview,
  }) {
    return ProductDetailState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      product: product ?? this.product,
      reviews: reviews ?? this.reviews,
      userReview: userReview ?? this.userReview,
    );
  }

  @override
  List<Object?> get props => [isLoading, error, product, reviews, userReview];
}

class ProductDetailCubit extends Cubit<ProductDetailState> {
  final ProductRepository _productRepo;
  final ReviewRepository _reviewRepo;

  ProductDetailCubit({
    ProductRepository? productRepository,
    ReviewRepository? reviewRepository,
  })  : _productRepo = productRepository ?? ProductRepository(),
        _reviewRepo = reviewRepository ?? ReviewRepository(),
        super(const ProductDetailState());

  Future<void> loadProduct(String id) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final results = await Future.wait([
        _productRepo.getProduct(id),
        _reviewRepo.getProductReviews(id),
      ]);
      final product = results[0] as Product;
      final reviews = results[1] as List<Review>;

      Review? userReview;
      try {
        userReview = await _reviewRepo.getUserReview(id);
      } catch (_) {}

      emit(state.copyWith(
        isLoading: false,
        product: product,
        reviews: reviews,
        userReview: userReview,
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> addReview({
    required String productId,
    required int rating,
    String? comment,
  }) async {
    try {
      await _reviewRepo.addReview(
        productId: productId,
        rating: rating,
        comment: comment,
      );
      await loadProduct(productId);
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }
}
