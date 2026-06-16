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
                          // Coins Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFC200).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFFFFC200).withValues(alpha: 0.4),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.monetization_on, size: 16, color: Color(0xFFFFC200)),
                                SizedBox(width: 4),
                                Text(
                                  '150',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
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

                    // ── 3. Email Verification Banner Box ─────────────────────
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
                          const Icon(Icons.mail_outline_rounded, size: 28, color: Colors.blue),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Add/Verify your Email',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Get latest updates of your orders',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () => _showEditProfileDialog(context, profile.name, profile.email, profile.phone ?? ''),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            child: const Text('Update', style: TextStyle(fontWeight: FontWeight.bold)),
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

                    // ── 7. Earn with Mugundhan Tex Box ────────────────────────
                    _sectionHeader('Earn with Mugundhan Tex'),
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
                            icon: Icons.storefront_outlined,
                            title: 'Sell on Mugundhan Tex',
                            onTap: () => context.showSnackBar('Seller registration opening soon!'),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ── 8. Feedback & Information Box ─────────────────────────
                    _sectionHeader('Feedback & Information'),
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
                            icon: Icons.description_outlined,
                            title: 'Terms, Policies and Licenses',
                            onTap: () => _showAboutSheet(context),
                          ),
                          _settingsTile(
                            context,
                            icon: Icons.help_outline,
                            title: 'Browse FAQs',
                            onTap: () => context.showSnackBar('FAQ section opening soon!'),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

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
    final nameController = TextEditingController(text: currentName);
    final emailController = TextEditingController(text: currentEmail);
    final phoneController = TextEditingController(text: currentPhone);
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Profile'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomTextField(
                controller: nameController,
                label: 'Name',
                hint: 'Enter your name',
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: emailController,
                label: 'Email',
                hint: 'Enter your email',
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: phoneController,
                label: 'Phone number',
                hint: 'Enter your phone number',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          PremiumButton(
            isFullWidth: false,
            backgroundColor: Theme.of(context).colorScheme.primary,
            onPressed: () {
              context.read<AuthCubit>().updateProfile({
                'name': nameController.text.trim(),
                'email': emailController.text.trim(),
                'phone': phoneController.text.trim(),
              });
              Navigator.pop(ctx);
            },
            child: const Text('SAVE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
          ),
        ],
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
