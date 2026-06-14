import 'package:flutter/material.dart';
import '../../../core/utils/extensions.dart';
import '../../../data/models/coupon.dart';
import '../../../data/repositories/coupon_repository.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../shared/widgets/premium_button.dart';

class AdminCouponsScreen extends StatefulWidget {
  const AdminCouponsScreen({super.key});

  @override
  State<AdminCouponsScreen> createState() => _AdminCouponsScreenState();
}

class _AdminCouponsScreenState extends State<AdminCouponsScreen> {
  final _repo = CouponRepository();
  List<Coupon> _coupons = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final coupons = await _repo.getAllCoupons();
    setState(() {
      _coupons = coupons;
      _isLoading = false;
    });
  }

  void _showForm({Coupon? coupon}) {
    final codeCtrl = TextEditingController(text: coupon?.code ?? '');
    final valueCtrl =
        TextEditingController(text: coupon?.value.toString() ?? '');
    final minCtrl =
        TextEditingController(text: coupon?.minOrderAmount.toString() ?? '0');
    final limitCtrl =
        TextEditingController(text: coupon?.usageLimit.toString() ?? '0');
    String discountType = coupon?.discountType ?? 'percentage';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(coupon == null ? 'Create Coupon' : 'Edit Coupon'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomTextField(
                  controller: codeCtrl,
                  label: 'Code',
                  hint: 'e.g. SAVE20',
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: discountType,
                  items: const [
                    DropdownMenuItem(
                        value: 'percentage', child: Text('Percentage')),
                    DropdownMenuItem(
                        value: 'flat', child: Text('Flat Amount')),
                  ],
                  onChanged: (v) =>
                      setDialogState(() => discountType = v ?? 'percentage'),
                  decoration:
                      const InputDecoration(labelText: 'Discount Type'),
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: valueCtrl,
                  label: 'Value',
                  hint: discountType == 'percentage' ? 'e.g. 20' : 'e.g. 500',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: minCtrl,
                  label: 'Min Order Amount',
                  hint: '0',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: limitCtrl,
                  label: 'Usage Limit (0 = unlimited)',
                  hint: '0',
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            SizedBox(
              width: 100,
              height: 40,
              child: PremiumButton(
                backgroundColor: context.isDarkMode ? Colors.white : Colors.black,
                onPressed: () async {
                  final data = {
                    'code': codeCtrl.text.trim(),
                    'discount_type': discountType,
                    'value': double.tryParse(valueCtrl.text) ?? 0,
                    'min_order_amount': double.tryParse(minCtrl.text) ?? 0,
                    'usage_limit': int.tryParse(limitCtrl.text) ?? 0,
                    'is_active': true,
                  };
                  if (coupon == null) {
                    await _repo.createCoupon(data);
                  } else {
                    await _repo.updateCoupon(coupon.id, data);
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
                  _load();
                },
                child: Text('Save', style: TextStyle(color: context.isDarkMode ? Colors.black : Colors.white, fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Coupons'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => _showForm(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _coupons.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final c = _coupons[index];
                  return ListTile(
                    title: Text(c.code,
                        style: context.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        )),
                    subtitle: Text(
                      '${c.discountLabel} · Used: ${c.usedCount}/${c.usageLimit > 0 ? c.usageLimit : '∞'} · ${c.isValid ? 'Active' : 'Expired'}',
                      style: context.textTheme.bodySmall,
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          onPressed: () => _showForm(coupon: c),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              size: 18, color: Color(0xFFFF6B6B)),
                          onPressed: () async {
                            await _repo.deleteCoupon(c.id);
                            _load();
                          },
                        ),
                      ],
                    ),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    tileColor: context.isDarkMode
                        ? Colors.white.withValues(alpha: 0.03)
                        : Colors.grey.shade50,
                  );
                },
              ),
            ),
    );
  }
}
