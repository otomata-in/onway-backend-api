import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/models/api_flag.dart';
import '../../../core/theme/teritory_theme.dart';
import '../../../core/widgets/flag/teritory_flag.dart';
import '../../flag/presentation/live_flag_detail_sheet.dart';

/// Full-screen interactive Worldwide Flag Map with dynamic landscape/portrait
/// rotation support and Daylight / Oceanic theme switching.
class WorldwideFlagMapScreen extends StatefulWidget {
  const WorldwideFlagMapScreen({
    super.key,
    required this.flags,
    required this.startInLandscape,
    this.initialOceanic = false,
  });

  final List<ApiFlag> flags;
  final bool startInLandscape;
  final bool initialOceanic;

  @override
  State<WorldwideFlagMapScreen> createState() => _WorldwideFlagMapScreenState();
}

class _WorldwideFlagMapScreenState extends State<WorldwideFlagMapScreen> {
  late final MapController _mapController;
  late bool _isOceanic;
  late bool _isLandscape;
  bool _isExiting = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _isOceanic = widget.initialOceanic;
    _isLandscape = widget.startInLandscape;

    if (_isLandscape) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
    }
  }

  void _toggleOrientation() {
    setState(() => _isLandscape = !_isLandscape);
    if (_isLandscape) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
    }
  }

  Future<void> _restorePortraitAndExit() async {
    if (_isExiting) return;
    _isExiting = true;

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final majorCount = widget.flags.where((f) => f.isMajorFlag).length;
    final continents = widget.flags.map((f) => f.continent).toSet().length;

    return PopScope(
      canPop: _isExiting,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _restorePortraitAndExit();
        }
      },
      child: Scaffold(
        backgroundColor:
            _isOceanic ? const Color(0xFF0B1120) : const Color(0xFFF1F5F9),
        body: Stack(
          children: [
            // Map canvas
            FlutterMap(
              mapController: _mapController,
              options: const MapOptions(
                initialCenter: LatLng(25.0, 35.0),
                initialZoom: 2.2,
                minZoom: 1.4,
                maxZoom: 16.0,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.onway.teritory',
                  tileBuilder: _isOceanic
                      ? (context, tileWidget, tile) => ColorFiltered(
                            colorFilter: const ColorFilter.matrix(<double>[
                              -0.20, -0.15, -0.30, 0.0, 140,
                              -0.45,  0.20, -0.35, 0.0, 165,
                              -0.55,  0.05, -0.05, 0.0, 185,
                               0.0,   0.0,   0.0,  1.0, 0,
                            ]),
                            child: tileWidget,
                          )
                      : null, // Default Daylight
                ),
                MarkerLayer(
                  markers: widget.flags.map((flag) {
                    return Marker(
                      point: flag.coordinates,
                      width: 48,
                      height: 34,
                      child: GestureDetector(
                        onTap: () =>
                            LiveFlagDetailSheet.show(context, flag: flag),
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(9),
                            border: Border.all(
                              color: flag.isMajorFlag
                                  ? TeritoryColors.majorGold
                                  : TeritoryColors.primary,
                              width: 1.8,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: TeritoryFlag(
                              style: flag.flagStyle,
                              width: 40,
                              showPole: false,
                              isMajor: flag.isMajorFlag,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),

            if (widget.flags.isEmpty)
              Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'No flags dropped yet',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: TeritoryColors.textSecondary,
                    ),
                  ),
                ),
              ),

            // Top control bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      // Back / Exit button: isolated from FittedBox with guaranteed 44x44 touch target
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _restorePortraitAndExit,
                          borderRadius: BorderRadius.circular(22),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.94),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.16),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.arrow_back_ios_new_rounded,
                                size: 18,
                                color: TeritoryColors.textPrimary,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Rest of header controls scale cleanly without shrinking back button
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Row(
                            children: [
                              // Title & Stats Badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 7),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.94),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.12),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.public_rounded,
                                      size: 16,
                                      color: TeritoryColors.primary,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${widget.flags.length} Spots • $continents Continents',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: TeritoryColors.textPrimary,
                                      ),
                                    ),
                                    if (majorCount > 0) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: TeritoryColors.majorGold
                                              .withValues(alpha: 0.18),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          '⭐ $majorCount Major',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFFB45309),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),

                              const SizedBox(width: 10),

                              // Rotate View Toggle
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: _toggleOrientation,
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.94),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.15),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      _isLandscape
                                          ? Icons.stay_current_portrait_rounded
                                          : Icons.screen_rotation_rounded,
                                      size: 18,
                                      color: TeritoryColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Theme Pill (Daylight / Oceanic)
                              Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.94),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.15),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _themeButton(
                                      label: '☀️ Daylight',
                                      isSelected: !_isOceanic,
                                      activeColor: const Color(0xFFF59E0B),
                                      onTap: () =>
                                          setState(() => _isOceanic = false),
                                    ),
                                    _themeButton(
                                      label: '🌊 Oceanic',
                                      isSelected: _isOceanic,
                                      activeColor: const Color(0xFF38BDF8),
                                      onTap: () =>
                                          setState(() => _isOceanic = true),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom presets toolbar
            Positioned(
              bottom: 14,
              left: 12,
              right: 12,
              child: SafeArea(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.94),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.16),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _presetChip(
                            label: '🌍 World',
                            onTap: () => _mapController.move(
                                const LatLng(25, 35), 1.8),
                          ),
                          _presetChip(
                            label: '🇮🇳 Asia / India',
                            onTap: () => _mapController.move(
                                const LatLng(20, 78), 4.2),
                          ),
                          _presetChip(
                            label: '🇪🇺 Europe',
                            onTap: () => _mapController.move(
                                const LatLng(48, 12), 4.0),
                          ),
                          _presetChip(
                            label: '🇦🇪 Middle East',
                            onTap: () => _mapController.move(
                                const LatLng(25, 55), 5.0),
                          ),
                          _presetChip(
                            label: '🌎 Americas',
                            onTap: () => _mapController.move(
                                const LatLng(20, -85), 3.0),
                          ),
                          _presetChip(
                            label: '🇦🇺 Oceania',
                            onTap: () => _mapController.move(
                                const LatLng(-25, 135), 3.5),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _themeButton({
    required String label,
    required bool isSelected,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F172A) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? activeColor : TeritoryColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _presetChip({required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: TeritoryColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

