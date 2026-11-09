import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/services/teritory_data_service.dart';
import '../../../core/theme/teritory_theme.dart';

class DropFlagModal extends StatefulWidget {
  final LatLng initialCoordinates;
  final String suggestedPlaceName;

  const DropFlagModal({
    super.key,
    required this.initialCoordinates,
    this.suggestedPlaceName = 'Current Location',
  });

  static Future<void> show(
    BuildContext context, {
    required LatLng coordinates,
    String suggestedPlaceName = 'Current Location',
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DropFlagModal(
        initialCoordinates: coordinates,
        suggestedPlaceName: suggestedPlaceName,
      ),
    );
  }

  @override
  State<DropFlagModal> createState() => _DropFlagModalState();
}

class _DropFlagModalState extends State<DropFlagModal> {
  late TextEditingController _placeController;
  late TextEditingController _cityController;
  late TextEditingController _notesController;
  bool _isMajorFlag = false;
  String _selectedCategory = 'Scenic Viewpoint';

  final List<String> _categories = [
    'Scenic Viewpoint',
    'UNESCO Heritage',
    'Mountain Peak',
    'Coastal Heritage',
    'Local Food & Café',
    'Hidden Gem',
    'Camp & Stay',
  ];

  @override
  void initState() {
    super.initState();
    _placeController = TextEditingController(text: widget.suggestedPlaceName);
    _cityController = TextEditingController(text: 'Kochi, Kerala');
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _placeController.dispose();
    _cityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submitFlag() {
    final name = _placeController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a location name')),
      );
      return;
    }

    final city = _cityController.text.trim().isNotEmpty
        ? _cityController.text.trim()
        : 'Kerala';

    TeritoryDataService.instance.addFlag(
      placeName: name,
      city: city,
      country: 'India',
      coordinates: widget.initialCoordinates,
      isMajorFlag: _isMajorFlag,
      category: _selectedCategory,
      notes: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : 'Claimed this spot on my journey! 🚩',
    );

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: TeritoryColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _isMajorFlag
                    ? '🎉 Major Flag Unlocked! +150 XP'
                    : '🚩 Territory Flag Staked! +50 XP',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
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
            // Drag handle
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
            const SizedBox(height: 16),

            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: TeritoryColors.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.flag_rounded,
                    color: TeritoryColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Stake Your Flag',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: TeritoryColors.textPrimary,
                        ),
                      ),
                      Text(
                        'GPS: ${widget.initialCoordinates.latitude.toStringAsFixed(4)}°, ${widget.initialCoordinates.longitude.toStringAsFixed(4)}°',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: TeritoryColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Major Flag Switch Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _isMajorFlag
                    ? TeritoryColors.majorGoldLight
                    : TeritoryColors.surfaceContainer,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isMajorFlag
                      ? TeritoryColors.majorGold
                      : TeritoryColors.border,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isMajorFlag
                        ? Icons.military_tech_rounded
                        : Icons.outlined_flag_rounded,
                    color: _isMajorFlag
                        ? TeritoryColors.majorGoldDark
                        : TeritoryColors.textSecondary,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mark as Major Landmark / Wonder',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: _isMajorFlag
                                ? TeritoryColors.majorGoldDark
                                : TeritoryColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Featured in global wonder counters & trophy shelf',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: TeritoryColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: _isMajorFlag,
                    activeThumbColor: TeritoryColors.majorGoldDark,
                    activeTrackColor: TeritoryColors.majorGold,
                    onChanged: (val) {
                      setState(() {
                        _isMajorFlag = val;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Place Name Field
            Text(
              'Location / Spot Name',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: TeritoryColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _placeController,
              decoration: InputDecoration(
                hintText: 'e.g. Fort Kochi Promenade, Mattancherry',
                filled: true,
                fillColor: TeritoryColors.surfaceContainer,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(Icons.location_on_rounded,
                    color: TeritoryColors.primary),
              ),
            ),
            const SizedBox(height: 14),

            // City / Region Field
            Text(
              'City / Region',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: TeritoryColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _cityController,
              decoration: InputDecoration(
                hintText: 'e.g. Kochi, Kerala, India',
                filled: true,
                fillColor: TeritoryColors.surfaceContainer,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(Icons.apartment_rounded,
                    color: TeritoryColors.textSecondary),
              ),
            ),
            const SizedBox(height: 14),

            // Category Selector
            Text(
              'Category',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: TeritoryColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _categories.map((cat) {
                  final isSelected = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(cat),
                      selected: isSelected,
                      selectedColor: TeritoryColors.primaryLight,
                      labelStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected
                            ? TeritoryColors.primary
                            : TeritoryColors.textSecondary,
                      ),
                      side: BorderSide(
                        color: isSelected
                            ? TeritoryColors.primary
                            : TeritoryColors.border,
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedCategory = cat;
                          });
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 14),

            // Travel Memory / Story Note
            Text(
              'Travel Memory / Traveler Tip',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: TeritoryColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _notesController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'What made this spot unforgettable? Any secret tip?',
                filled: true,
                fillColor: TeritoryColors.surfaceContainer,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _submitFlag,
                icon: const Icon(Icons.flag_rounded, color: Colors.white),
                label: Text(
                  'Claim & Stake Flag',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isMajorFlag
                      ? TeritoryColors.majorGoldDark
                      : TeritoryColors.primary,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
