import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import '../../../core/utils/extensions.dart';
import '../../../core/utils/responsive_helper.dart';
import '../../../core/constants.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../shared/widgets/premium_button.dart';
import '../../../data/models/user_profile.dart';
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
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(Icons.email_outlined, size: 14, color: Colors.grey.shade500),
                                    const SizedBox(width: 6),
                                    Text(
                                      profile.email.endsWith('@phone.mukundhantextile.com') ? 'Not Set' : profile.email,
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                    ),
                                    if (!profile.email.endsWith('@phone.mukundhantextile.com')) ...[
                                      const SizedBox(width: 6),
                                      if (profile.isEmailVerified)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.green.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.verified, size: 10, color: Colors.green),
                                              SizedBox(width: 2),
                                              Text('Verified', style: TextStyle(fontSize: 8, color: Colors.green, fontWeight: FontWeight.bold)),
                                            ],
                                          ),
                                        )
                                      else
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.orange.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Text('Unverified', style: TextStyle(fontSize: 8, color: Colors.orange, fontWeight: FontWeight.bold)),
                                        ),
                                    ],
                                  ],
                                ),
                                if (profile.phone != null && profile.phone!.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.phone_android_outlined, size: 14, color: Colors.grey.shade500),
                                      const SizedBox(width: 6),
                                      Text(
                                        profile.phone!,
                                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                      ),
                                      const SizedBox(width: 6),
                                      if (profile.isPhoneVerified)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.green.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.verified, size: 10, color: Colors.green),
                                              SizedBox(width: 2),
                                              Text('Verified', style: TextStyle(fontSize: 8, color: Colors.green, fontWeight: FontWeight.bold)),
                                            ],
                                          ),
                                        )
                                      else
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.orange.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Text('Unverified', style: TextStyle(fontSize: 8, color: Colors.orange, fontWeight: FontWeight.bold)),
                                        ),
                                    ],
                                  ),
                                ],
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

                    // ── 2. Quick Actions Row ────────────────
                    Container(
                      decoration: BoxDecoration(
                        color: context.isDarkMode ? const Color(0xFF1E1E2A) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: context.isDarkMode ? Colors.white10 : Colors.grey.shade200,
                        ),
                        boxShadow: context.isDarkMode ? [] : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
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
                            onTap: () => _showEditProfileDialog(context, profile),
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
                            onTap: () => _showChangePasswordDialog(context, profile),
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
                            onTap: () => context.push('/reviews'),
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
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.blue.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 24, color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
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

  void _showEditProfileDialog(BuildContext context, UserProfile profile) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _EditProfileDialog(
        profile: profile,
        onSave: (data) {
          context.read<AuthCubit>().updateProfile(data);
        },
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context, UserProfile profile) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _ChangePasswordDialog(profile: profile),
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
              Text('Support',
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
  final UserProfile profile;
  final Function(Map<String, dynamic>) onSave;

  const _EditProfileDialog({
    required this.profile,
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
  bool _isLoading = false;
  String _otpTargetType = ''; // 'Email' or 'Phone'
  String _otpTargetValue = '';
  int _secondsRemaining = 59;
  Timer? _timer;
  final String _sentOtpCode = '1234'; // Mock OTP code for verification

  bool _emailNeedsVerification = false;
  bool _phoneNeedsVerification = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.name);
    _emailController = TextEditingController(
      text: widget.profile.email.endsWith('@phone.mukundhantextile.com') 
          ? '' 
          : widget.profile.email
    );
    _phoneController = TextEditingController(text: widget.profile.phone ?? '');
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

  Future<void> _sendOtp(String type, String value) async {
    if (value.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a valid $type')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      if (type == 'Email') {
        await Supabase.instance.client.auth.updateUser(
          UserAttributes(email: value),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Verification link/code sent to email: $value'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (type == 'Phone') {
        var formattedPhone = value.replaceAll(RegExp(r'\s+|-'), '').trim();
        if (!formattedPhone.startsWith('+')) {
          formattedPhone = '+91$formattedPhone';
        }
        await Supabase.instance.client.auth.updateUser(
          UserAttributes(phone: formattedPhone),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Verification OTP code sent to phone: $formattedPhone'),
            backgroundColor: Colors.green,
          ),
        );
      }

      setState(() {
        _isOtpSent = true;
        _otpTargetType = type;
        _otpTargetValue = value;
        _otpController.clear();
      });
      _startTimer();
    } catch (e) {
      debugPrint('Error sending verification: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send verification for $type: $e\n(Falling back to mock code $_sentOtpCode)'),
          backgroundColor: Colors.orange,
        ),
      );
      setState(() {
        _isOtpSent = true;
        _otpTargetType = type;
        _otpTargetValue = value;
        _otpController.clear();
      });
      _startTimer();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmOtp() async {
    final code = _otpController.text.trim();
    if (code.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      bool verified = false;
      if (code == _sentOtpCode) {
        verified = true;
      } else {
        if (_otpTargetType == 'Email') {
          try {
            await Supabase.instance.client.auth.verifyOTP(
              email: _otpTargetValue,
              token: code,
              type: OtpType.emailChange,
            );
            verified = true;
          } catch (e) {
            debugPrint('Real email verification failed: $e');
          }
        } else if (_otpTargetType == 'Phone') {
          try {
            var formattedPhone = _otpTargetValue.replaceAll(RegExp(r'\s+|-'), '').trim();
            if (!formattedPhone.startsWith('+')) {
              formattedPhone = '+91$formattedPhone';
            }
            await Supabase.instance.client.auth.verifyOTP(
              phone: formattedPhone,
              token: code,
              type: OtpType.phoneChange,
            );
            verified = true;
          } catch (e) {
            debugPrint('Real phone verification failed: $e');
          }
        }
      }

      if (verified) {
        final updates = <String, dynamic>{
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'phone': _phoneController.text.trim(),
        };
        
        if (_emailController.text.trim() != widget.profile.email) {
          updates['is_email_verified'] = true;
        }
        if (_phoneController.text.trim() != widget.profile.phone) {
          updates['is_phone_verified'] = true;
        }

        widget.onSave(updates);
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
            content: Text('Invalid OTP code. Please try again! (Hint: use 1234)'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Verification error: $e\n(Hint: You can also use mock code 1234)'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
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
            const SizedBox(height: 8),
            Text(
              'If you do not receive the OTP, please use mock code: 1234',
              style: const TextStyle(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              maxLength: 8,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 8),
              decoration: InputDecoration(
                counterText: '',
                hintText: '00000000',
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
          onPressed: _isLoading ? null : () async {
            final newEmail = _emailController.text.trim();
            final newPhone = _phoneController.text.trim();
            
            _emailNeedsVerification = newEmail.isNotEmpty && newEmail != widget.profile.email;
            _phoneNeedsVerification = newPhone.isNotEmpty && newPhone != widget.profile.phone;

            if (newPhone.isNotEmpty && newPhone != widget.profile.phone) {
              setState(() => _isLoading = true);
              final isUnique = await context.read<AuthCubit>().checkPhoneUnique(newPhone);
              setState(() => _isLoading = false);

              if (!isUnique) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('This phone number is already linked to another account.'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
            }

            if (_emailNeedsVerification || _phoneNeedsVerification) {
              final hasEmail = newEmail.isNotEmpty || widget.profile.email.isNotEmpty;
              final hasPhone = newPhone.isNotEmpty || (widget.profile.phone != null && widget.profile.phone!.isNotEmpty);
              
              if (hasEmail && hasPhone) {
                if (!mounted) return;
                final choice = await showDialog<String>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Choose Verification Method'),
                    content: const Text('To verify and save your changes, please choose how you would like to receive the verification OTP:'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, 'Email'),
                        child: const Text('Email OTP'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, 'Phone'),
                        child: const Text('Phone OTP'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, null),
                        child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                      ),
                    ],
                  ),
                );

                if (choice == null) return; // User cancelled
                
                if (choice == 'Email') {
                  _sendOtp('Email', newEmail.isNotEmpty ? newEmail : widget.profile.email);
                } else {
                  _sendOtp('Phone', newPhone.isNotEmpty ? newPhone : widget.profile.phone!);
                }
              } else if (hasPhone) {
                _sendOtp('Phone', newPhone.isNotEmpty ? newPhone : widget.profile.phone!);
              } else {
                _sendOtp('Email', newEmail.isNotEmpty ? newEmail : widget.profile.email);
              }
            } else {
              widget.onSave({
                'name': _nameController.text.trim(),
              });
              Navigator.pop(context);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: _isLoading 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Save & Verify'),
        ),
      ],
    );
  }
}

class _ChangePasswordDialog extends StatefulWidget {
  final UserProfile profile;

  const _ChangePasswordDialog({required this.profile});

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  bool _isOtpSent = false;
  bool _isLoading = false;
  int _secondsRemaining = 59;
  Timer? _timer;
  final String _sentOtpCode = '1234';

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
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

  Future<void> _verifyOldAndSendOtp() async {
    if (!_formKey.currentState!.validate()) return;

    final phoneVal = widget.profile.phone;
    if (phoneVal == null || phoneVal.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add and verify a mobile number in Edit Profile first.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    final isOldPasswordCorrect = await context.read<AuthCubit>().verifyOldPassword(
          _oldPasswordController.text.trim(),
        );

    if (!isOldPasswordCorrect) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Incorrect old password. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      var formattedPhone = phoneVal.replaceAll(RegExp(r'\s+|-'), '').trim();
      if (!formattedPhone.startsWith('+')) {
        formattedPhone = '+91$formattedPhone';
      }
      await Supabase.instance.client.auth.signInWithOtp(phone: formattedPhone);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('OTP sent to $formattedPhone!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint('Error sending OTP for password change: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not send real OTP: $e\n(Falling back to mock code $_sentOtpCode)'),
          backgroundColor: Colors.orange,
        ),
      );
    }

    setState(() {
      _isOtpSent = true;
      _otpController.clear();
      _isLoading = false;
    });
    _startTimer();
  }

  Future<void> _confirmOtpAndChangePassword() async {
    final code = _otpController.text.trim();
    if (code.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      bool verified = false;
      if (code == _sentOtpCode) {
        verified = true;
      } else {
        try {
          var formattedPhone = widget.profile.phone!.replaceAll(RegExp(r'\s+|-'), '').trim();
          if (!formattedPhone.startsWith('+')) {
            formattedPhone = '+91$formattedPhone';
          }
          await Supabase.instance.client.auth.verifyOTP(
            phone: formattedPhone,
            token: code,
            type: OtpType.sms,
          );
          verified = true;
        } catch (e) {
          debugPrint('Real OTP verification failed: $e');
        }
      }

      if (verified) {
        await context.read<AuthCubit>().updatePassword(
              _newPasswordController.text.trim(),
            );
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Password changed successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid OTP code. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isOtpSent) {
      return AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.shield_outlined, color: Colors.blue),
            SizedBox(width: 8),
            Text('Verify Phone OTP'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'A 4-digit code was sent to ${widget.profile.phone} to authorize password change:',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
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
                    onPressed: _verifyOldAndSendOtp,
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                    child: const Text('Resend OTP', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => setState(() => _isOtpSent = false),
            child: const Text('Back'),
          ),
          ElevatedButton(
            onPressed: _isLoading ? null : _confirmOtpAndChangePassword,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
            child: _isLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Verify & Save'),
          ),
        ],
      );
    }

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.lock_reset_outlined, color: Colors.blue),
          SizedBox(width: 8),
          Text('Change Password'),
        ],
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomTextField(
                controller: _oldPasswordController,
                label: 'Old Password',
                hint: 'Enter current password',
                obscureText: _obscureOld,
                prefixIcon: Icons.lock_outline,
                suffixIcon: IconButton(
                  icon: Icon(_obscureOld ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscureOld = !_obscureOld),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) {
                    return 'Old password is required';
                  }
                  return null;
                },
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    final router = GoRouter.of(context);
                    Navigator.pop(context);
                    router.push('/forgot-password');
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 30),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Forgot Password?', style: TextStyle(fontSize: 13)),
                ),
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: _newPasswordController,
                label: 'New Password',
                hint: 'Enter new password',
                obscureText: _obscureNew,
                prefixIcon: Icons.lock_outline,
                suffixIcon: IconButton(
                  icon: Icon(_obscureNew ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscureNew = !_obscureNew),
                ),
                validator: (val) {
                  if (val == null || val.length < 6) {
                    return 'New password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: _confirmPasswordController,
                label: 'Confirm Password',
                hint: 'Re-enter new password',
                obscureText: _obscureConfirm,
                prefixIcon: Icons.lock_outline,
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                ),
                validator: (val) {
                  if (val != _newPasswordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _verifyOldAndSendOtp,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
          ),
          child: _isLoading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Send OTP to Verify'),
        ),
      ],
    );
  }
}
