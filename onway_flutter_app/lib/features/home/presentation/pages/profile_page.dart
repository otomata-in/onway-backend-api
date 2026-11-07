import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/standard_top_bar.dart';
import '../bloc/home_bloc.dart';
import '../bloc/home_event.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _api = BuyerApiService();
  bool _isLoading = true;
  String _name = 'User';
  String _email = '';
  String _phone = '';
  String? _selectedAvatarPath;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final res = await _api.getProfile();
      if (mounted) {
        if (res['success'] == true && res['data'] != null) {
          final profile = res['data'];
          setState(() {
            _name = profile['fullName'] ?? 'User';
            _email = profile['email'] ?? '';
            _phone = profile['user']?['phone'] ?? '';
            _selectedAvatarPath = profile['avatarUrl'];
            _isLoading = false;
          });
        } else {
          setState(() => _isLoading = false);
        }
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showEditProfileBottomSheet() {
    final nameController = TextEditingController(text: _name);
    final emailController = TextEditingController(text: _email);
    final phoneController = TextEditingController(text: _phone);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Edit Profile Details',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.onSurface,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.outline),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Full Name',
                prefixIcon: const Icon(Icons.person_outline, color: AppColors.primary),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: 'Email Address',
                prefixIcon: const Icon(Icons.email_outlined, color: AppColors.primary),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              readOnly: true,
              enabled: false,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.outline),
                suffixIcon: const Icon(Icons.lock_outline, color: AppColors.outline, size: 18),
                helperText: 'Phone number linked to account cannot be changed',
                helperStyle: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.outline),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: AppColors.surfaceContainerHigh.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  final newName = nameController.text.trim();
                  final newEmail = emailController.text.trim();
                  
                  if (newName.isEmpty) {
                    _showToast('Name cannot be empty');
                    return;
                  }

                  Navigator.pop(ctx);
                  
                  setState(() => _isLoading = true);

                  final res = await _api.updateProfile(fullName: newName, email: newEmail);
                  if (res['success'] == true) {
                    _showToast('Profile details saved to database!');
                  } else {
                    _showToast(res['message'] ?? 'Failed to update profile');
                  }
                  await _loadProfile();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Text(
                  'Save Changes',
                  style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPhotoUpdateBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Update Profile Photo',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.onSurface,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.outline),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.camera_alt_outlined, color: AppColors.primary),
              ),
              title: Text('Take Photo', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(ctx);
                _showToast('Camera opened (Demo Mode)');
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
              ),
              title: Text('Choose from Gallery', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(ctx);
                _showToast('Gallery opened (Demo Mode)');
              },
            ),
            const Divider(height: 24),
            Text(
              'Select Avatar Preset',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.outline,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildAvatarOption('assets/images/vendor_green_valley.png', 'Green'),
                _buildAvatarOption('assets/images/stitch_saved_vendor_1.png', 'Baker'),
                _buildAvatarOption('assets/images/stitch_saved_vendor_2.png', 'Chef'),
                _buildAvatarOption('assets/images/vendor_ocean_catch.png', 'Fisher'),
              ],
            ),
            if (_selectedAvatarPath != null) ...[
              const Divider(height: 24),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFEE2E2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.delete_outline, color: Color(0xFFDC2626)),
                ),
                title: Text('Remove Photo', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: const Color(0xFFDC2626))),
                onTap: () {
                  setState(() => _selectedAvatarPath = null);
                  Navigator.pop(ctx);
                  _api.uploadAvatar('');
                  _showToast('Profile photo removed');
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarOption(String path, String label) {
    final isSelected = _selectedAvatarPath == path;
    return GestureDetector(
      onTap: () async {
        Navigator.pop(context);
        setState(() => _isLoading = true);
        final res = await _api.uploadAvatar(path);
        if (res['success'] == true) {
          _showToast('Profile photo saved to database!');
        } else {
          _showToast('Failed to save photo to database');
        }
        await _loadProfile();
      },
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.surfaceContainerHigh,
                width: isSelected ? 3 : 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: Image.asset(path, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? AppColors.primary : AppColors.outline,
            ),
          ),
        ],
      ),
    );
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
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
                StandardTopBar(
                  title: 'Profile',
                  subtitle: 'Manage your account details',
                  icon: Icons.person_outline,
                  onBackTap: () {
                    context.read<HomeBloc>().add(const HomeNavIndexChanged(0));
                  },
                  onIconTap: () {
                    _showEditProfileBottomSheet();
                  },
                ),
                
                SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: 32),
                    
                    Center(
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: _showPhotoUpdateBottomSheet,
                            child: Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                Container(
                                  width: 128,
                                  height: 128,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 4),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.1),
                                        blurRadius: 20,
                                      ),
                                    ],
                                    color: AppColors.surfaceContainerHigh,
                                  ),
                                  child: _selectedAvatarPath != null && _selectedAvatarPath!.isNotEmpty
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(999),
                                          child: Image.asset(
                                            _selectedAvatarPath!,
                                            fit: BoxFit.cover,
                                            errorBuilder: (c, e, s) => const Icon(Icons.person, size: 64, color: AppColors.outlineVariant),
                                          ),
                                        )
                                      : const Icon(Icons.person, size: 64, color: AppColors.outlineVariant),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.1),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(Icons.photo_camera, size: 18, color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _name,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppColors.onSurface,
                            ),
                          ),
                          if (_email.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              _email,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                          if (_phone.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              _phone,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                color: AppColors.outline,
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _showEditProfileBottomSheet,
                            icon: const Icon(Icons.edit, size: 18),
                            label: Text('Edit Profile', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                              elevation: 4,
                              shadowColor: AppColors.primary.withValues(alpha: 0.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          _buildSettingsGroup(
                            title: 'Account',
                            items: [
                              _buildSettingItem(Icons.person_outline, 'Profile details', onTap: _showEditProfileBottomSheet),
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

  Widget _buildSettingItem(IconData icon, String title, {VoidCallback? onTap, bool hasToggle = false, bool toggleValue = false, String? trailingText}) {
    return InkWell(
      onTap: onTap ?? () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
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
                onChanged: (val) {},
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
