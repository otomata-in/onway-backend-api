import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/teritory_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
          ),
          _buildSettingsTile(
            context,
            icon: Icons.alternate_email_rounded,
            title: 'Change Handle',
          ),
          _buildSettingsTile(
            context,
            icon: Icons.mail_outline_rounded,
            title: 'Email / Phone',
          ),

          // ── Preferences ──
          _buildSectionHeader('Preferences'),
          _buildSettingsTile(
            context,
            icon: Icons.map_outlined,
            title: 'Map Theme Default',
          ),
          _buildSettingsTile(
            context,
            icon: Icons.notifications_none_rounded,
            title: 'Notification Settings',
          ),
          _buildSettingsTile(
            context,
            icon: Icons.lock_outline_rounded,
            title: 'Privacy',
          ),

          // ── App ──
          _buildSectionHeader('App'),
          _buildSettingsTile(
            context,
            icon: Icons.info_outline_rounded,
            title: 'About Teritory',
            subtitle: 'Your Map. Your Crew.',
          ),
          _buildSettingsTile(
            context,
            icon: Icons.description_outlined,
            title: 'Terms of Service',
          ),
          _buildSettingsTile(
            context,
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
          ),
          _buildSettingsTile(
            context,
            icon: Icons.build_outlined,
            title: 'Version 2.0.0',
          ),

          // ── Danger Zone ──
          _buildSectionHeader('Danger Zone'),
          _buildSettingsTile(
            context,
            icon: Icons.logout_rounded,
            title: 'Log Out',
            isDanger: true,
          ),
          _buildSettingsTile(
            context,
            icon: Icons.delete_forever_rounded,
            title: 'Delete Account',
            isDanger: true,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
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
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: TeritoryColors.textSecondary,
              ),
            )
          : null,
      trailing: Icon(
        Icons.chevron_right_rounded,
        size: 20,
        color: isDanger ? TeritoryColors.expiredRed : TeritoryColors.textMuted,
      ),
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Coming soon')),
        );
      },
    );
  }
}
