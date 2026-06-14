import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme_cubit.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/utils/responsive_helper.dart';

class ThemeSettingsScreen extends StatelessWidget {
  const ThemeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isLargeScreen(context);
    final colorColumns = isDesktop ? 6 : 4;

    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, themeState) {
        return Scaffold(
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: ListView(
                padding: EdgeInsets.all(Responsive.horizontalPadding(context)),
                children: [
                  // ── Header ────────────────────────────────
                  Text(
                    'Theme Settings',
                    style: context.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Customize the look and feel of your app',
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: context.isDarkMode ? Colors.white60 : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Light / Dark Mode Toggle ──────────────
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: context.isDarkMode
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: context.isDarkMode ? Colors.white10 : Colors.grey.shade200,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Appearance',
                          style: context.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _ModeCard(
                              icon: Icons.light_mode_rounded,
                              label: 'Light',
                              isSelected: themeState.themeMode == ThemeMode.light,
                              onTap: () => context.read<ThemeCubit>().setThemeMode(ThemeMode.light),
                              color: themeState.colorTheme.primary,
                            ),
                            const SizedBox(width: 12),
                            _ModeCard(
                              icon: Icons.dark_mode_rounded,
                              label: 'Dark',
                              isSelected: themeState.themeMode == ThemeMode.dark,
                              onTap: () => context.read<ThemeCubit>().setThemeMode(ThemeMode.dark),
                              color: themeState.colorTheme.primary,
                            ),
                            const SizedBox(width: 12),
                            _ModeCard(
                              icon: Icons.settings_brightness_rounded,
                              label: 'System',
                              isSelected: themeState.themeMode == ThemeMode.system,
                              onTap: () => context.read<ThemeCubit>().setThemeMode(ThemeMode.system),
                              color: themeState.colorTheme.primary,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Color Theme Picker ────────────────────
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: context.isDarkMode
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: context.isDarkMode ? Colors.white10 : Colors.grey.shade200,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Color Theme',
                              style: context.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: themeState.colorTheme.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                themeState.colorTheme.name,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: context.isDarkMode
                                      ? Colors.white
                                      : themeState.colorTheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Dark Themes Section
                        Text('Dark Colors',
                          style: context.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 12),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: 12,
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: colorColumns,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 0.85,
                          ),
                          itemBuilder: (context, index) {
                            final ct = AppColorThemes.all[index];
                            final isSelected = themeState.colorIndex == index;
                            return _ColorThemeCard(
                              colorTheme: ct,
                              isSelected: isSelected,
                              onTap: () => context.read<ThemeCubit>().setColorTheme(index),
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                        // Light Themes Section
                        Text('Light / Bright Colors',
                          style: context.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 12),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: AppColorThemes.all.length - 12,
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: colorColumns,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 0.85,
                          ),
                          itemBuilder: (context, index) {
                            final realIndex = index + 12;
                            final ct = AppColorThemes.all[realIndex];
                            final isSelected = themeState.colorIndex == realIndex;
                            return _ColorThemeCard(
                              colorTheme: ct,
                              isSelected: isSelected,
                              onTap: () => context.read<ThemeCubit>().setColorTheme(realIndex),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Preview ───────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: context.isDarkMode
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: context.isDarkMode ? Colors.white10 : Colors.grey.shade200,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Preview',
                          style: context.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Preview buttons
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {},
                                child: const Text('Primary'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {},
                                child: const Text('Outlined'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Preview accent
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: themeState.colorTheme.accent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Accent Color',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Chips preview
                        Wrap(
                          spacing: 8,
                          children: [
                            Chip(label: Text('Category 1')),
                            Chip(
                              label: const Text('Selected', style: TextStyle(color: Colors.white)),
                              backgroundColor: themeState.colorTheme.primary,
                            ),
                            Chip(label: Text('Category 3')),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ModeCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color color;

  const _ModeCard({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : (context.isDarkMode ? Colors.white12 : Colors.grey.shade300),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? color : (context.isDarkMode ? Colors.white54 : Colors.black45),
                size: 28,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? color : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ColorThemeCard extends StatelessWidget {
  final AppColorTheme colorTheme;
  final bool isSelected;
  final VoidCallback onTap;

  const _ColorThemeCard({
    required this.colorTheme,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? colorTheme.primary : Colors.transparent,
            width: 2.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Color circle with accent dot
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [colorTheme.primary, colorTheme.primaryLight],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: colorTheme.primary.withValues(alpha: 0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : [],
                  ),
                  child: isSelected
                      ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
                      : null,
                ),
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: colorTheme.accent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: context.isDarkMode ? Colors.black : Colors.white,
                      width: 2,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              colorTheme.name,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? (context.isDarkMode ? Colors.white : colorTheme.primary)
                    : null,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
