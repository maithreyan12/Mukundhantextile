import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/extensions.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/status_chip.dart';
import '../bloc/orders_cubit.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  @override
  void initState() {
    super.initState();
    context.read<OrdersCubit>().loadOrders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
        title: Text('MY ORDERS', style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, letterSpacing: 1.5)),
        centerTitle: true,
      ),
      body: BlocBuilder<OrdersCubit, OrdersState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.orders.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.receipt_long_outlined,
              title: 'No Orders Yet',
              subtitle: 'Place your first order!',
            );
          }

          return RefreshIndicator(
            onRefresh: () => context.read<OrdersCubit>().loadOrders(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: state.orders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final order = state.orders[index];
                return GestureDetector(
                  onTap: () => context.push('/order/${order.id}'),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: context.isDarkMode
                          ? const Color(0xFF1A1A1A)
                          : Colors.white,
                      borderRadius: BorderRadius.zero,
                      border: Border.all(
                        color: context.isDarkMode ? Colors.white12 : Colors.black12,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'ORDER #${order.id.substring(0, 8).toUpperCase()}',
                              style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: 1.0),
                            ),
                            StatusChip(label: order.status.label),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '${order.items.length} ITEM(S) · ${order.finalAmount.toCurrency}',
                          style: context.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          order.createdAt.formattedWithTime,
                          style: context.textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
