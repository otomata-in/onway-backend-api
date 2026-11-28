import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/models/api_flag.dart';

/// Available camera transition styles for the Profile Worldwide Flag Map tour.
enum MapTourTransition {
  odysseySwoop(
    id: 'odyssey_swoop',
    title: 'Odyssey Swoop',
    subtitle: 'Zooms out to the globe, swoops across, and dives onto each flag.',
    badge: 'Signature',
    icon: Icons.sailing_rounded,
    accentColor: Color(0xFF0EA5E9),
    cycleSeconds: 3.0,
  ),
  horizonSail(
    id: 'horizon_sail',
    title: 'Horizon Sail',
    subtitle: 'Continuous eastward globe glide that steers smoothly to each flag.',
    badge: 'Classic',
    icon: Icons.public_rounded,
    accentColor: Color(0xFF38BDF8),
    cycleSeconds: 3.4,
  ),
  eagleDive(
    id: 'eagle_dive',
    title: 'Eagle Dive',
    subtitle: 'High-altitude soar followed by a crisp, rapid dive onto the target.',
    badge: 'Speedy',
    icon: Icons.flight_land_rounded,
    accentColor: Color(0xFFF59E0B),
    cycleSeconds: 2.5,
  ),
  compassOrbit(
    id: 'compass_orbit',
    title: 'Compass Orbit',
    subtitle: 'Banks gently with a compass heading tilt as it locks onto each spot.',
    badge: 'Cinematic',
    icon: Icons.explore_rounded,
    accentColor: Color(0xFF8B5CF6),
    cycleSeconds: 3.4,
  ),
  islandHop(
    id: 'island_hop',
    title: 'Island Hop',
    subtitle: 'Brisk mid-altitude hops from flag to flag with a crisp bounce lock.',
    badge: 'Rhythmic',
    icon: Icons.waves_rounded,
    accentColor: Color(0xFF10B981),
    cycleSeconds: 2.6,
  ),
  polarArc(
    id: 'polar_arc',
    title: 'Polar Arc',
    subtitle: 'Great-circle style curved trajectory arching gracefully between flags.',
    badge: 'Scenic',
    icon: Icons.flight_takeoff_rounded,
    accentColor: Color(0xFFEC4899),
    cycleSeconds: 3.2,
  ),
  chronoWarp(
    id: 'chrono_warp',
    title: 'Chrono Warp',
    subtitle: 'Hyper-fast zoom burst across continents with instant flag lock-on.',
    badge: 'Turbo',
    icon: Icons.bolt_rounded,
    accentColor: Color(0xFFF97316),
    cycleSeconds: 2.1,
  ),
  beaconDrift(
    id: 'beacon_drift',
    title: 'Beacon Drift',
    subtitle: 'Calm, meditative float with a gentle breathing zoom over each flag.',
    badge: 'Ambient',
    icon: Icons.flare_rounded,
    accentColor: Color(0xFF14B8A6),
    cycleSeconds: 3.8,
  );

  const MapTourTransition({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.icon,
    required this.accentColor,
    required this.cycleSeconds,
  });

  final String id;
  final String title;
  final String subtitle;
  final String badge;
  final IconData icon;
  final Color accentColor;
  final double cycleSeconds;

  static MapTourTransition fromId(String? id) {
    return MapTourTransition.values.firstWhere(
      (t) => t.id == id,
      orElse: () => MapTourTransition.odysseySwoop,
    );
  }
}

/// Persisted user customization for the profile map animation.
class MapAnimationSettings {
  const MapAnimationSettings({
    this.transition = MapTourTransition.odysseySwoop,
    this.speedMultiplier = 1.0,
    this.autoStart = true,
  });

  final MapTourTransition transition;
  final double speedMultiplier;
  final bool autoStart;

  static const _kTransitionKey = 'teritory_profile_map_transition';
  static const _kSpeedKey = 'teritory_profile_map_speed';
  static const _kAutoStartKey = 'teritory_profile_map_autostart';

