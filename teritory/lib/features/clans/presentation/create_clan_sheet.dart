import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/models/clan_models.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/teritory_theme.dart';
import '../application/clans_provider.dart';

/// Founds a clan with `POST /v1/clans` and returns it so the caller can open it.
class CreateClanSheet extends ConsumerStatefulWidget {
  const CreateClanSheet({super.key});

  static Future<Clan?> show(BuildContext context) {
    return showModalBottomSheet<Clan>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CreateClanSheet(),
    );
  }

  @override
  ConsumerState<CreateClanSheet> createState() => _CreateClanSheetState();
}

class _CreateClanSheetState extends ConsumerState<CreateClanSheet> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _regionController = TextEditingController();
  final _coverController = TextEditingController();

  static const List<String> _interestTags = [
    'trekking',
    'camping',
    'heritage',
    'culture',
    'road_trip',
    'wildlife',
    'international',
  ];

  String? _interestTag;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _regionController.dispose();
    _coverController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;

    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _toast('Give your clan a name first.', error: true);
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isSubmitting = true);

    try {
      final clan = await ref.read(clansProvider.notifier).createClan(
            name: name,
            description: _descriptionController.text.trim(),
            region: _regionController.text.trim(),
            interestTag: _interestTag ?? '',
            coverImageUrl: _coverController.text.trim().isEmpty
                ? null
                : _coverController.text.trim(),
          );
      if (!mounted) return;
      Navigator.pop(context, clan);
      messenger.showSnackBar(
        SnackBar(
          content: Text('Clan founded: ${clan.name}'),
          backgroundColor: TeritoryColors.primary,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _toast(e.message, error: true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _toast('Could not reach Teritory. Check your connection.', error: true);
    }
  }

  void _toast(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? TeritoryColors.expiredRed : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Found a Clan',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: TeritoryColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'You become the chieftain of every clan you create.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: TeritoryColors.textSecondary,
              ),
            ),
            const SizedBox(height: 18),
            _field(_nameController, 'Clan name'),
            const SizedBox(height: 12),
            _field(_descriptionController, 'What is this clan about?',
                maxLines: 2),
            const SizedBox(height: 12),
            _field(_regionController, 'Region (e.g. Kerala, India)'),
            const SizedBox(height: 16),
            Text(
              'Interest',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: TeritoryColors.textMuted,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _interestTags.map((tag) {
                final selected = _interestTag == tag;
                return GestureDetector(
                  onTap: () => setState(
                      () => _interestTag = selected ? null : tag),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: selected
                          ? TeritoryColors.clanPurple
                          : TeritoryColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      tag.replaceAll('_', ' '),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: selected
                            ? Colors.white
                            : TeritoryColors.textSecondary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            _field(_coverController, 'Cover image URL (optional)'),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: TeritoryColors.clanPurple,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Found Clan',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController controller, String hint,
      {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        color: TeritoryColors.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          color: TeritoryColors.textMuted,
        ),
        filled: true,
        fillColor: TeritoryColors.surfaceContainer,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}
