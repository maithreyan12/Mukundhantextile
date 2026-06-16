import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/utils/responsive_helper.dart';
import '../../../core/constants.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../shared/widgets/premium_button.dart';
import '../bloc/auth_cubit.dart';
import '../bloc/auth_state.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.isDarkMode ? const Color(0xFF0F0F1A) : Colors.grey.shade100,
      appBar: AppBar(
        title: Text(
          'My Account',
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w900,
            fontSize: 18,
            color: context.isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        elevation: 0,
        backgroundColor: context.isDarkMode ? const Color(0xFF1E1E2A) : Colors.white,
      ),
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          if (state is! AuthAuthenticated) {
            return const Center(child: CircularProgressIndicator());
          }

          final profile = state.profile;
          final isAdmin = profile.email == 'mukundhantextile@gmail.com';

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Column(
                  children: [
                    // ── 1. Profile Header Box ──────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: context.isDarkMode ? const Color(0xFF1E1E2A) : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: context.isDarkMode ? Colors.white10 : Colors.grey.shade300,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  profile.name.isNotEmpty ? profile.name : 'User',
                                  style: context.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 18,
                                    color: context.isDarkMode ? Colors.white : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Brand Logo
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.asset(
                              'ios/logo.jpeg',
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ],
                      ),
                    ),


                    const SizedBox(height: 12),

                    // ── 2. Quick Actions Grid (2x2 Box Cards) ────────────────
                    Container(
                      decoration: BoxDecoration(
                        color: context.isDarkMode ? const Color(0xFF1E1E2A) : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: context.isDarkMode ? Colors.white10 : Colors.grey.shade300,
                        ),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        childAspectRatio: 2.8,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        children: [
                          _quickActionButton(
                            context,
                            icon: Icons.inventory_2_outlined,
                            label: 'Orders',
                            onTap: () => context.push('/orders'),
                          ),
                          _quickActionButton(
                            context,
                            icon: Icons.favorite_border,
                            label: 'Wishlist',
                            onTap: () => context.push('/wishlist'),
                          ),
                          _quickActionButton(
                            context,
                            icon: Icons.card_giftcard_outlined,
                            label: 'Coupons',
                            onTap: () => _showCouponsDialog(context),
                          ),
                          _quickActionButton(
                            context,
                            icon: Icons.headset_mic_outlined,
                            label: 'Help Center',
                            onTap: () => _showStoreInfoSheet(context),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ── 4. Admin Dashboard (Mukundhan Tex Admin Only) ────────
                    if (isAdmin) ...[
                      _sectionHeader('Admin Controls'),
                      Container(
                        decoration: BoxDecoration(
                          color: context.isDarkMode ? const Color(0xFF1E1E2A) : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: context.isDarkMode ? Colors.white10 : Colors.grey.shade300,
                          ),
                        ),
                        child: _settingsTile(
                          context,
                          icon: Icons.admin_panel_settings_outlined,
                          title: 'Admin Dashboard',
                          onTap: () => context.push('/admin'),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // ── 5. Account Settings Box ──────────────────────────────
                    _sectionHeader('Account Settings'),
                    Container(
                      decoration: BoxDecoration(
                        color: context.isDarkMode ? const Color(0xFF1E1E2A) : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: context.isDarkMode ? Colors.white10 : Colors.grey.shade300,
                        ),
                      ),
                      child: Column(
                        children: [
                          _settingsTile(
                            context,
                            icon: Icons.person_outline,
                            title: 'Edit Profile',
                            onTap: () => _showEditProfileDialog(context, profile.name, profile.email, profile.phone ?? ''),
                          ),
                          _settingsTile(
                            context,
                            icon: Icons.location_on_outlined,
                            title: 'Saved Addresses',
                            onTap: () => context.push('/address-form'),
                          ),
                          _settingsTile(
                            context,
                            icon: Icons.translate,
                            title: 'Select Language',
                            onTap: () => _showLanguageDialog(context),
                          ),
                          _settingsTile(
                            context,
                            icon: Icons.notifications_none_outlined,
                            title: 'Notification Settings',
                            onTap: () => context.push('/notifications'),
                          ),
                          _settingsTile(
                            context,
                            icon: Icons.privacy_tip_outlined,
                            title: 'Privacy Center',
                            onTap: () => _showPrivacyDialog(context),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ── Security Box ─────────────────────────────────────────
                    _sectionHeader('Security'),
                    Container(
                      decoration: BoxDecoration(
                        color: context.isDarkMode ? const Color(0xFF1E1E2A) : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: context.isDarkMode ? Colors.white10 : Colors.grey.shade300,
                        ),
                      ),
                      child: Column(
                        children: [
                          _settingsTile(
                            context,
                            icon: Icons.lock_outline,
                            title: 'Change Password',
                            onTap: () => _showChangePasswordDialog(context),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ── 6. My Activity Box ───────────────────────────────────
                    _sectionHeader('My Activity'),
                    Container(
                      decoration: BoxDecoration(
                        color: context.isDarkMode ? const Color(0xFF1E1E2A) : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: context.isDarkMode ? Colors.white10 : Colors.grey.shade300,
                        ),
                      ),
                      child: Column(
                        children: [
                          _settingsTile(
                            context,
                            icon: Icons.rate_review_outlined,
                            title: 'Reviews',
                            onTap: () => context.showSnackBar('Your Reviews will appear here!'),
                          ),
                          _settingsTile(
                            context,
                            icon: Icons.question_answer_outlined,
                            title: 'Questions & Answers',
                            onTap: () => context.showSnackBar('Your Q&A history will appear here!'),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ── 9. Log Out Button Box ────────────────────────────────
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: context.isDarkMode ? const Color(0xFF1E1E2A) : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: context.isDarkMode ? Colors.white10 : Colors.grey.shade300,
                        ),
                      ),
                      child: OutlinedButton(
                        onPressed: () => context.read<AuthCubit>().signOut(),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          side: BorderSide.none,
                          backgroundColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Log Out',
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Helper Widgets ──────────────────────────────────────────

  Widget _quickActionButton(BuildContext context, {required IconData icon, required String label, required VoidCallback onTap}) {
    final isDark = context.isDarkMode;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: Colors.blue.shade600),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _settingsTile(BuildContext context, {required IconData icon, required String title, required VoidCallback onTap}) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, size: 20, color: Colors.blue.shade600),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      dense: true,
    );
  }

  // ── Dialogs & Sheets ────────────────────────────────────────

  void _showEditProfileDialog(BuildContext context, String currentName, String currentEmail, String currentPhone) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _EditProfileDialog(
        currentName: currentName,
        currentEmail: currentEmail,
        currentPhone: currentPhone,
        onSave: (data) {
          context.read<AuthCubit>().updateProfile(data);
        },
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool obscureNew = true;
    bool obscureConfirm = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.lock_reset_outlined, color: Colors.blue),
                SizedBox(width: 8),
                Text('Change Password'),
              ],
            ),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomTextField(
                    controller: newPasswordController,
                    label: 'New Password',
                    hint: 'Enter new password',
                    obscureText: obscureNew,
                    prefixIcon: Icons.lock_outline,
                    suffixIcon: IconButton(
                      icon: Icon(obscureNew ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => obscureNew = !obscureNew),
                    ),
                    validator: (val) {
                      if (val == null || val.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    controller: confirmPasswordController,
                    label: 'Confirm Password',
                    hint: 'Re-enter new password',
                    obscureText: obscureConfirm,
                    prefixIcon: Icons.lock_outline,
                    suffixIcon: IconButton(
                      icon: Icon(obscureConfirm ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => obscureConfirm = !obscureConfirm),
                    ),
                    validator: (val) {
                      if (val != newPasswordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (formKey.currentState?.validate() ?? false) {
                    await context.read<AuthCubit>().updatePassword(
                      newPasswordController.text.trim(),
                    );
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Password changed successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
                child: const Text('Change Password'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showCouponsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Available Coupons'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _couponRow(context, 'WELCOME100', '₹100 Off on your first order'),
            const Divider(),
            _couponRow(context, 'FESTIVE15', '15% Off on premium sarees'),
            const Divider(),
            _couponRow(context, 'MUGUNDHAN50', '₹50 Off on orders above ₹500'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _couponRow(BuildContext context, String code, String desc) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        title: Text(
          code,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
        ),
        subtitle: Text(desc),
        trailing: IconButton(
          icon: const Icon(Icons.copy),
          onPressed: () {
            context.showSnackBar('Code $code copied!');
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Select Language'),
        children: [
          SimpleDialogOption(
            onPressed: () {
              context.showSnackBar('Language set to English');
              Navigator.pop(ctx);
            },
            child: const Text('English'),
          ),
          SimpleDialogOption(
            onPressed: () {
              context.showSnackBar('Language set to Tamil (தமிழ்)');
              Navigator.pop(ctx);
            },
            child: const Text('Tamil (தமிழ்)'),
          ),
          SimpleDialogOption(
            onPressed: () {
              context.showSnackBar('Language set to Hindi (हिंदी)');
              Navigator.pop(ctx);
            },
            child: const Text('Hindi (हिंदी)'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Privacy Center'),
        content: const Text(
          'Your privacy is important to us. All personal data is encrypted, and payment information is securely processed. We do not sell your personal data to third parties.',
          style: TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showStoreInfoSheet(BuildContext context) {
    final isDesktop = Responsive.isLargeScreen(context);
    final content = Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.store, color: Theme.of(context).colorScheme.primary, size: 28),
              const SizedBox(width: 12),
              Text('Our Store',
                style: context.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.location_on, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    AppConstants.contactAddress,
                    style: context.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.phone, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  AppConstants.contactPhone,
                  style: context.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                final uri = Uri.parse(
                  'https://maps.app.goo.gl/FkS3Pras5srMkBc86?g_st=iw',
                );
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              icon: const Icon(Icons.map),
              label: const Text('Open in Maps'),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );

    if (isDesktop) {
      showDialog(
        context: context,
        builder: (ctx) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: content,
          ),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) => content,
      );
    }
  }

  void _showAboutSheet(BuildContext context) {
    final isDesktop = Responsive.isLargeScreen(context);
    final content = Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.checkroom, color: Theme.of(context).colorScheme.primary, size: 48),
          const SizedBox(height: 12),
          Text('Mugundhan Tex & Readymades',
            style: context.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(AppConstants.appTagline,
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.isDarkMode ? Colors.white60 : Colors.black54,
            )),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _infoRow(context, Icons.location_on_outlined, AppConstants.contactAddress),
                const SizedBox(height: 12),
                _infoRow(context, Icons.phone_outlined, AppConstants.contactPhone),
                const SizedBox(height: 12),
                _infoRow(context, Icons.email_outlined, AppConstants.adminEmail),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('Version 1.0.0',
            style: context.textTheme.bodySmall),
          const SizedBox(height: 16),
        ],
      ),
    );

    if (isDesktop) {
      showDialog(
        context: context,
        builder: (ctx) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: content,
          ),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) => content,
      );
    }
  }

  Widget _infoRow(BuildContext context, IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: context.textTheme.bodySmall)),
      ],
    );
  }
}

class _EditProfileDialog extends StatefulWidget {
  final String currentName;
  final String currentEmail;
  final String currentPhone;
  final Function(Map<String, String>) onSave;

  const _EditProfileDialog({
    required this.currentName,
    required this.currentEmail,
    required this.currentPhone,
    required this.onSave,
  });

  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  final _otpController = TextEditingController();

  bool _isOtpSent = false;
  String _otpTargetType = ''; // 'Email' or 'Phone'
  String _otpTargetValue = '';
  int _secondsRemaining = 59;
  Timer? _timer;
  final String _sentOtpCode = '1234'; // Mock OTP code for verification

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
    _emailController = TextEditingController(text: widget.currentEmail);
    _phoneController = TextEditingController(text: widget.currentPhone);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _secondsRemaining = 59;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        _timer?.cancel();
      }
    });
  }

  void _sendOtp(String type, String value) {
    if (value.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a valid $type')),
      );
      return;
    }
    setState(() {
      _isOtpSent = true;
      _otpTargetType = type;
      _otpTargetValue = value;
      _otpController.clear();
    });
    _startTimer();
    
    // Simulate sending OTP
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Verification OTP code sent to $value! (Mock code is $_sentOtpCode)'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _confirmOtp() {
    if (_otpController.text.trim() == _sentOtpCode) {
      // Verification successful! Save changes.
      widget.onSave({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
      });
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated and verified successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid OTP. Please try again! (Hint: use 1234)'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isOtpSent) {
      return AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.shield_outlined, color: Colors.blue),
            const SizedBox(width: 8),
            Text('Verify $_otpTargetType'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'A 4-digit verification code has been sent to:',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 4),
            Text(
              _otpTargetValue,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 8),
              decoration: InputDecoration(
                counterText: '',
                hintText: '0000',
                hintStyle: TextStyle(color: Colors.grey.shade400, letterSpacing: 8),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _secondsRemaining > 0 ? 'Resend in ${_secondsRemaining}s' : 'Did not receive code?',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                if (_secondsRemaining == 0)
                  TextButton(
                    onPressed: () => _sendOtp(_otpTargetType, _otpTargetValue),
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
              setState(() {
                _isOtpSent = false;
              });
            },
            child: const Text('Back'),
          ),
          ElevatedButton(
            onPressed: _confirmOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text('Verify & Confirm'),
          ),
        ],
      );
    }

    return AlertDialog(
      title: const Text('Edit Account Info'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomTextField(
              controller: _nameController,
              label: 'Name',
              hint: 'Enter your name',
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: _emailController,
              label: 'Email',
              hint: 'Enter your email',
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: _phoneController,
              label: 'Phone number',
              hint: 'Enter your phone number',
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final newEmail = _emailController.text.trim();
            final newPhone = _phoneController.text.trim();
            
            // Prefer verification for modified email, else phone, else default to email
            if (newEmail != widget.currentEmail) {
              _sendOtp('Email', newEmail);
            } else if (newPhone != widget.currentPhone) {
              _sendOtp('Phone', newPhone);
            } else {
              _sendOtp('Email', newEmail);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: const Text('Save & Verify'),
        ),
      ],
    );
  }
}