  MapAnimationSettings copyWith({
    MapTourTransition? transition,
    double? speedMultiplier,
    bool? autoStart,
  }) {
    return MapAnimationSettings(
      transition: transition ?? this.transition,
      speedMultiplier: speedMultiplier ?? this.speedMultiplier,
      autoStart: autoStart ?? this.autoStart,
    );
  }

  static Future<MapAnimationSettings> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final transition =
          MapTourTransition.fromId(prefs.getString(_kTransitionKey));
      final speed = (prefs.getDouble(_kSpeedKey) ?? 1.0).clamp(0.5, 2.0);
      final autoStart = prefs.getBool(_kAutoStartKey) ?? true;
      return MapAnimationSettings(
        transition: transition,
        speedMultiplier: speed,
        autoStart: autoStart,
      );
    } catch (_) {
      return const MapAnimationSettings();
    }
  }

  Future<void> save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kTransitionKey, transition.id);
      await prefs.setDouble(_kSpeedKey, speedMultiplier);
      await prefs.setBool(_kAutoStartKey, autoStart);
    } catch (_) {
      // Ignore persistence failures on restricted storage.
    }
  }
}

/// Clean, exact circular map-tour control button.
/// Tap to play/pause the tour; long-press to open the customization studio.
class OdysseyShipButton extends StatelessWidget {
  const OdysseyShipButton({
    super.key,
    required this.isPlaying,
    required this.pulsePhase,
    required this.accentColor,
    required this.onTap,
    required this.onLongPress,
    this.size = 36,
  });

