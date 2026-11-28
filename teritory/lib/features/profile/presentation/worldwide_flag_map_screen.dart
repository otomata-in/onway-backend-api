import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/models/api_flag.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/flag_style_provider.dart';
import '../../../core/theme/teritory_theme.dart';
import '../../../core/widgets/flag/teritory_flag.dart';
import '../../flag/presentation/live_flag_detail_sheet.dart';
import 'map_animation_catalog.dart';
import 'map_animation_settings_screen.dart';

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

class _WorldwideFlagMapScreenState extends State<WorldwideFlagMapScreen>
    with SingleTickerProviderStateMixin {
  static const Duration _resumeDelay = Duration(seconds: 3);

  late final MapController _mapController;
  late final Ticker _tourTicker;
  final ValueNotifier<double> _pulsePhase = ValueNotifier<double>(0.0);
  final ValueNotifier<double> _cloudVeilOpacity = ValueNotifier<double>(0.0);
  final MapTourEngine _tourEngine = MapTourEngine();

  late bool _isOceanic;
  late bool _isLandscape;
  bool _isExiting = false;

  Duration _lastTick = Duration.zero;
  bool _isMapReady = false;
  bool _isUserPlaying = true;
  bool _isTemporarilyPaused = false;
  Timer? _resumeTimer;
  String? _spotlightFlagId;
  MapAnimationSettings _animSettings = const MapAnimationSettings();

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _isOceanic = widget.initialOceanic;
    _isLandscape = widget.startInLandscape;
    _tourTicker = createTicker(_onTick)..start();
    _loadAnimationSettings();

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

  Future<void> _loadAnimationSettings() async {
    final loaded = await MapAnimationSettings.load();
    if (!mounted) return;
    setState(() {
      _animSettings = loaded;
      _isUserPlaying = loaded.autoStart;
    });
  }

  void _togglePlayPause() {
    HapticFeedback.lightImpact();
    _resumeTimer?.cancel();
    setState(() {
      _isUserPlaying = !_isUserPlaying;
      _isTemporarilyPaused = false;
      if (_isUserPlaying && _isMapReady) {
        _tourEngine.resetFromCamera(_mapController.camera);
      }
    });
  }

  Future<void> _openAnimationStudio() async {
    HapticFeedback.mediumImpact();
    _pauseTemporarily();
    final updated = await Navigator.of(context).push<MapAnimationSettings>(
      MaterialPageRoute(
        builder: (_) => MapAnimationSettingsScreen(
          initialSettings: _animSettings,
        ),
      ),
    );
    if (!mounted) return;
    if (updated != null) {
      setState(() {
        _animSettings = updated;
        _isUserPlaying = true;
        _isTemporarilyPaused = false;
        if (_isMapReady) {
          _tourEngine.resetFromCamera(_mapController.camera);
        }
      });
    } else {
      _scheduleResume();
    }
  }

  void _pauseTemporarily() {
    _resumeTimer?.cancel();
    _isTemporarilyPaused = true;
  }

  void _scheduleResume() {
    _resumeTimer?.cancel();
    _resumeTimer = Timer(_resumeDelay, () {
      if (mounted) {
        if (_isMapReady) {
          _tourEngine.resetFromCamera(_mapController.camera);
        }
        _isTemporarilyPaused = false;
      }
    });
  }

  void _movePreset(LatLng center, double zoom) {
    _pauseTemporarily();
    _mapController.moveAndRotate(center, zoom, 0.0);
    _scheduleResume();
  }

  void _onTick(Duration elapsed) {
    if (_lastTick == Duration.zero) {
      _lastTick = elapsed;
      return;
    }
    final dt = ((elapsed - _lastTick).inMicroseconds / 1000000.0)
        .clamp(0.0, 0.1);
    _lastTick = elapsed;

    if (!mounted) return;

    _pulsePhase.value = (elapsed.inMilliseconds % 1400) / 1400.0;

    if (!_isMapReady || !_isUserPlaying || _isTemporarilyPaused || dt <= 0) {
      return;
    }

    final size = MediaQuery.sizeOf(context);
    final step = _tourEngine.tick(
      camera: _mapController.camera,
      flags: widget.flags,
      settings: _animSettings,
      dt: dt,
      halfCanvasW: (size.width * 0.46).clamp(160.0, 420.0),
      halfCanvasH: (size.height * 0.40).clamp(140.0, 360.0),
    );

    if (step.spotlightFlagId != _spotlightFlagId) {
      setState(() => _spotlightFlagId = step.spotlightFlagId);
    }
    _cloudVeilOpacity.value = step.cloudVeilOpacity;

    _mapController.moveAndRotate(
      LatLng(step.lat, step.lng),
      step.zoom,
      step.rotation,
    );
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
    _resumeTimer?.cancel();
    _tourTicker.dispose();
    _pulsePhase.dispose();
    _cloudVeilOpacity.dispose();
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
    final trailColor =
        _isOceanic ? const Color(0xFF38BDF8) : TeritoryColors.primary;
    final spotlightFlag = _spotlightFlagId == null
        ? null
        : widget.flags.cast<ApiFlag?>().firstWhere(
              (f) => f?.id == _spotlightFlagId,
              orElse: () => null,
            );

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
            Listener(
              onPointerDown: (_) => _pauseTemporarily(),
              onPointerUp: (_) => _scheduleResume(),
              onPointerCancel: (_) => _scheduleResume(),
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: const LatLng(25.0, 35.0),
                  initialZoom: 2.2,
                  minZoom: 1.4,
                  maxZoom: 16.0,
                  onMapReady: () => _isMapReady = true,
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
                      final isSpotlight = flag.id == _spotlightFlagId;
                      final double w = flag.isMajorFlag ? 44 : 36;
                      final double h = flag.isMajorFlag ? 56 : 46;
                      final double poleOffset = w * (1 - 0.15);
                      return Marker(
                        point: flag.coordinates,
                        width: w + poleOffset + (isSpotlight ? 18 : 0),
                        height: h + 10,
                        alignment: Alignment.topCenter,
                        child: GestureDetector(
                          onTap: () =>
                              LiveFlagDetailSheet.show(context, flag: flag),
                          child: Stack(
                            alignment: Alignment.bottomCenter,
                            clipBehavior: Clip.none,
                            children: [
                              if (isSpotlight)
                                Positioned(
                                  bottom: -4,
                                  child: SpotlightBeaconRing(
                                    pulsePhase: _pulsePhase,
                                    color: flag.isMajorFlag
                                        ? TeritoryColors.majorGold
                                        : trailColor,
                                  ),
                                ),
                              FlagTerrainBase(
                                accentColor: flag.isMajorFlag
                                    ? TeritoryColors.majorGold
                                    : TeritoryColors.primary,
                                isMajor: flag.isMajorFlag,
                                width: flag.isMajorFlag ? 32 : 24,
                              ),
                              Padding(
                                padding: EdgeInsets.only(
                                  left: poleOffset,
                                  bottom: flag.isMajorFlag ? 8.5 : 6,
                                ),
                                child: context.findAncestorWidgetOfExactType<
                                            UncontrolledProviderScope>() !=
                                        null
                                    ? Consumer(
                                        builder: (ctx, ref, _) {
                                          final myId =
                                              ref.watch(currentUserProvider).id;
                                          final myStyle =
                                              ref.watch(flagStyleProvider);
                                          return FlagPinFlag(
                                            style: flag.effectiveStyle(
                                              myId,
                                              myStyle,
                                            ),
                                            width: w,
                                            height: h,
                                            showPole: true,
                                            isMajor: flag.isMajorFlag,
                                          );
                                        },
                                      )
                                    : FlagPinFlag(
                                        style: flag.flagStyle,
                                        width: w,
                                        height: h,
                                        showPole: true,
                                        isMajor: flag.isMajorFlag,
                                      ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            // Clash-style white scouting cloud veil during zoom-out transitions.
            Positioned.fill(
              child: IgnorePointer(
                child: ValueListenableBuilder<double>(
                  valueListenable: _cloudVeilOpacity,
                  builder: (context, opacity, _) {
                    if (opacity <= 0.01) return const SizedBox.shrink();
                    return DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment.center,
                          radius: 1.05,
                          colors: [
                            Colors.white.withValues(alpha: (opacity * 0.92).clamp(0.0, 1.0)),
                            Colors.white.withValues(alpha: opacity.clamp(0.0, 1.0)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            if (spotlightFlag != null)
              Positioned(
                bottom: 72,
                left: 14,
                child: SafeArea(
                  child: GestureDetector(
                    onTap: () =>
                        LiveFlagDetailSheet.show(context, flag: spotlightFlag),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 280),
                      child: Container(
                        key: ValueKey(spotlightFlag.id),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFF0F172A).withValues(alpha: 0.86),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: (spotlightFlag.isMajorFlag
                                    ? TeritoryColors.majorGold
                                    : trailColor)
                                .withValues(alpha: 0.6),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.22),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: spotlightFlag.isMajorFlag
                                    ? TeritoryColors.majorGold
                                    : trailColor,
                              ),
                            ),
                            const SizedBox(width: 7),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 240),
                              child: Text(
                                spotlightFlag.country.isNotEmpty
                                    ? '${spotlightFlag.placeName} • ${spotlightFlag.country}'
                                    : spotlightFlag.placeName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
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

            // Bottom presets toolbar + inline Odyssey Ship button
            Positioned(
              bottom: 14,
              left: 12,
              right: 12,
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
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
                                onTap: () =>
                                    _movePreset(const LatLng(25, 35), 1.8),
                              ),
                              _presetChip(
                                label: '🇮🇳 Asia / India',
                                onTap: () =>
                                    _movePreset(const LatLng(20, 78), 4.2),
                              ),
                              _presetChip(
                                label: '🇪🇺 Europe',
                                onTap: () =>
                                    _movePreset(const LatLng(48, 12), 4.0),
                              ),
                              _presetChip(
                                label: '🇦🇪 Middle East',
                                onTap: () =>
                                    _movePreset(const LatLng(25, 55), 5.0),
                              ),
                              _presetChip(
                                label: '🌎 Americas',
                                onTap: () =>
                                    _movePreset(const LatLng(20, -85), 3.0),
                              ),
                              _presetChip(
                                label: '🇦🇺 Oceania',
                                onTap: () =>
                                    _movePreset(const LatLng(-25, 135), 3.5),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OdysseyShipButton(
                      size: 38,
                      isPlaying: _isUserPlaying && !_isTemporarilyPaused,
                      pulsePhase: _pulsePhase,
                      accentColor: _animSettings.transition.accentColor,
                      onTap: _togglePlayPause,
                      onLongPress: _openAnimationStudio,
                    ),
                  ],
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

