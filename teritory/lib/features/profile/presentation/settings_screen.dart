import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/config/app_config.dart';
import '../../../core/models/api_user.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/preferences_provider.dart';
import '../../../core/theme/teritory_theme.dart';
import '../application/profile_providers.dart';
import 'edit_profile_sheet.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(myProfileProvider).valueOrNull;
    final isDarkMap = ref.watch(mapThemeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: ListView(
        children: [
          // ── Account ──
          _buildSectionHeader('Account'),
          _buildSettingsTile(
            context,
            icon: Icons.person_outline_rounded,
            title: 'Edit Profile',
            subtitle: profile == null
                ? 'Loading your profile…'
                : '${profile.displayName} · @${profile.handle}',
            onTap: profile == null
                ? null
                : () => _openEditProfile(context, ref, profile),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.alternate_email_rounded,
            title: 'Change Handle',
            subtitle: profile == null ? '@…' : '@${profile.handle}',
            onTap: () => _showGap(
              context,
              'Handles are permanent for now: the profile endpoint accepts '
              'display name, bio, avatar and location, but not the handle.',
            ),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.mail_outline_rounded,
            title: 'Email / Phone',
            subtitle: profile == null || profile.phone.isEmpty
                ? 'Not available'
                : profile.phone,
            onTap: () => _showGap(
              context,
              'Your phone number is your sign-in identity, so it cannot be '
              'changed in-app yet.',
            ),
          ),

          // ── Preferences ──
          _buildSectionHeader('Preferences'),
          _buildSettingsTile(
            context,
            icon: Icons.map_outlined,
            title: 'Map Theme Default',
            subtitle: isDarkMap ? 'Midnight Oceanic' : 'Daylight White',
            onTap: () => _pickMapTheme(context, ref),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.notifications_none_rounded,
            title: 'Notification Settings',
            subtitle: 'Saved on this device',
            onTap: () => _openNotificationSettings(context, ref),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.lock_outline_rounded,
            title: 'Privacy',
            subtitle: profile == null
                ? 'Loading…'
                : (profile.isPrivate
                    ? 'Private profile'
                    : 'Visible to other travelers'),
            onTap: profile == null
                ? null
                : () => EditProfileSheet.show(context, profile),
          ),

          // ── App ──
          _buildSectionHeader('App'),
          _buildSettingsTile(
            context,
            icon: Icons.info_outline_rounded,
            title: 'About Teritory',
            subtitle: 'Your Map. Your Crew.',
            onTap: () => context.go('/profile/settings/about'),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.description_outlined,
            title: 'Terms of Service',
            onTap: () => context.go('/profile/settings/terms'),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            onTap: () => context.go('/profile/settings/privacy'),
          ),
          ListTile(
            leading: const Icon(
              Icons.build_outlined,
              size: 22,
              color: TeritoryColors.textSecondary,
            ),
            title: Text(
              'Version ${AppConfig.appVersion}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: TeritoryColors.textPrimary,
              ),
            ),
          ),

          // ── Danger Zone ──
          _buildSectionHeader('Danger Zone'),
          _buildSettingsTile(
            context,
            icon: Icons.logout_rounded,
            title: 'Log Out',
            isDanger: true,
            onTap: () => _confirmSignOut(context, ref),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.delete_forever_rounded,
            title: 'Delete Account',
            subtitle: 'Needs a backend endpoint',
            isDanger: true,
            showChevron: false,
            onTap: () => showDialog<void>(
              context: context,
              builder: (dialogContext) => AlertDialog(
                title: const Text('Delete account'),
                content: const Text(
                  'Account deletion needs a backend endpoint that does not '
                  'exist yet, so this stays disabled. Contact '
                  'support@teritory.app to remove your account and data.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Future<void> _openEditProfile(
    BuildContext context,
    WidgetRef ref,
    ApiUser profile,
  ) async {
    final saved = await EditProfileSheet.show(context, profile);
    if (saved == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated')),
      );
    }
  }

  void _showGap(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pickMapTheme(BuildContext context, WidgetRef ref) async {
    final selected = await showModalBottomSheet<bool>(
      context: context,
      builder: (sheetContext) {
        final isDark = ref.watch(mapThemeProvider);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.water_drop_rounded,
                    color: TeritoryColors.sapphireBlue),
                title: const Text('Midnight Oceanic'),
                subtitle: const Text('Dark map with blue accents'),
                trailing: isDark
                    ? const Icon(Icons.check_rounded,
                        color: TeritoryColors.primary)
                    : null,
                onTap: () => Navigator.of(sheetContext).pop(true),
              ),
              ListTile(
                leading: const Icon(Icons.light_mode_rounded,
                    color: TeritoryColors.majorGold),
                title: const Text('Daylight White'),
                subtitle: const Text('Light map for daytime use'),
                trailing: !isDark
                    ? const Icon(Icons.check_rounded,
                        color: TeritoryColors.primary)
                    : null,
                onTap: () => Navigator.of(sheetContext).pop(false),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (selected == null) return;
    await ref.read(mapThemeProvider.notifier).setDark(selected);
  }

  Future<void> _openNotificationSettings(
    BuildContext context,
    WidgetRef ref,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        final prefs = ref.watch(notificationPreferencesProvider);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notifications',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: TeritoryColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Stored on this device. The backend has no notification '
                  'preferences endpoint yet, so these switches are not synced.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    height: 1.4,
                    color: TeritoryColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                for (final entry in const [
                  ('friendRequests', 'Friend requests', 'Someone adds you'),
                  ('clanActivity', 'Clan activity', 'Members join or leave'),
                  ('tripUpdates', 'Trip updates', 'Waypoint and plan changes'),
                ])
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      entry.$2,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: TeritoryColors.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      entry.$3,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: TeritoryColors.textSecondary,
                      ),
                    ),
                    value: prefs[entry.$1] ?? true,
                    activeThumbColor: TeritoryColors.primary,
                    onChanged: (value) => ref
                        .read(notificationPreferencesProvider.notifier)
                        .setEnabled(entry.$1, value),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Revokes the refresh token and returns to the login route through the
  /// router redirect (no manual navigation needed).
  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text(
          'You will need your phone number and a fresh code to sign back in.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;
    await ref.read(authStatusProvider.notifier).signOut();
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1,
          color: TeritoryColors.textMuted,
        ),
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    bool isDanger = false,
    bool showChevron = true,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        size: 22,
        color: isDanger ? TeritoryColors.expiredRed : TeritoryColors.textSecondary,
      ),
      title: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: isDanger ? TeritoryColors.expiredRed : TeritoryColors.textPrimary,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: TeritoryColors.textSecondary,
              ),
            )
          : null,
      trailing: showChevron
          ? Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: isDanger ? TeritoryColors.expiredRed : TeritoryColors.textMuted,
            )
          : null,
      onTap: onTap ??
          () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Coming soon')),
            );
          },
    );
  }
}