  final bool isPlaying;
  final ValueNotifier<double> pulsePhase;
  final Color accentColor;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: isPlaying
          ? 'Tap: Pause tour • Hold: Customize'
          : 'Tap: Play tour • Hold: Customize',
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: ValueListenableBuilder<double>(
          valueListenable: pulsePhase,
          builder: (context, phase, _) {
            return SizedBox(
              width: size,
              height: size,
              child: CustomPaint(
                painter: _CircularTourRingPainter(
                  phase: phase,
                  isPlaying: isPlaying,
                  accentColor: accentColor,
                ),
                child: Container(
                  margin: const EdgeInsets.all(2.5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isPlaying
                        ? const Color(0xFF0F172A)
                        : Colors.white.withValues(alpha: 0.96),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.16),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      transitionBuilder: (child, anim) =>
                          ScaleTransition(scale: anim, child: child),
                      child: Icon(
                        isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        key: ValueKey(isPlaying),
                        size: size * 0.54,
                        color: isPlaying
                            ? Colors.white
                            : const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CircularTourRingPainter extends CustomPainter {
  const _CircularTourRingPainter({
    required this.phase,
    required this.isPlaying,
    required this.accentColor,
  });

  final double phase;
  final bool isPlaying;
  final Color accentColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 1.2;

    // Subtle static track around the exact circle.
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = isPlaying
            ? accentColor.withValues(alpha: 0.25)
            : Colors.black.withValues(alpha: 0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    if (!isPlaying) return;

    // Smooth orbiting arc indicating active auto-tour playback.
    final startAngle = (phase * 2 * math.pi) - (math.pi / 2);
    const sweepAngle = math.pi * 0.75;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      Paint()
        ..color = accentColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _CircularTourRingPainter oldDelegate) {
    return oldDelegate.phase != phase ||
        oldDelegate.isPlaying != isPlaying ||
        oldDelegate.accentColor != accentColor;
  }
}

/// Animated radar beacon ring rendered beneath the currently spotlighted flag.
class SpotlightBeaconRing extends StatelessWidget {
  const SpotlightBeaconRing({
    super.key,
    required this.pulsePhase,
    required this.color,
  });

  final ValueNotifier<double> pulsePhase;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: pulsePhase,
      builder: (context, phase, _) {
        final ringSize = 26.0 + (phase * 28.0);
        final ringOpacity = (1.0 - phase).clamp(0.0, 1.0) * 0.65;
        return Container(
          width: ringSize,
          height: ringSize * 0.52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(ringSize),
            border: Border.all(
              color: color.withValues(alpha: ringOpacity),
              width: 2.2,
            ),
            color: color.withValues(alpha: ringOpacity * 0.25),
          ),
        );
      },
    );
  }
}

/// Output frame produced by [MapTourEngine.tick].
class MapTourStep {
  const MapTourStep({
    required this.lat,
    required this.lng,
    required this.zoom,
    required this.rotation,
    required this.spotlightFlagId,
    this.cloudVeilOpacity = 0.0,
  });

  final double lat;
  final double lng;
  final double zoom;
  final double rotation;
  final String? spotlightFlagId;
  final double cloudVeilOpacity;
}

/// Shared camera animation engine powering both the Profile mini-map and
/// the Full-View [WorldwideFlagMapScreen].
class MapTourEngine {
  static const double _emptyScrollDegPerSec = 10.0;
  static const double _overviewZoom = 1.8;

  int _tourIndex = 0;
  double _cycleElapsed = 0.0;
  double _startLat = 30.0;
  double _startLng = 50.0;
  double _startZoom = 2.2;
  bool _tourInitialized = false;

  void resetFromCamera(MapCamera camera) {
    _startLat = camera.center.latitude;
    _startLng = camera.center.longitude;
    _startZoom = camera.zoom;
    _cycleElapsed = 0.0;
  }

  static double wrapLng(double lng) {
    var v = lng;
    while (v >= 180.0) {
      v -= 360.0;
    }
    while (v < -180.0) {
      v += 360.0;
    }
    return v;
  }

  static double shortestDeltaLng(double fromLng, double toLng) {
    var d = toLng - fromLng;
    while (d > 180.0) {
      d -= 360.0;
    }
    while (d < -180.0) {
      d += 360.0;
    }
    return d;
  }

  static double _zoomOutCloud(double phaseProgress) {
    // Reach full white cloud cover by 50% of zoom-out so it lingers cleanly.
    final p = (phaseProgress / 0.50).clamp(0.0, 1.0);
    return Curves.easeOutCubic.transform(p);
  }

  static double _zoomInCloud(double phaseProgress) {
    // Hold full white briefly into the swoop, then part clouds smoothly up to 80%.
    final p = ((phaseProgress - 0.15) / 0.65).clamp(0.0, 1.0);
    return 1.0 - Curves.easeInOutCubic.transform(p);
  }

  static double computeFocusZoom(
    ApiFlag target,
    List<ApiFlag> allFlags, {
    double halfCanvasW = 195.0,
    double halfCanvasH = 150.0,
  }) {
    final baseZoom = target.isMajorFlag ? 6.2 : 5.5;
    if (allFlags.length <= 1) return baseZoom;

    const double pxPerDegAtZ0 = 256.0 / 360.0;
    const double maxTourZoom = 14.5;

    final targetLat = target.coordinates.latitude;
    final targetLng = target.coordinates.longitude;
    final cosLat = math.cos(targetLat * math.pi / 180.0).abs().clamp(0.2, 1.0);

    double requiredZoom = baseZoom;
    for (final other in allFlags) {
      if (other.id == target.id) continue;
      final dxDeg = shortestDeltaLng(targetLng, other.coordinates.longitude).abs();
      final dyDeg = (other.coordinates.latitude - targetLat).abs();

      if (dxDeg < 0.0002 && dyDeg < 0.0002) {
        requiredZoom = maxTourZoom;
        continue;
      }

      double zoomX = maxTourZoom;
      if (dxDeg > 0) {
        final pow2X = halfCanvasW / (dxDeg * pxPerDegAtZ0);
        zoomX = pow2X <= 1.0 ? 0.0 : math.log(pow2X) / math.ln2;
      }

      double zoomY = maxTourZoom;
      if (dyDeg > 0) {
        final pow2Y = halfCanvasH / ((dyDeg * pxPerDegAtZ0) / cosLat);
        zoomY = pow2Y <= 1.0 ? 0.0 : math.log(pow2Y) / math.ln2;
      }

      final clearNeighborZoom = math.min(zoomX, zoomY);
      if (clearNeighborZoom > requiredZoom) {
        requiredZoom = clearNeighborZoom;
      }
    }

    return requiredZoom.clamp(baseZoom, maxTourZoom);
  }

  static double computeBridgeZoom(
    ApiFlag from,
    ApiFlag to,
    double focusZoom, {
    double usableHalfW = 120.0,
    double usableHalfH = 82.0,
  }) {
    if (from.id == to.id) return _overviewZoom;

    const double pxPerDegAtZ0 = 256.0 / 360.0;

    final halfDx =
        shortestDeltaLng(from.coordinates.longitude, to.coordinates.longitude)
                .abs() /
            2.0;
    final halfDy =
        (to.coordinates.latitude - from.coordinates.latitude).abs() / 2.0;
    final midLat = (from.coordinates.latitude + to.coordinates.latitude) / 2.0;
    final cosLat = math.cos(midLat * math.pi / 180.0).abs().clamp(0.2, 1.0);

    double zoomX = 13.5;
    if (halfDx > 0.0001) {
      final pow2X = usableHalfW / (halfDx * pxPerDegAtZ0);
      zoomX = pow2X <= 0.01 ? 1.5 : math.log(pow2X) / math.ln2;
    }

    double zoomY = 13.5;
    if (halfDy > 0.0001) {
      final pow2Y = usableHalfH / ((halfDy * pxPerDegAtZ0) / cosLat);
      zoomY = pow2Y <= 0.01 ? 1.5 : math.log(pow2Y) / math.ln2;
    }

    final fitZoom = math.min(zoomX, zoomY);
    final upper = (focusZoom - 0.8).clamp(1.8, 13.5);
    return fitZoom.clamp(1.6, upper);
  }

  MapTourStep tick({
    required MapCamera camera,
    required List<ApiFlag> flags,
    required MapAnimationSettings settings,
    required double dt,
    double halfCanvasW = 195.0,
    double halfCanvasH = 150.0,
  }) {
    final speed = settings.speedMultiplier;

    if (flags.isEmpty) {
      final nextLng =
          wrapLng(camera.center.longitude + _emptyScrollDegPerSec * speed * dt);
      return MapTourStep(
        lat: camera.center.latitude,
        lng: nextLng,
        zoom: camera.zoom,
        rotation: 0.0,
        spotlightFlagId: null,
      );
    }

    final sortedFlags = [...flags]
      ..sort((a, b) => a.coordinates.longitude.compareTo(b.coordinates.longitude));

    if (settings.transition == MapTourTransition.horizonSail) {
      return _tickHorizonSail(
        camera,
        sortedFlags,
        dt,
        speed,
        halfCanvasW: halfCanvasW,
        halfCanvasH: halfCanvasH,
      );
    }

    if (!_tourInitialized) {
      _tourInitialized = true;
      resetFromCamera(camera);
      _tourIndex = 0;
    }

    if (_tourIndex >= sortedFlags.length) {
      _tourIndex = 0;
    }

    final cycleDuration =
        (settings.transition.cycleSeconds / speed).clamp(1.0, 8.0);
    _cycleElapsed += dt;
    if (_cycleElapsed >= cycleDuration) {
      _cycleElapsed -= cycleDuration;
      _tourIndex = (_tourIndex + 1) % sortedFlags.length;
      resetFromCamera(camera);
    }

    final targetFlag = sortedFlags[_tourIndex];
    final nextFlag = sortedFlags[(_tourIndex + 1) % sortedFlags.length];
    final targetLat = targetFlag.coordinates.latitude.clamp(-65.0, 75.0);
    final targetLng = targetFlag.coordinates.longitude;
    final focusZoom = computeFocusZoom(
      targetFlag,
      sortedFlags,
      halfCanvasW: halfCanvasW,
      halfCanvasH: halfCanvasH,
    );
    final bridgeZoom = computeBridgeZoom(
      targetFlag,
      nextFlag,
      focusZoom,
      usableHalfW: halfCanvasW * 0.62,
      usableHalfH: halfCanvasH * 0.55,
    );
    final nextTargetLat = nextFlag.coordinates.latitude.clamp(-65.0, 75.0);
    final nextTargetLng = nextFlag.coordinates.longitude;
    final midLat = ((targetLat + nextTargetLat) / 2.0).clamp(-65.0, 75.0);
    final midLng = wrapLng(
      targetLng + shortestDeltaLng(targetLng, nextTargetLng) * 0.5,
    );

    final u = (_cycleElapsed / cycleDuration).clamp(0.0, 1.0);
    double nextLat = targetLat;
    double nextLng = targetLng;
    double nextZoom = focusZoom;
    double nextRotation = 0.0;
    double cloudVeil = 0.0;
    String? nextSpotlightId;

    switch (settings.transition) {
      case MapTourTransition.eagleDive:
        if (u < 0.44) {
          final raw = u / 0.44;
          final p = Curves.easeOutExpo.transform(raw);
          nextLat = _startLat + (targetLat - _startLat) * p;
          nextLng = wrapLng(
              _startLng + shortestDeltaLng(_startLng, targetLng) * p);
          nextZoom = _startZoom + (focusZoom - _startZoom) * p;
          cloudVeil = _zoomInCloud(raw);
          if (p > 0.5) nextSpotlightId = targetFlag.id;
        } else if (u < 0.72) {
          nextSpotlightId = targetFlag.id;
        } else {
          final raw = (u - 0.72) / 0.28;
          final p = Curves.easeInExpo.transform(raw);
          nextLat = targetLat + (midLat - targetLat) * p;
          nextLng = wrapLng(
              targetLng + shortestDeltaLng(targetLng, midLng) * p);
          nextZoom = focusZoom + (bridgeZoom - focusZoom) * p;
          cloudVeil = _zoomOutCloud(raw);
          if (p < 0.35) nextSpotlightId = targetFlag.id;
        }
        break;

      case MapTourTransition.compassOrbit:
        if (u < 0.42) {
          final raw = u / 0.42;
          final p = Curves.easeInOutCubic.transform(raw);
          final arcLat = math.sin(math.pi * p) * 6.0;
          nextLat = _startLat + (targetLat - _startLat) * p + arcLat;
          nextLng = wrapLng(
              _startLng + shortestDeltaLng(_startLng, targetLng) * p);
          nextZoom = _startZoom + (focusZoom - _startZoom) * p;
          nextRotation = math.sin(math.pi * raw) * 14.0;
          cloudVeil = _zoomInCloud(raw);
          if (p > 0.55) nextSpotlightId = targetFlag.id;
        } else if (u < 0.70) {
          nextSpotlightId = targetFlag.id;
        } else {
          final raw = (u - 0.70) / 0.30;
          final p = Curves.easeInOutCubic.transform(raw);
          nextLat = targetLat + (midLat - targetLat) * p;
          nextLng = wrapLng(
              targetLng + shortestDeltaLng(targetLng, midLng) * p);
          nextZoom = focusZoom + (bridgeZoom - focusZoom) * p;
          nextRotation = -math.sin(math.pi * p) * 10.0;
          cloudVeil = _zoomOutCloud(raw);
          if (p < 0.35) nextSpotlightId = targetFlag.id;
        }
        break;

      case MapTourTransition.islandHop:
        if (u < 0.46) {
          final raw = u / 0.46;
          final p = Curves.easeOutCubic.transform(raw);
          final zBounce = Curves.easeOutBack.transform(raw).clamp(0.0, 1.08);
          nextLat = _startLat + (targetLat - _startLat) * p;
          nextLng = wrapLng(
              _startLng + shortestDeltaLng(_startLng, targetLng) * p);
          nextZoom = _startZoom + (focusZoom - _startZoom) * zBounce;
          cloudVeil = _zoomInCloud(raw);
          if (p > 0.5) nextSpotlightId = targetFlag.id;
        } else if (u < 0.72) {
          nextSpotlightId = targetFlag.id;
        } else {
          final raw = (u - 0.72) / 0.28;
          final p = Curves.easeInOutCubic.transform(raw);
          nextLat = targetLat + (midLat - targetLat) * p;
          nextLng = wrapLng(
              targetLng + shortestDeltaLng(targetLng, midLng) * p);
          nextZoom = focusZoom + (bridgeZoom - focusZoom) * p;
          cloudVeil = _zoomOutCloud(raw);
          if (p < 0.35) nextSpotlightId = targetFlag.id;
        }
        break;

      case MapTourTransition.polarArc:
        if (u < 0.44) {
          final raw = u / 0.44;
          final p = Curves.easeInOutCubic.transform(raw);
          final poleSign = targetLat >= 0 ? 1.0 : -1.0;
          final arcOffset = math.sin(math.pi * p) * 14.0 * poleSign;
          nextLat = _startLat + (targetLat - _startLat) * p + arcOffset;
          nextLng = wrapLng(
              _startLng + shortestDeltaLng(_startLng, targetLng) * p);
          nextZoom = _startZoom + (focusZoom - _startZoom) * p;
          cloudVeil = _zoomInCloud(raw);
          if (p > 0.55) nextSpotlightId = targetFlag.id;
        } else if (u < 0.68) {
          nextSpotlightId = targetFlag.id;
        } else {
          final raw = (u - 0.68) / 0.32;
          final p = Curves.easeInOutCubic.transform(raw);
          nextLat = targetLat + (midLat - targetLat) * p;
          nextLng = wrapLng(
              targetLng + shortestDeltaLng(targetLng, midLng) * p);
          nextZoom = focusZoom + (bridgeZoom - focusZoom) * p;
          cloudVeil = _zoomOutCloud(raw);
          if (p < 0.35) nextSpotlightId = targetFlag.id;
        }
        break;

      case MapTourTransition.chronoWarp:
        if (u < 0.36) {
          final raw = u / 0.36;
          final p = Curves.easeInOutExpo.transform(raw);
          nextLat = _startLat + (targetLat - _startLat) * p;
          nextLng = wrapLng(
              _startLng + shortestDeltaLng(_startLng, targetLng) * p);
          nextZoom = _startZoom + (focusZoom - _startZoom) * p;
          cloudVeil = _zoomInCloud(raw);
          if (p > 0.55) nextSpotlightId = targetFlag.id;
        } else if (u < 0.66) {
          nextSpotlightId = targetFlag.id;
        } else {
          final raw = (u - 0.66) / 0.34;
          final p = Curves.easeInOutExpo.transform(raw);
          nextLat = targetLat + (midLat - targetLat) * p;
          nextLng = wrapLng(
              targetLng + shortestDeltaLng(targetLng, midLng) * p);
          nextZoom = focusZoom + (bridgeZoom - focusZoom) * p;
          cloudVeil = _zoomOutCloud(raw);
          if (p < 0.3) nextSpotlightId = targetFlag.id;
        }
        break;

      case MapTourTransition.beaconDrift:
        if (u < 0.38) {
          final raw = u / 0.38;
          final p = Curves.easeInOutSine.transform(raw);
          nextLat = _startLat + (targetLat - _startLat) * p;
          nextLng = wrapLng(
              _startLng + shortestDeltaLng(_startLng, targetLng) * p);
          nextZoom = _startZoom + (focusZoom - _startZoom) * p;
          cloudVeil = _zoomInCloud(raw);
          if (p > 0.5) nextSpotlightId = targetFlag.id;
        } else if (u < 0.74) {
          final holdP = (u - 0.38) / 0.36;
          nextZoom = focusZoom + math.sin(holdP * 2 * math.pi) * 0.35;
          nextSpotlightId = targetFlag.id;
        } else {
          final raw = (u - 0.74) / 0.26;
          final p = Curves.easeInOutSine.transform(raw);
          nextLat = targetLat + (midLat - targetLat) * p;
          nextLng = wrapLng(
              targetLng + shortestDeltaLng(targetLng, midLng) * p);
          nextZoom = focusZoom + (bridgeZoom - focusZoom) * p;
          cloudVeil = _zoomOutCloud(raw);
          if (p < 0.35) nextSpotlightId = targetFlag.id;
        }
        break;

      case MapTourTransition.odysseySwoop:
      case MapTourTransition.horizonSail:
        if (u < 0.40) {
          final raw = u / 0.40;
          final p = Curves.easeInOutCubic.transform(raw);
          nextLat = _startLat + (targetLat - _startLat) * p;
          nextLng = wrapLng(
              _startLng + shortestDeltaLng(_startLng, targetLng) * p);
          nextZoom = _startZoom + (focusZoom - _startZoom) * p;
          cloudVeil = _zoomInCloud(raw);
          if (p > 0.55) nextSpotlightId = targetFlag.id;
        } else if (u < 0.68) {
          nextSpotlightId = targetFlag.id;
        } else {
          final raw = (u - 0.68) / 0.32;
          final p = Curves.easeInOutCubic.transform(raw);
          nextLat = targetLat + (midLat - targetLat) * p;
          nextLng = wrapLng(
              targetLng + shortestDeltaLng(targetLng, midLng) * p);
          nextZoom = focusZoom + (bridgeZoom - focusZoom) * p;
          cloudVeil = _zoomOutCloud(raw);
          if (p < 0.35) nextSpotlightId = targetFlag.id;
        }
        break;
    }

    return MapTourStep(
      lat: nextLat.clamp(-65.0, 75.0),
      lng: nextLng,
      zoom: nextZoom.clamp(1.5, 14.5),
      rotation: nextRotation,
      spotlightFlagId: nextSpotlightId,
      cloudVeilOpacity: cloudVeil.clamp(0.0, 1.0),
    );
  }

  MapTourStep _tickHorizonSail(
    MapCamera camera,
    List<ApiFlag> flags,
    double dt,
    double speed, {
    required double halfCanvasW,
    required double halfCanvasH,
  }) {
    final zoomBoost = (camera.zoom / 2.2).clamp(0.8, 2.5);
    final currentLng = camera.center.longitude;

    ApiFlag? upcomingFlag;
    ApiFlag? closestFlag;
    double minAhead = double.infinity;
    double minDist = double.infinity;

    for (final flag in flags) {
      double ahead = flag.coordinates.longitude - currentLng;
      if (ahead <= 0) ahead += 360.0;
      if (ahead < minAhead) {
        minAhead = ahead;
        upcomingFlag = flag;
      }
      final dist = shortestDeltaLng(currentLng, flag.coordinates.longitude).abs();
      if (dist < minDist) {
        minDist = dist;
        closestFlag = flag;
      }
    }

    final proximitySlowdown = minDist < 10.0
        ? (0.45 + 0.55 * (minDist / 10.0)).clamp(0.45, 1.0)
        : 1.0;

    final nextLng = wrapLng(
      currentLng + 12.5 * speed * zoomBoost * proximitySlowdown * dt,
    );

    double nextLat = camera.center.latitude;
    double nextZoom = camera.zoom;
    if (upcomingFlag != null) {
      final targetLat = upcomingFlag.coordinates.latitude.clamp(-65.0, 75.0);
      final focusZoom = computeFocusZoom(
        upcomingFlag,
        flags,
        halfCanvasW: halfCanvasW,
        halfCanvasH: halfCanvasH,
      );
      final bridgeZoom = computeBridgeZoom(
        closestFlag ?? upcomingFlag,
        upcomingFlag,
        focusZoom,
        usableHalfW: halfCanvasW * 0.62,
        usableHalfH: halfCanvasH * 0.55,
      );
      final targetZoom = minDist < 15.0 ? focusZoom : bridgeZoom;
      final t = (1.0 - math.exp(-2.0 * zoomBoost * speed * dt)).clamp(0.0, 1.0);
      nextLat = (nextLat + (targetLat - nextLat) * t).clamp(-65.0, 75.0);
      nextZoom = (nextZoom + (targetZoom - nextZoom) * t).clamp(1.5, 14.5);
    }

    final nextSpotlightId =
        (closestFlag != null && minDist <= 25.0) ? closestFlag.id : null;

    return MapTourStep(
      lat: nextLat,
      lng: nextLng,
      zoom: nextZoom,
      rotation: 0.0,
      spotlightFlagId: nextSpotlightId,
    );
  }
}

