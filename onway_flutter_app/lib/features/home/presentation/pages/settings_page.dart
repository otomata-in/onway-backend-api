import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/network/api_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/standard_top_bar.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _api = BuyerApiService();
  bool _pushNotifications = true;
  bool _darkMode = false;
  String _language = 'English';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final res = await _api.getPreferences();
      if (res['success'] == true && res['data'] != null) {
        final pref = res['data'];
        if (mounted) {
          setState(() {
            _pushNotifications = pref['pushNotifications'] ?? true;
            _darkMode = pref['darkMode'] ?? false;
            _language = pref['language'] ?? 'English';
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _togglePush(bool val) async {
    setState(() => _pushNotifications = val);
    await _api.updatePreferences(pushNotifications: val);
  }

  Future<void> _toggleDark(bool val) async {
    setState(() => _darkMode = val);
    await _api.updatePreferences(darkMode: val);
  }

  Future<void> _handleLogout() async {
    try {
      await _api.logout();
    } catch (_) {}
    if (mounted) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : CustomScrollView(
              slivers: [
                const StandardTopBar(
                  title: 'Settings',
                  subtitle: 'App preferences & support',
                  icon: Icons.settings_outlined,
                ),
                
                SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: 16),
                    
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          _buildSettingsGroup(
                            title: 'Preferences',
                            items: [
                              _buildSettingItem(
                                Icons.notifications_active,
                                'Push Notifications',
                                hasToggle: true,
                                toggleValue: _pushNotifications,
                                onToggleChanged: _togglePush,
                              ),
                              _buildSettingItem(
                                Icons.dark_mode,
                                'Dark Mode',
                                hasToggle: true,
                                toggleValue: _darkMode,
                                onToggleChanged: _toggleDark,
                              ),
                              _buildSettingItem(
                                Icons.language,
                                'Language',
                                trailingText: _language,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          _buildSettingsGroup(
                            title: 'Support',
                            items: [
                              _buildSettingItem(Icons.help, 'Help Center'),
                              _buildSettingItem(Icons.verified_user, 'Privacy Policy'),
                              _buildSettingItem(Icons.gavel, 'Terms of Service'),
                            ],
                          ),
                          const SizedBox(height: 32),
                          
                          Center(
                            child: OutlinedButton.icon(
                              onPressed: _handleLogout,
                              icon: const Icon(Icons.logout),
                              label: Text('Log Out', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.error,
                                side: BorderSide(color: AppColors.error.withValues(alpha: 0.2)),
                                backgroundColor: AppColors.errorContainer.withValues(alpha: 0.1),
                                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 120),
                        ],
                      ),
                    ),
                  ]),
                ),
              ],
            ),
    );
  }

  Widget _buildSettingsGroup({required String title, required List<Widget> items}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(color: AppColors.onSurface.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(title.toUpperCase(), style: GoogleFonts.plusJakartaSans(
              fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary, letterSpacing: 1.2
            )),
          ),
          ...items,
        ],
      ),
    );
  }

  Widget _buildSettingItem(
    IconData icon,
    String title, {
    bool hasToggle = false,
    bool toggleValue = false,
    ValueChanged<bool>? onToggleChanged,
    String? trailingText,
  }) {
    return InkWell(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(title, style: GoogleFonts.plusJakartaSans(
                fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.onSurface
              )),
            ),
            if (trailingText != null) ...[
              Text(trailingText, style: GoogleFonts.plusJakartaSans(
                fontSize: 12, color: AppColors.onSurfaceVariant
              )),
              const SizedBox(width: 4),
            ],
            if (hasToggle)
              Switch(
                value: toggleValue,
                onChanged: onToggleChanged,
                activeThumbColor: AppColors.primaryContainer,
              )
            else
              const Icon(Icons.chevron_right, color: AppColors.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
