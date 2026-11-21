import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/config/app_config.dart';
import '../../../core/models/api_user.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/teritory_repository.dart';
import '../../../core/theme/teritory_theme.dart';
import '../application/profile_providers.dart';

/// Edits the fields `PATCH /users/me` accepts and the trip-mode flag.
/// Returns `true` after a successful save so the caller can confirm.
class EditProfileSheet extends ConsumerStatefulWidget {
  const EditProfileSheet({super.key, required this.profile});

  final ApiUser profile;

  static Future<bool?> show(BuildContext context, ApiUser profile) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditProfileSheet(profile: profile),
    );
  }

  @override
  ConsumerState<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<EditProfileSheet> {
  late final TextEditingController _displayName;
  late final TextEditingController _bio;
  late final TextEditingController _avatarUrl;
  late final TextEditingController _country;
  late final TextEditingController _state;
  late final TextEditingController _district;

  late bool _isPrivate;
  late bool _isTripMode;

  bool _busy = false;
  bool _uploadingAvatar = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final profile = widget.profile;
    _displayName = TextEditingController(text: profile.displayName);
    _bio = TextEditingController(text: profile.bio);
    _avatarUrl = TextEditingController(text: profile.avatarUrl);
    _country = TextEditingController(text: profile.country);
    _state = TextEditingController(text: profile.state);
    _district = TextEditingController(text: profile.district);
    _isPrivate = profile.isPrivate;
    _isTripMode = profile.isTripMode;
  }

  @override
  void dispose() {
    _displayName.dispose();
    _bio.dispose();
    _avatarUrl.dispose();
    _country.dispose();
    _state.dispose();
    _district.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadAvatar(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (picked == null) return;

      setState(() {
        _uploadingAvatar = true;
        _error = null;
      });

      final url = await TeritoryRepository.instance.uploadImage(picked.path);
      if (!mounted) return;
      setState(() {
        _avatarUrl.text = url;
        _uploadingAvatar = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _uploadingAvatar = false;
        _error = 'Failed to upload photo: $e';
      });
    }
  }

  void _showImageSourcePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: TeritoryColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_rounded, color: TeritoryColors.primary),
              title: Text('Take a photo', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndUploadAvatar(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: TeritoryColors.primary),
              title: Text('Choose from gallery', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndUploadAvatar(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final displayName = _displayName.text.trim();
    if (displayName.length < 2) {
      setState(() => _error = 'Display name needs at least 2 characters');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await TeritoryRepository.instance.updateMyProfile(
        displayName: displayName,
        bio: _bio.text.trim(),
        avatarUrl: _avatarUrl.text.trim(),
        country: _country.text.trim(),
        state: _state.text.trim(),
        district: _district.text.trim(),
        isPrivate: _isPrivate,
      );

      if (_isTripMode != widget.profile.isTripMode) {
        await TeritoryRepository.instance.setTripMode(_isTripMode);
      }

      if (!mounted) return;
      ref.invalidate(myProfileProvider);
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Could not save your profile. Check your connection and retry.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.92,
      ),
      decoration: const BoxDecoration(
        color: TeritoryColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottomInset),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: TeritoryColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Edit profile',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: TeritoryColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Changes are saved to your account and load on every device.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: TeritoryColors.textSecondary,
              ),
            ),
            const SizedBox(height: 18),
            Center(
              child: Stack(
                children: [
                  GestureDetector(
                    onTap: (_busy || _uploadingAvatar) ? null : _showImageSourcePicker,
                    child: Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: TeritoryColors.primary, width: 2),
                        color: TeritoryColors.surfaceContainer,
                      ),
                      child: ClipOval(
                        child: _uploadingAvatar
                            ? const Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : _avatarUrl.text.trim().isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: AppConfig.resolveMediaUrl(
                                      _avatarUrl.text.trim(),
                                    ),
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => const Center(
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      ),
                                    ),
                                    errorWidget: (context, url, error) => const Icon(
                                      Icons.person_rounded,
                                      size: 40,
                                      color: TeritoryColors.textSecondary,
                                    ),
                                  )
                                : const Icon(
                                    Icons.person_rounded,
                                    size: 40,
                                    color: TeritoryColors.textSecondary,
                                  ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: (_busy || _uploadingAvatar) ? null : _showImageSourcePicker,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: TeritoryColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _field(_displayName, 'Display name', 'Arjun Nair'),
            const SizedBox(height: 12),
            _field(_bio, 'Bio', 'Chasing coastlines', maxLines: 3, maxLength: 250),
            const SizedBox(height: 12),
            _field(_avatarUrl, 'Avatar URL', 'https://…', keyboardType: TextInputType.url),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _field(_district, 'District', 'Kochi')),
                const SizedBox(width: 10),
                Expanded(child: _field(_state, 'State', 'Kerala')),
              ],
            ),
            const SizedBox(height: 12),
            _field(_country, 'Country', 'India'),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'Private profile',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: TeritoryColors.textPrimary,
                ),
              ),
              subtitle: Text(
                'Hide your footprint from travelers who are not friends.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: TeritoryColors.textSecondary,
                ),
              ),
              value: _isPrivate,
              activeThumbColor: TeritoryColors.primary,
              onChanged: _busy ? null : (value) => setState(() => _isPrivate = value),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'On a trip',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: TeritoryColors.textPrimary,
                ),
              ),
              subtitle: Text(
                'Shows the “On a trip” badge on Explore and your profile.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: TeritoryColors.textSecondary,
                ),
              ),
              value: _isTripMode,
              activeThumbColor: TeritoryColors.primary,
              onChanged: _busy ? null : (value) => setState(() => _isTripMode = value),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: TeritoryColors.expiredRed,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _busy ? null : () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: TeritoryColors.textPrimary,
                      side: const BorderSide(color: TeritoryColors.border),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _busy ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TeritoryColors.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          TeritoryColors.primary.withValues(alpha: 0.4),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Save',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    String hint, {
    int maxLines = 1,
    int? maxLength,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      enabled: !_busy,
      maxLines: maxLines,
      maxLength: maxLength,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        counterText: '',
        filled: true,
        fillColor: TeritoryColors.surfaceContainer,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: TeritoryColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: TeritoryColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: TeritoryColors.primary, width: 1.6),
        ),
      ),
    );
  }
}
