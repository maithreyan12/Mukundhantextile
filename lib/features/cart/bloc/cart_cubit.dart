import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/models/cart_item.dart';
import '../../../data/models/coupon.dart';
import '../../../data/repositories/cart_repository.dart';
import '../../../data/repositories/coupon_repository.dart';

class CartState extends Equatable {
  final bool isLoading;
  final String? error;
  final List<CartItem> items;
  final Coupon? appliedCoupon;
  final double discountAmount;

  const CartState({
    this.isLoading = false,
    this.error,
    this.items = const [],
    this.appliedCoupon,
    this.discountAmount = 0,
  });

  double get subtotal =>
      items.fold(0.0, (sum, item) => sum + item.totalPrice);

  double get total => (subtotal - discountAmount).clamp(0, double.infinity);

  int get itemCount => items.length;

  CartState copyWith({
    bool? isLoading,
    String? error,
    List<CartItem>? items,
    Coupon? appliedCoupon,
    double? discountAmount,
  }) {
    return CartState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      items: items ?? this.items,
      appliedCoupon: appliedCoupon ?? this.appliedCoupon,
      discountAmount: discountAmount ?? this.discountAmount,
    );
  }

  @override
  List<Object?> get props =>
      [isLoading, error, items, appliedCoupon, discountAmount];
}

class CartCubit extends Cubit<CartState> {
  final CartRepository _cartRepo;
  final CouponRepository _couponRepo;

  CartCubit({
    CartRepository? cartRepository,
    CouponRepository? couponRepository,
  })  : _cartRepo = cartRepository ?? CartRepository(),
        _couponRepo = couponRepository ?? CouponRepository(),
        super(const CartState());

  Future<void> loadCart() async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final items = await _cartRepo.getCartItems();
      emit(state.copyWith(isLoading: false, items: items));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> addToCart({
    required String productId,
    int quantity = 1,
    Map<String, dynamic>? variant,
  }) async {
    try {
      await _cartRepo.addToCart(
        productId: productId,
        quantity: quantity,
        variant: variant,
      );
      await loadCart();
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> updateQuantity(String cartItemId, int quantity) async {
    try {
      await _cartRepo.updateQuantity(cartItemId, quantity);
      await loadCart();
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> removeItem(String cartItemId) async {
    try {
      await _cartRepo.removeItem(cartItemId);
      await loadCart();
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> clearCart() async {
    try {
      await _cartRepo.clearCart();
      emit(const CartState());
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<bool> applyCoupon(String code) async {
    try {
      final coupon = await _couponRepo.validateCoupon(code);
      if (coupon == null) {
        emit(state.copyWith(error: 'Invalid or expired coupon'));
        return false;
      }
      if (state.subtotal < coupon.minOrderAmount) {
        emit(state.copyWith(
            error:
                'Minimum order amount is ₹${coupon.minOrderAmount.toStringAsFixed(0)}'));
        return false;
      }
      final discount = coupon.calculateDiscount(state.subtotal);
      emit(state.copyWith(appliedCoupon: coupon, discountAmount: discount));
      return true;
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
      return false;
    }
  }

  void removeCoupon() {
    emit(CartState(
      items: state.items,
    ));
  }
}
