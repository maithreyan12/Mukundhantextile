import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/constants.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../shared/widgets/premium_button.dart';
import '../../../shared/widgets/cached_image.dart';
import '../../../core/theme_cubit.dart';
import '../bloc/auth_cubit.dart';
import '../bloc/auth_state.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          BlocBuilder<ThemeCubit, ThemeMode>(
            builder: (context, themeMode) {
              return IconButton(
                icon: Icon(
                  themeMode == ThemeMode.dark
                      ? Icons.light_mode_rounded
                      : Icons.dark_mode_rounded,
                ),
                onPressed: () => context.read<ThemeCubit>().toggleTheme(),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          if (state is! AuthAuthenticated) {
            return const Center(child: CircularProgressIndicator());
          }

          final profile = state.profile;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
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
                    color: const Color(0xFFEAEAEA),
                  ),
                const SizedBox(height: 16),
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
            backgroundColor: const Color(0xFFEAEAEA),
            onPressed: () {
              context
                  .read<AuthCubit>()
                  .updateProfile({'name': nameController.text.trim()});
              Navigator.pop(ctx);
            },
            child: const Text('SAVE', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}
