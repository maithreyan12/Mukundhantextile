import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/utils/responsive_helper.dart';
import '../../../core/constants.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../shared/widgets/premium_button.dart';
import '../../../shared/widgets/cached_image.dart';
import '../bloc/auth_cubit.dart';
import '../bloc/auth_state.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          if (state is! AuthAuthenticated) {
            return const Center(child: CircularProgressIndicator());
          }

          final profile = state.profile;
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: SingleChildScrollView(
            padding: EdgeInsets.all(Responsive.horizontalPadding(context)),
            child: Column(
              children: [
                // Avatar
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: context.isDarkMode ? Colors.white10 : Colors.black12,
                      child: profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty
                          ? ClipOval(
                              child: CachedImage(
                                imageUrl: profile.avatarUrl,
                                width: 80,
                                height: 80,
                              ),
                            )
                          : Text(
                              profile.name.isNotEmpty ? profile.name[0].toUpperCase() : 'U',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                color: context.isDarkMode ? Colors.white : Colors.black,
                              ),
                            ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(profile.name.toUpperCase(), style: context.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900)),
                          const SizedBox(height: 4),
                          Text(profile.email, style: context.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade500)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 48),

                // Menu Items
                _menuItem(
                  context,
                  icon: Icons.person_outline,
                  title: 'Edit Profile',
                  onTap: () => _showEditProfileDialog(context, profile.name),
                ),
                _menuItem(
                  context,
                  icon: Icons.location_on_outlined,
                  title: 'My Addresses',
                  onTap: () => context.push('/address-form'),
                ),
                _menuItem(
                  context,
                  icon: Icons.receipt_long_outlined,
                  title: 'My Orders',
                  onTap: () => context.push('/orders'),
                ),
                _menuItem(
                  context,
                  icon: Icons.favorite_border,
                  title: 'Wishlist',
                  onTap: () => context.go('/wishlist'),
                ),
                _menuItem(
                  context,
                  icon: Icons.notifications_none_rounded,
                  title: 'Notifications',
                  onTap: () => context.push('/notifications'),
                ),
                if (profile.isAdmin || profile.email == AppConstants.adminEmail)
                  _menuItem(
                    context,
                    icon: Icons.admin_panel_settings_outlined,
                    title: 'Admin Dashboard',
                    onTap: () => context.push('/admin'),
                    color: Theme.of(context).colorScheme.primary,
                  ),
                const SizedBox(height: 16),

                // ── Contact & About ───────────────────
                _menuItem(
                  context,
                  icon: Icons.phone_outlined,
                  title: 'Call Us — ${AppConstants.contactPhone}',
                  onTap: () async {
                    final uri = Uri.parse('tel:${AppConstants.contactPhone.replaceAll(' ', '')}');
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri);
                    }
                  },
                ),
                _menuItem(
                  context,
                  icon: Icons.location_on_outlined,
                  title: 'Visit Store',
                  onTap: () => _showStoreInfoSheet(context),
                ),
                _menuItem(
                  context,
                  icon: Icons.info_outline,
                  title: 'About Mukundhan Tex & Readymades',
                  onTap: () => _showAboutSheet(context),
                ),

                const SizedBox(height: 32),
                PremiumButton(
                  onPressed: () => context.read<AuthCubit>().signOut(),
                  backgroundColor: context.isDarkMode ? const Color(0xFF1A1A1A) : Colors.grey.shade100,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout, color: Color(0xFFFF6B6B)),
                      SizedBox(width: 8),
                      Text('SIGN OUT', style: TextStyle(color: Color(0xFFFF6B6B), fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ),
          );
        },
      ),
    );
  }

  Widget _menuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: (color ?? (context.isDarkMode ? Colors.white : Colors.black)).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color ?? (context.isDarkMode ? Colors.white : Colors.black), size: 20),
        ),
        title: Text(title, style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        trailing: const Icon(Icons.chevron_right, size: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: context.isDarkMode ? const Color(0xFF222222) : Colors.grey.shade300, width: 1),
        ),
        tileColor: context.isDarkMode
            ? const Color(0xFF1A1A1A)
            : Colors.white,
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context, String currentName) {
    final nameController = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Profile'),
        content: CustomTextField(
          controller: nameController,
          label: 'Name',
          hint: 'Enter your name',
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
              context
                  .read<AuthCubit>()
                  .updateProfile({'name': nameController.text.trim()});
              Navigator.pop(ctx);
            },
            child: const Text('SAVE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
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
          Text('Mukundhan Tex & Readymades',
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
