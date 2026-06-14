import 'package:flutter/material.dart';
import '../../../shared/widgets/responsive_wrapper.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants.dart';
import '../../../core/utils/extensions.dart';
import '../../../data/models/address.dart';
import '../../../data/repositories/address_repository.dart';
import '../../../data/repositories/order_repository.dart';
import '../../../shared/widgets/premium_button.dart';
import '../bloc/cart_cubit.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _addressRepo = AddressRepository();
  final _orderRepo = OrderRepository();
  Address? _selectedAddress;
  String _paymentMethod = 'cod';
  bool _isLoading = false;
  bool _isPlacingOrder = false;

  @override
  void initState() {
    super.initState();
    _loadDefaultAddress();
  }

  Future<void> _loadDefaultAddress() async {
    setState(() => _isLoading = true);
    final addr = await _addressRepo.getDefaultAddress();
    setState(() {
      _selectedAddress = addr;
      _isLoading = false;
    });
  }

  Future<void> _placeOrder() async {
    if (_selectedAddress == null) {
      context.showSnackBar('Please add a delivery address', isError: true);
      return;
    }

    setState(() => _isPlacingOrder = true);
    try {
      final cartState = context.read<CartCubit>().state;
      await _orderRepo.placeOrder(
        items: cartState.items,
        totalAmount: cartState.subtotal,
        discountAmount: cartState.discountAmount,
        couponCode: cartState.appliedCoupon?.code,
        paymentMethod: _paymentMethod,
        shippingAddress: _selectedAddress!.toShippingJson(),
      );

      if (!mounted) return;
      context.read<CartCubit>().clearCart();
      context.go('/order-success');
    } catch (e) {
      if (mounted) {
        context.showSnackBar('Failed to place order: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isPlacingOrder = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartState = context.watch<CartCubit>().state;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: ResponsiveWrapper(
        maxWidth: 900,
        child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Delivery Address ────────────────────
                  Text('DELIVERY ADDRESS',
                      style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, letterSpacing: 1.0)),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: context.isDarkMode
                          ? const Color(0xFF1A1A1A)
                          : Colors.grey.shade50,
                      borderRadius: BorderRadius.zero,
                      border: Border.all(
                        color: context.isDarkMode ? Colors.white12 : Colors.grey.shade300,
                        width: 1.5,
                      ),
                    ),
                    child: _selectedAddress != null
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_selectedAddress!.fullName.toUpperCase(),
                                  style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                              const SizedBox(height: 8),
                              Text(_selectedAddress!.shortAddress,
                                  style: context.textTheme.bodyMedium),
                              const SizedBox(height: 4),
                              Text(
                                _selectedAddress!.phone,
                                style: context.textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 16),
                              GestureDetector(
                                onTap: () =>
                                    context.push('/address-form').then((_) =>
                                        _loadDefaultAddress()),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: context.isDarkMode ? Colors.white24 : Colors.black26),
                                  ),
                                  child: Text(
                                    'CHANGE ADDRESS',
                                    style: TextStyle(
                                      color: context.isDarkMode ? Colors.white : Colors.black,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : InkWell(
                            onTap: () => context
                                .push('/address-form')
                                .then((_) => _loadDefaultAddress()),
                            child: Row(
                              children: [
                                Icon(Icons.add,
                                    color: context.isDarkMode ? Colors.white : Colors.black),
                                const SizedBox(width: 8),
                                Text(
                                  'ADD NEW ADDRESS',
                                  style:
                                      context.textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),

                  const SizedBox(height: 28),

                  // ── Payment Method ──────────────────────
                  Text('PAYMENT METHOD',
                      style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, letterSpacing: 1.0)),
                  const SizedBox(height: 12),
                  ...AppConstants.paymentMethods.map((method) {
                    return RadioListTile<String>(
                      value: method,
                      groupValue: _paymentMethod,
                      onChanged: (v) =>
                          setState(() => _paymentMethod = v!),
                      title: Text(AppConstants.paymentMethodLabel(method).toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
                      activeColor: context.isDarkMode ? Colors.white : Colors.black,
                      contentPadding: EdgeInsets.zero,
                    );
                  }),

                  const SizedBox(height: 28),

                  // ── Order Summary ───────────────────────
                  Text('ORDER SUMMARY',
                      style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, letterSpacing: 1.0)),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: context.isDarkMode ? const Color(0xFF1A1A1A) : Colors.grey.shade50,
                      borderRadius: BorderRadius.zero,
                      border: Border.all(color: context.isDarkMode ? Colors.white12 : Colors.black12, width: 1.5),
                    ),
                    child: Column(
                      children: [
                        _summaryRow('ITEMS', '${cartState.itemCount}'),
                        const SizedBox(height: 12),
                        _summaryRow('SUBTOTAL', cartState.subtotal.toCurrency),
                        if (cartState.discountAmount > 0) ...[
                          const SizedBox(height: 12),
                          _summaryRow(
                            'DISCOUNT',
                            '-${cartState.discountAmount.toCurrency}',
                            valueColor: const Color(0xFFEaeaea),
                          ),
                        ],
                        const SizedBox(height: 12),
                        _summaryRow('SHIPPING', 'FREE'),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Divider(height: 1, color: Colors.white24),
                        ),
                        _summaryRow(
                          'TOTAL',
                          cartState.total.toCurrency,
                          isBold: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  PremiumButton(
                    onPressed: _isPlacingOrder ? null : _placeOrder,
                    backgroundColor: const Color(0xFFEAEAEA),
                    child: _isPlacingOrder
                        ? const CircularProgressIndicator(color: Colors.black)
                        : Text('PLACE ORDER · ${cartState.total.toCurrency}', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
      ),
    );
  }

  Widget _summaryRow(String label, String value,
      {bool isBold = false, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isBold
              ? context.textTheme.titleMedium
              : context.textTheme.bodyMedium,
        ),
        Text(
          value,
          style: (isBold
                  ? context.textTheme.titleMedium
                  : context.textTheme.bodyMedium)
              ?.copyWith(
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
