import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/models/order.dart';
import '../../../data/repositories/order_repository.dart';

class OrdersState extends Equatable {
  final bool isLoading;
  final String? error;
  final List<Order> orders;

  const OrdersState({
    this.isLoading = false,
    this.error,
    this.orders = const [],
  });

  OrdersState copyWith({
    bool? isLoading,
    String? error,
    List<Order>? orders,
  }) {
    return OrdersState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      orders: orders ?? this.orders,
    );
  }

  @override
  List<Object?> get props => [isLoading, error, orders];
}

class OrdersCubit extends Cubit<OrdersState> {
  final OrderRepository _repo;

  OrdersCubit({OrderRepository? orderRepository})
      : _repo = orderRepository ?? OrderRepository(),
        super(const OrdersState());

  Future<void> loadOrders({String? status}) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final orders = await _repo.getUserOrders(status: status);
      emit(state.copyWith(isLoading: false, orders: orders));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }
}
