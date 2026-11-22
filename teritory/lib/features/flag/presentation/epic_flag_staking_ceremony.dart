import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart' hide Path;

import '../../../core/theme/teritory_theme.dart';

/// Full-screen signature cinematic animation that plays when an explorer
/// stakes a flag into the earth. Features:
/// - Downward spear plunge & violent ground impact
/// - Hard-effort secondary muscular shove driving the staff deep into the bedrock
/// - Screen camera shake & haptic feedback on impact
/// - Expanding ground shockwaves, fissures, and radial spark/dust particles
/// - Glowing territorial compass rose burning into the earth
/// - Procedural cloth wind simulation as the flag unfurls
/// - Conquest telemetry stamp and merit point award
class EpicFlagStakingCeremony extends StatefulWidget {
  final String placeName;
  final String city;
  final LatLng coordinates;
  final bool isMajorFlag;
  final String category;

  const EpicFlagStakingCeremony({
    super.key,
    required this.placeName,
    required this.city,
    required this.coordinates,
    required this.isMajorFlag,
    required this.category,
  });

  /// Displays the signature flag staking ceremony over the active route.
  static Future<void> show(
    BuildContext context, {
    required String placeName,
    required String city,
    required LatLng coordinates,
    required bool isMajorFlag,
    required String category,
  }) {
    return Navigator.of(context, rootNavigator: true).push<void>(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: false,
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (ctx, anim, _) => FadeTransition(
          opacity: anim,
          child: EpicFlagStakingCeremony(
            placeName: placeName,
            city: city,
            coordinates: coordinates,
            isMajorFlag: isMajorFlag,
            category: category,
          ),
        ),
      ),
    );
  }

  @override
  State<EpicFlagStakingCeremony> createState() =>
      _EpicFlagStakingCeremonyState();
}

class _Particle {
  double x;
  double y;
  double vx;
  double vy;
  double size;
  Color color;
  double life;
  double maxLife;

  _Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.color,
    required this.maxLife,
  }) : life = maxLife;

  void update(double dt) {
    x += vx * dt;
    y += vy * dt;
    vy += 380 * dt; // gravity
    life -= dt;
  }
}

