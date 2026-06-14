import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/models/product.dart';
import '../../../data/repositories/wishlist_repository.dart';

class WishlistState extends Equatable {
  final bool isLoading;
  final String? error;
  final List<Product> products;
  final Set<String> wishlistIds;

  const WishlistState({
    this.isLoading = false,
    this.error,
    this.products = const [],
    this.wishlistIds = const {},
  });

  WishlistState copyWith({
    bool? isLoading,
    String? error,
    List<Product>? products,
    Set<String>? wishlistIds,
  }) {
    return WishlistState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      products: products ?? this.products,
      wishlistIds: wishlistIds ?? this.wishlistIds,
    );
  }

  @override
  List<Object?> get props => [isLoading, error, products, wishlistIds];
}

class WishlistCubit extends Cubit<WishlistState> {
  final WishlistRepository _repo;

  WishlistCubit({WishlistRepository? wishlistRepository})
      : _repo = wishlistRepository ?? WishlistRepository(),
        super(const WishlistState());

  Future<void> loadWishlist() async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final results = await Future.wait([
        _repo.getWishlist(),
        _repo.getWishlistIds(),
      ]);
      emit(state.copyWith(
        isLoading: false,
        products: results[0] as List<Product>,
        wishlistIds: results[1] as Set<String>,
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> loadWishlistIds() async {
    try {
      final ids = await _repo.getWishlistIds();
      emit(state.copyWith(wishlistIds: ids));
    } catch (_) {}
  }

  Future<void> toggleWishlist(String productId) async {
    try {
      final isInWishlist = state.wishlistIds.contains(productId);
      if (isInWishlist) {
        await _repo.removeFromWishlist(productId);
        final newIds = Set<String>.from(state.wishlistIds)..remove(productId);
        final newProducts =
            state.products.where((p) => p.id != productId).toList();
        emit(state.copyWith(wishlistIds: newIds, products: newProducts));
      } else {
        await _repo.addToWishlist(productId);
        final newIds = Set<String>.from(state.wishlistIds)..add(productId);
        emit(state.copyWith(wishlistIds: newIds));
      }
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }
}
