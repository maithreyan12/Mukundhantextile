import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/utils/validators.dart';
import '../../../data/repositories/address_repository.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../shared/widgets/premium_button.dart';

class AddressFormScreen extends StatefulWidget {
  const AddressFormScreen({super.key});

  @override
  State<AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends State<AddressFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repo = AddressRepository();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _streetCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _pincodeCtrl = TextEditingController();
  bool _isDefault = true;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _streetCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _pincodeCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      await _repo.addAddress({
        'full_name': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'street': _streetCtrl.text.trim(),
        'city': _cityCtrl.text.trim(),
        'state': _stateCtrl.text.trim(),
        'pincode': _pincodeCtrl.text.trim(),
        'is_default': _isDefault,
      });
      if (mounted) {
        context.showSuccessSnackBar('Address saved!');
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        context.showSnackBar('Failed to save: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Address'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              CustomTextField(
                controller: _nameCtrl,
                label: 'Full Name',
                hint: 'Enter full name',
                prefixIcon: Icons.person_outline,
                validator: (v) => Validators.required(v, 'Name'),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _phoneCtrl,
                label: 'Phone',
                hint: 'Enter phone number',
                keyboardType: TextInputType.phone,
                prefixIcon: Icons.phone_outlined,
                validator: Validators.phone,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _streetCtrl,
                label: 'Street Address',
                hint: 'Enter street address',
                prefixIcon: Icons.home_outlined,
                maxLines: 2,
                validator: (v) => Validators.required(v, 'Street'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _cityCtrl,
                      label: 'City',
                      hint: 'City',
                      validator: (v) => Validators.required(v, 'City'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomTextField(
                      controller: _stateCtrl,
                      label: 'State',
                      hint: 'State',
                      validator: (v) => Validators.required(v, 'State'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _pincodeCtrl,
                label: 'Pincode',
                hint: 'Enter pincode',
                keyboardType: TextInputType.number,
                prefixIcon: Icons.pin_drop_outlined,
                validator: Validators.pincode,
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                value: _isDefault,
                onChanged: (v) => setState(() => _isDefault = v),
                title: const Text('Set as default address'),
                activeThumbColor: context.isDarkMode ? Colors.black : Colors.white,
                activeTrackColor: const Color(0xFFEAEAEA),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 24),
              PremiumButton(
                onPressed: _isSaving ? null : _save,
                backgroundColor: const Color(0xFFEAEAEA),
                child: _isSaving 
                     ? const CircularProgressIndicator(color: Colors.black)
                     : const Text('SAVE ADDRESS', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800, letterSpacing: 1.0)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