class _EpicFlagStakingCeremonyState extends State<EpicFlagStakingCeremony>
    with TickerProviderStateMixin {
  late AnimationController _ceremonyController;
  late AnimationController _clothWaveController;

  final List<_Particle> _particles = [];
  bool _firstImpactTriggered = false;
  bool _secondShoveTriggered = false;

  @override
  void initState() {
    super.initState();

    // Main ceremony timeline (plunge -> impact -> effort shove -> unfurl -> telemetry)
    _ceremonyController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    // Continuous wind waving simulation for cloth
    _clothWaveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    _ceremonyController.addListener(_onCeremonyTick);
    _ceremonyController.forward();
  }

  @override
  void dispose() {
    _ceremonyController.removeListener(_onCeremonyTick);
    _ceremonyController.dispose();
    _clothWaveController.dispose();
    super.dispose();
  }

  void _onCeremonyTick() {
    if (!mounted) return;
    final t = _ceremonyController.value;

    // 1. Primary ground impact (t ≈ 0.32)
    if (t >= 0.32 && !_firstImpactTriggered) {
      _firstImpactTriggered = true;
      HapticFeedback.heavyImpact();
      _spawnImpactParticles(count: 36, isSecondary: false);
    }

    // 2. The hard-effort muscular shove (t ≈ 0.46)
    if (t >= 0.46 && !_secondShoveTriggered) {
      _secondShoveTriggered = true;
      HapticFeedback.mediumImpact();
      _spawnImpactParticles(count: 24, isSecondary: true);
    }

    // Update particles
    for (final p in _particles) {
      p.update(0.016);
    }
    _particles.removeWhere((p) => p.life <= 0);

    setState(() {});
  }

  void _spawnImpactParticles({required int count, required bool isSecondary}) {
    final random = math.Random();
    final primaryColor = widget.isMajorFlag
        ? TeritoryColors.majorGold
        : TeritoryColors.primary;

    for (int i = 0; i < count; i++) {
      final angle = (random.nextDouble() * math.pi) + math.pi; // upwards arc
      final speed = (random.nextDouble() * 260) + (isSecondary ? 140 : 180);
      final size = (random.nextDouble() * 4.5) + 2.0;
      final maxLife = (random.nextDouble() * 0.6) + 0.4;

      final color = i % 3 == 0
          ? Colors.white
          : (i % 2 == 0 ? primaryColor : TeritoryColors.majorGoldLight);

      _particles.add(
        _Particle(
          x: 0,
          y: 0,
          vx: math.cos(angle) * speed,
          vy: math.sin(angle) * speed * 0.7,
          size: size,
          color: color,
          maxLife: maxLife,
        ),
      );
    }
  }

  /// Calculates screen shake magnitude based on ceremony progress
  Offset _calculateScreenShake() {
    final t = _ceremonyController.value;
    double intensity = 0.0;

    // Shake on primary strike (0.32 to 0.42)
    if (t >= 0.32 && t < 0.42) {
      final progress = (t - 0.32) / 0.10;
      intensity = (1.0 - progress) * 12.0;
    }
    // Shake on hard effort shove (0.46 to 0.56)
    else if (t >= 0.46 && t < 0.56) {
      final progress = (t - 0.46) / 0.10;
      intensity = (1.0 - progress) * 9.0;
    }

    if (intensity <= 0.01) return Offset.zero;

    final phase = t * 65.0;
    final dx = math.sin(phase) * intensity;
    final dy = math.cos(phase * 1.3) * intensity * 0.75;
    return Offset(dx, dy);
  }

  @override
  Widget build(BuildContext context) {
    final t = _ceremonyController.value;
    final shake = _calculateScreenShake();
    final size = MediaQuery.of(context).size;

    // Telemetry and badge visibility (phases in from t = 0.65)
    final badgeOpacity = ((t - 0.65) / 0.25).clamp(0.0, 1.0);
    final buttonOpacity = ((t - 0.82) / 0.18).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // 1. Dark Vignette Cinematic Backdrop
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, 0.1),
                  radius: 1.2,
                  colors: [
                    const Color(0xFF0F172A).withValues(alpha: 0.92),
                    const Color(0xFF030712).withValues(alpha: 0.98),
                  ],
                ),
              ),
            ),
          ),

          // 2. Light shafts / God-rays in background
          Positioned.fill(
            child: CustomPaint(
              painter: _GodRaysPainter(
                progress: t,
                isMajor: widget.isMajorFlag,
              ),
            ),
          ),

          // 3. Shaking World Layer: Ground, Staff, Shockwave, and Flag
          Transform.translate(
            offset: shake,
            child: Stack(
              children: [
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _clothWaveController,
                    builder: (context, _) => CustomPaint(
                      painter: _FlagStakingPainter(
                        progress: t,
                        clothPhase: _clothWaveController.value,
                        particles: _particles,
                        placeName: widget.placeName,
                        city: widget.city,
                        category: widget.category,
                        isMajor: widget.isMajorFlag,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 4. Effort indicator text during shove
          if (t >= 0.38 && t < 0.62)
            Positioned(
              left: 0,
              right: 0,
              top: size.height * 0.32,
              child: Center(
                child: Opacity(
                  opacity: (1.0 - ((t - 0.38) / 0.24 - 0.5).abs() * 2).clamp(0.0, 1.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: widget.isMajorFlag
                            ? TeritoryColors.majorGold
                            : TeritoryColors.primary,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (widget.isMajorFlag
                                  ? TeritoryColors.majorGold
                                  : TeritoryColors.primary)
                              .withValues(alpha: 0.4),
                          blurRadius: 16,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.fitness_center_rounded,
                          size: 16,
                          color: widget.isMajorFlag
                              ? TeritoryColors.majorGold
                              : TeritoryColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'CLAIMING BEDROCK...',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.0,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // 5. Telemetry Card (Slams in after flag is firmly staked)
          if (badgeOpacity > 0.01)
            Positioned(
              left: 20,
              right: 20,
              bottom: 40,
              child: Opacity(
                opacity: badgeOpacity,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Territory Claimed HUD Card
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B).withValues(alpha: 0.94),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: widget.isMajorFlag
                              ? TeritoryColors.majorGold
                              : const Color(0xFF334155),
                          width: widget.isMajorFlag ? 1.8 : 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                          if (widget.isMajorFlag)
                            BoxShadow(
                              color: TeritoryColors.majorGold
                                  .withValues(alpha: 0.25),
                              blurRadius: 24,
                            ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Merit Points Pill
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: widget.isMajorFlag
                                  ? TeritoryColors.majorGold
                                      .withValues(alpha: 0.2)
                                  : TeritoryColors.primaryLight
                                      .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  widget.isMajorFlag
                                      ? Icons.military_tech_rounded
                                      : Icons.verified_rounded,
                                  size: 18,
                                  color: widget.isMajorFlag
                                      ? TeritoryColors.majorGold
                                      : TeritoryColors.primary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  widget.isMajorFlag
                                      ? 'MAJOR WONDER CONQUERED • +250 MERIT'
                                      : 'TERITORY EXPEDITION FLAG STAKED • +100 MERIT',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    color: widget.isMajorFlag
                                        ? TeritoryColors.majorGold
                                        : Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Place Title
                          Text(
                            widget.placeName,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),

                          // City, Country & Coordinates
                          Text(
                            '${widget.city} • ${widget.category}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              color: TeritoryColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'GPS: ${widget.coordinates.latitude.toStringAsFixed(4)}° N, ${widget.coordinates.longitude.toStringAsFixed(4)}° E',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: TeritoryColors.textMuted,
                              letterSpacing: 0.5,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // "Continue Expedition" Action CTA
                    if (buttonOpacity > 0.01)
                      Opacity(
                        opacity: buttonOpacity,
                        child: SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: widget.isMajorFlag
                                  ? TeritoryColors.majorGold
                                  : TeritoryColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 6,
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.travel_explore_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'CONTINUE EXPEDITION',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Custom painter rendering the flagpole plunge, secondary hard effort shove,
/// ground shockwave rings, fissures, particles, and unfurling flag cloth with wind waves.
class _FlagStakingPainter extends CustomPainter {
  final double progress; // 0.0 to 1.0
  final double clothPhase; // 0.0 to 1.0
  final List<_Particle> particles;
  final String placeName;
  final String city;
  final String category;
  final bool isMajor;

  _FlagStakingPainter({
    required this.progress,
    required this.clothPhase,
    required this.particles,
    required this.placeName,
    required this.city,
    required this.category,
    required this.isMajor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width * 0.42;
    final groundY = size.height * 0.55;

    // Timeline phases:
    // 0.00 -> 0.32: Fast dive downward
    // 0.32 -> 0.44: First ground impact & bounce
    // 0.44 -> 0.58: Hard effort muscular shove (thrusting deep into bedrock)
    // 0.58 -> 1.00: Planted firm & solid

    double poleTipY;
    if (progress < 0.32) {
      // Diving downward
      final t = progress / 0.32;
      final ease = Curves.easeInCubic.transform(t);
      poleTipY = -size.height * 0.2 + (groundY + size.height * 0.2) * ease;
    } else if (progress < 0.44) {
      // First impact bounce
      final t = (progress - 0.32) / 0.12;
      final bounce = math.sin(t * math.pi) * 16.0;
      poleTipY = groundY - bounce;
    } else if (progress < 0.58) {
      // THE HARD EFFORT SHOVE: Plunging 28px further down into the rock
      final t = (progress - 0.44) / 0.14;
      final shoveEase = Curves.easeInOutBack.transform(t);
      poleTipY = groundY + (28.0 * shoveEase);
    } else {
      // Firmly planted deep
      poleTipY = groundY + 28.0;
    }

    final poleLength = size.height * 0.44;
    final poleTopY = poleTipY - poleLength;

    // ─── 1. Ground Plane & Radial Territorial Compass Seal ───
    if (progress >= 0.32) {
      _drawGroundEffects(canvas, Offset(centerX, groundY + 28.0), size);
    }

    // ─── 2. Flying Particles ───
    _drawParticles(canvas, Offset(centerX, groundY + 28.0));

    // ─── 3. The Metallic Expedition Flagstaff ───
    _drawFlagstaff(canvas, centerX, poleTopY, poleTipY);

    // ─── 4. The Unfurling Waving Flag Cloth ───
    if (progress >= 0.46) {
      _drawFlagCloth(canvas, centerX, poleTopY, poleTipY, size);
    }
  }

  void _drawGroundEffects(Canvas canvas, Offset impactPoint, Size size) {
    final tSinceImpact = (progress - 0.32) / 0.68;

    // A. Expanding ground shockwave rings (flattened perspective ellipses)
    final shockwavePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    for (int i = 0; i < 3; i++) {
      final ringProgress = (tSinceImpact * 1.8 - (i * 0.22)).clamp(0.0, 1.0);
      if (ringProgress <= 0.0 || ringProgress >= 1.0) continue;

      final radiusX = ringProgress * (size.width * 0.65);
      final radiusY = radiusX * 0.32; // Perspective tilt
      final alpha = (1.0 - ringProgress) * 0.85;

      shockwavePaint.color = (isMajor
              ? TeritoryColors.majorGold
              : TeritoryColors.primary)
          .withValues(alpha: alpha);

      canvas.drawOval(
        Rect.fromCenter(center: impactPoint, width: radiusX * 2, height: radiusY * 2),
        shockwavePaint,
      );
    }

    // B. Territorial Compass Rose Seal burning into the ground
    final sealAlpha = (tSinceImpact * 2.0).clamp(0.0, 1.0);
    if (sealAlpha > 0.01) {
      final sealPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..color = (isMajor ? TeritoryColors.majorGold : const Color(0xFF38BDF8))
            .withValues(alpha: sealAlpha * 0.65);

      final sealRadiusX = 85.0;
      final sealRadiusY = sealRadiusX * 0.34;

      // Outer rings
      canvas.drawOval(
        Rect.fromCenter(center: impactPoint, width: sealRadiusX * 2, height: sealRadiusY * 2),
        sealPaint,
      );
      canvas.drawOval(
        Rect.fromCenter(center: impactPoint, width: sealRadiusX * 1.6, height: sealRadiusY * 1.6),
        sealPaint,
      );

      // Compass ray points on ground
      for (int i = 0; i < 8; i++) {
        final angle = (i * math.pi / 4);
        final r = (i % 2 == 0) ? sealRadiusX : sealRadiusX * 0.6;
        final x = impactPoint.dx + math.cos(angle) * r;
        final y = impactPoint.dy + math.sin(angle) * (r * 0.34);
        canvas.drawLine(impactPoint, Offset(x, y), sealPaint);
      }
    }

    // C. Ground impact crack fissure lines
    final crackPaint = Paint()
      ..color = (isMajor ? TeritoryColors.majorGold : const Color(0xFFFF5330))
          .withValues(alpha: (1.0 - tSinceImpact * 0.5).clamp(0.0, 0.9))
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final crackPath = Path();
    crackPath.moveTo(impactPoint.dx, impactPoint.dy);
    crackPath.lineTo(impactPoint.dx - 18, impactPoint.dy - 6);
    crackPath.lineTo(impactPoint.dx - 32, impactPoint.dy - 4);

    crackPath.moveTo(impactPoint.dx, impactPoint.dy);
    crackPath.lineTo(impactPoint.dx + 22, impactPoint.dy - 7);
    crackPath.lineTo(impactPoint.dx + 38, impactPoint.dy - 5);

    crackPath.moveTo(impactPoint.dx, impactPoint.dy);
    crackPath.lineTo(impactPoint.dx + 8, impactPoint.dy + 8);
    crackPath.lineTo(impactPoint.dx + 16, impactPoint.dy + 14);

    canvas.drawPath(crackPath, crackPaint);
  }

  void _drawParticles(Canvas canvas, Offset origin) {
    for (final p in particles) {
      final paint = Paint()
        ..color = p.color.withValues(alpha: (p.life / p.maxLife).clamp(0.0, 1.0));
      canvas.drawCircle(Offset(origin.dx + p.x, origin.dy + p.y), p.size, paint);
    }
  }

  void _drawFlagstaff(
    Canvas canvas,
    double x,
    double topY,
    double tipY,
  ) {
    // 1. Staff shaft (thick, heavy metallic spear)
    final staffRect = Rect.fromLTRB(x - 3.5, topY, x + 3.5, tipY);
    final staffPaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFFE2E8F0),
          Color(0xFF94A3B8),
          Color(0xFFCBD5E1),
          Color(0xFF475569),
        ],
        stops: [0.0, 0.4, 0.7, 1.0],
      ).createShader(staffRect);

    canvas.drawRRect(
      RRect.fromRectAndRadius(staffRect, const Radius.circular(3)),
      staffPaint,
    );

    // Effort grip rings (where muscular force shoved the pole)
    final gripPaint = Paint()..color = const Color(0xFF1E293B);
    for (int i = 0; i < 4; i++) {
      final gy = topY + 70 + (i * 9);
      canvas.drawRect(Rect.fromLTRB(x - 4.5, gy, x + 4.5, gy + 4), gripPaint);
    }

    // 2. Sharp staking spike at bottom (tapered wedge penetrating the earth)
    final spikePath = Path();
    spikePath.moveTo(x - 3.5, tipY - 14);
    spikePath.lineTo(x + 3.5, tipY - 14);
    spikePath.lineTo(x, tipY + 8); // Sharp point
    spikePath.close();

    final spikePaint = Paint()..color = const Color(0xFFE2E8F0);
    canvas.drawPath(spikePath, spikePaint);

    // 3. Spearhead / Golden Finial at top
    final finialPaint = Paint()
      ..shader = const RadialGradient(
        colors: [Colors.white, TeritoryColors.majorGold, Color(0xFFB45309)],
      ).createShader(Rect.fromCircle(center: Offset(x, topY - 8), radius: 14));

    // Orb finial
    canvas.drawCircle(Offset(x, topY - 2), 7, finialPaint);

    // Spear tip
    final finialSpike = Path();
    finialSpike.moveTo(x - 5, topY - 2);
    finialSpike.lineTo(x + 5, topY - 2);
    finialSpike.lineTo(x, topY - 20);
    finialSpike.close();
    canvas.drawPath(finialSpike, finialPaint);
  }

  void _drawFlagCloth(
    Canvas canvas,
    double poleX,
    double poleTopY,
    double poleTipY,
    Size size,
  ) {
    // Unfurling expansion progress (0.46 -> 0.85)
    final unfurlProgress = Curves.elasticOut.transform(
      ((progress - 0.46) / 0.39).clamp(0.0, 1.0),
    );

    final flagWidth = (size.width * 0.46) * unfurlProgress;
    if (flagWidth < 4) return;

    final flagHeight = size.height * 0.16;
    final flagStartY = poleTopY + 12;

    final clothPath = Path();

    // Procedural cloth wind wave vertices
    const segments = 24;
    final topPoints = <Offset>[];
    final bottomPoints = <Offset>[];

    for (int i = 0; i <= segments; i++) {
      final ratio = i / segments;
      final px = poleX + (ratio * flagWidth);

      // Sine wave wind turbulence
      final wave = math.sin((ratio * 2.8 * math.pi) - (clothPhase * 2 * math.pi)) *
          (6.0 * ratio);

      final topY = flagStartY + wave;
      final botY = flagStartY + flagHeight + wave * 0.8;

      topPoints.add(Offset(px, topY));
      bottomPoints.add(Offset(px, botY));
    }

    clothPath.moveTo(topPoints.first.dx, topPoints.first.dy);
    for (int i = 1; i < topPoints.length; i++) {
      clothPath.lineTo(topPoints[i].dx, topPoints[i].dy);
    }
    for (int i = bottomPoints.length - 1; i >= 0; i--) {
      clothPath.lineTo(bottomPoints[i].dx, bottomPoints[i].dy);
    }
    clothPath.close();

    // Gradient shading on fabric
    final clothRect = Rect.fromLTRB(
      poleX,
      flagStartY,
      poleX + flagWidth,
      flagStartY + flagHeight,
    );

    final clothPaint = Paint()
      ..shader = LinearGradient(
        colors: isMajor
            ? [
                const Color(0xFFD97706),
                const Color(0xFFF59E0B),
                const Color(0xFFFEF3C7),
                const Color(0xFFB45309),
              ]
            : [
                const Color(0xFFD63B19),
                const Color(0xFFFF5330),
                const Color(0xFFFF7A5C),
                const Color(0xFFB91C1C),
              ],
        stops: const [0.0, 0.4, 0.75, 1.0],
      ).createShader(clothRect);

    canvas.drawPath(clothPath, clothPaint);

    // Cloth border / golden fringe
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = isMajor ? Colors.white : TeritoryColors.majorGold;
    canvas.drawPath(clothPath, borderPaint);

    // Tassels at flag fly edge
    if (unfurlProgress > 0.8) {
      final tip = topPoints.last;
      final bot = bottomPoints.last;
      final tasselPaint = Paint()
        ..color = TeritoryColors.majorGold
        ..strokeWidth = 2.5;

      canvas.drawLine(tip, Offset(tip.dx + 8, tip.dy + 4), tasselPaint);
      canvas.drawLine(bot, Offset(bot.dx + 8, bot.dy - 4), tasselPaint);
    }

    // Flag Crest & Text (only when mostly unfurled)
    if (unfurlProgress > 0.65) {
      final crestX = poleX + 22.0;
      final crestY = flagStartY + flagHeight * 0.42;

      // Sailboat / Compass Emblem
      final emblemPaint = Paint()..color = Colors.white;
      canvas.drawCircle(Offset(crestX, crestY), 12, emblemPaint);

      final iconPaint = Paint()
        ..color = isMajor ? TeritoryColors.majorGoldDark : TeritoryColors.primary
        ..style = PaintingStyle.fill;

      // Mini sail emblem
      final sailPath = Path();
      sailPath.moveTo(crestX - 4, crestY + 5);
      sailPath.lineTo(crestX + 4, crestY + 5);
      sailPath.lineTo(crestX + 2, crestY - 6);
      sailPath.close();
      canvas.drawPath(sailPath, iconPaint);

      // Text painter on flag cloth
      final tp = TextPainter(
        text: TextSpan(
          text: isMajor ? '★ MAJOR WONDER' : 'TERITORY CLAIMED',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 9.5,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 0.8,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: flagWidth - 45);

      tp.paint(canvas, Offset(crestX + 16, crestY - 6));
    }
  }

  @override
  bool shouldRepaint(covariant _FlagStakingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.clothPhase != clothPhase ||
        oldDelegate.particles != particles;
  }
}

/// Atmospheric god rays radiating down onto the staked flag
class _GodRaysPainter extends CustomPainter {
  final double progress;
  final bool isMajor;

  _GodRaysPainter({required this.progress, required this.isMajor});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress < 0.35) return;

    final rayAlpha = ((progress - 0.35) / 0.4).clamp(0.0, 1.0);
    final paint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, -0.9),
        radius: 1.4,
        colors: [
          (isMajor ? TeritoryColors.majorGold : const Color(0xFF38BDF8))
              .withValues(alpha: rayAlpha * 0.22),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant _GodRaysPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
