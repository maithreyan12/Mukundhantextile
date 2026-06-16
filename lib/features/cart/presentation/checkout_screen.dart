import 'dart:async';
import 'package:flutter/material.dart';
import '../../../shared/widgets/responsive_wrapper.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants.dart';
import '../../../core/utils/extensions.dart';
import '../../../data/models/address.dart';
import '../../../data/models/user_profile.dart';
import '../../../data/repositories/address_repository.dart';
import '../../../data/repositories/order_repository.dart';
import '../../../shared/widgets/premium_button.dart';
import '../../auth/bloc/auth_cubit.dart';
import '../../auth/bloc/auth_state.dart';
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

    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated) {
      final profile = authState.profile;
      if (!profile.isPhoneVerified) {
        final phoneToVerify = (profile.phone != null && profile.phone!.isNotEmpty)
            ? profile.phone!
            : _selectedAddress!.phone;
        
        if (phoneToVerify.trim().isEmpty) {
          context.showSnackBar('Please add a phone number to your delivery address first.', isError: true);
          return;
        }

        final verified = await _showCheckoutVerificationDialog(profile, phoneToVerify);
        if (!verified) {
          context.showSnackBar('Mobile number verification is required to place your order.', isError: true);
          return;
        }
      }
    }

    setState(() => _isPlacingOrder = true);
    try {
      final cartState = context.read<CartCubit>().state;
      final shippingCost = cartState.subtotal < 3000 ? 100.0 : 0.0;
      await _orderRepo.placeOrder(
        items: cartState.items,
        totalAmount: cartState.subtotal + shippingCost,
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

  Future<bool> _showCheckoutVerificationDialog(UserProfile profile, String phoneToVerify) async {
    final otpController = TextEditingController();
    bool isLoading = false;
    int secondsRemaining = 59;
    Timer? timer;
    const sentOtpCode = '1234';

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          if (timer == null) {
            secondsRemaining = 59;
            timer = Timer.periodic(const Duration(seconds: 1), (t) {
              if (secondsRemaining > 0) {
                setState(() {
                  secondsRemaining--;
                });
              } else {
                timer?.cancel();
              }
            });
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('OTP code sent to $phoneToVerify! (Mock code is $sentOtpCode)'),
                  backgroundColor: Colors.green,
                ),
              );
            });
          }

          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.verified_user, color: Colors.blue),
                SizedBox(width: 8),
                Text('Verify Mobile No'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'First-time buyers must verify their mobile number for trust and security. Code sent to:',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                Text(
                  phoneToVerify,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 8,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 8),
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: '00000000',
                    hintStyle: TextStyle(color: Colors.grey.shade400, letterSpacing: 8),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      secondsRemaining > 0 ? 'Resend in ${secondsRemaining}s' : 'Did not receive code?',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    if (secondsRemaining == 0)
                      TextButton(
                        onPressed: () {
                          secondsRemaining = 59;
                          timer?.cancel();
                          timer = Timer.periodic(const Duration(seconds: 1), (t) {
                            if (secondsRemaining > 0) {
                              setState(() {
                                secondsRemaining--;
                              });
                            } else {
                              timer?.cancel();
                            }
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('OTP resent to $phoneToVerify! (Mock code is $sentOtpCode)'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },
                        style: TextButton.styleFrom(padding: EdgeInsets.zero),
                        child: const Text('Resend OTP', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  timer?.cancel();
                  Navigator.pop(ctx, false);
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isLoading ? null : () async {
                  if (otpController.text.trim() == sentOtpCode) {
                    timer?.cancel();
                    setState(() => isLoading = true);
                    
                    final isUnique = await context.read<AuthCubit>().checkPhoneUnique(phoneToVerify);
                    if (!isUnique) {
                      setState(() => isLoading = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('This phone number is already linked to another account.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    await context.read<AuthCubit>().updateProfile({
                      'phone': phoneToVerify,
                      'is_phone_verified': true,
                    });
                    
                    if (ctx.mounted) {
                      Navigator.pop(ctx, true);
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Invalid OTP. Use mock code 1234'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
                child: isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Verify & Proceed'),
              ),
            ],
          );
        },
      ),
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final cartState = context.watch<CartCubit>().state;
    final shippingCost = cartState.subtotal < 3000 ? 100.0 : 0.0;
    final finalTotal = cartState.total + shippingCost;

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
                        _summaryRow('SHIPPING', shippingCost > 0 ? shippingCost.toCurrency : 'FREE'),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Divider(height: 1, color: Colors.white24),
                        ),
                        _summaryRow(
                          'TOTAL',
                          finalTotal.toCurrency,
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
                        : Text('PLACE ORDER · ${finalTotal.toCurrency}', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
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
