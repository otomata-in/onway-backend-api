import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart' hide Path;

import '../../../core/models/flag_style.dart';
import '../../../core/theme/flag_style_catalog.dart';
import '../../../core/theme/teritory_theme.dart';
import '../../../core/widgets/flag/flag_cloth_painter.dart';

/// Full-screen signature cinematic shown when a flag is staked.
///
/// The ceremony is a five-beat sequence rather than a single tween:
///
/// 1. **Dive** — the staff falls with motion ghosts and speed lines.
/// 2. **Impact** — a flash, a hard camera shake, a three-ring shockwave and a
///    debris burst (dust behind the staff, sparks in front).
/// 3. **Shove** — the traveller drives the staff deeper; the ground cracks and
///    the shockwave settles.
/// 4. **Reveal** — the staked [FlagStyle] cloth snaps open with an elastic
///    whip, the emblem burns in, and the compass seal draws itself.
/// 5. **Stamp** — the telemetry card slides in, merit counts up, confetti and
///    a victory pulse land, and the CTA appears.
///
/// Everything follows the flag's own palette, and the cloth is the shared
/// [FlagClothPainter] — the flag that lands is the flag on the map.
class EpicFlagStakingCeremony extends StatefulWidget {
  final String placeName;
  final String city;
  final LatLng coordinates;
  final bool isMajorFlag;
  final String category;

  /// The flag's snapshot style: cloth, emblem, motion and speed.
  final FlagStyle style;

  const EpicFlagStakingCeremony({
    super.key,
    required this.placeName,
    required this.city,
    required this.coordinates,
    required this.isMajorFlag,
    required this.category,
    this.style = FlagStyle.fallback,
  });

  /// Displays the signature flag staking ceremony over the active route.
  static Future<void> show(
    BuildContext context, {
    required String placeName,
    required String city,
    required LatLng coordinates,
    required bool isMajorFlag,
    required String category,
    FlagStyle style = FlagStyle.fallback,
  }) {
    return Navigator.of(context, rootNavigator: true).push<void>(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: false,
        transitionDuration: const Duration(milliseconds: 260),
        pageBuilder: (ctx, anim, _) => FadeTransition(
          opacity: anim,
          child: EpicFlagStakingCeremony(
            placeName: placeName,
            city: city,
            coordinates: coordinates,
            isMajorFlag: isMajorFlag,
            category: category,
            style: style,
          ),
        ),
      ),
    );
  }

  @override
  State<EpicFlagStakingCeremony> createState() =>
      _EpicFlagStakingCeremonyState();
}

/// Beat boundaries on the 0–1 ceremony timeline. Painters and the HUD read the
/// same constants so the visual and the choreography can never drift apart.
class _Beat {
  static const double impact = 0.26;
  static const double shoveStart = 0.44;
  static const double shoveEnd = 0.56;
  static const double unfurlStart = 0.49;
  static const double unfurlEnd = 0.72;
  static const double sealStart = 0.34;
  static const double emblem = 0.66;
  static const double stamp = 0.78;
  static const double hudIn = 0.74;
  static const double ctaIn = 0.86;
}

/// One source of truth for where the stake, flag and seal sit, so the state's
/// particle bursts and the painter's choreography cannot drift apart.
///
/// Phones in portrait get the full 50%-height stake; short and landscape
/// windows compress it so the seal, card and CTA all still fit on screen.
class _StakeGeometry {
  static const double _compactHeight = 620;

  static bool isCompact(Size size) => size.height < _compactHeight;

  static double groundY(Size size) =>
      size.height * (isCompact(size) ? 0.44 : 0.50);

  static double impactY(Size size) => groundY(size) + size.height * 0.035;

  static double poleLength(Size size) =>
      size.height * (isCompact(size) ? 0.34 : 0.42);

  /// Cloth proportions, capped so a wide landscape window doesn't turn the flag
  /// into an unreadable ribbon.
  static Size flagSize(Size size) {
    final width = math.min(size.width * 0.46, size.height * 0.60);
    return Size(width, math.min(size.height * 0.20, width * 0.55));
  }

  static double tipY(double t, Size size) {
    final ground = groundY(size);
    final planted = ground + size.height * 0.035;

    if (t < _Beat.impact) {
      final p = Curves.easeInQuart.transform(
        (t / _Beat.impact).clamp(0.0, 1.0),
      );
      return -size.height * 0.55 + (ground + size.height * 0.55) * p;
    }
    if (t < _Beat.impact + 0.035) {
      final p = (t - _Beat.impact) / 0.035;
      return ground - math.sin(p * math.pi) * size.height * 0.018;
    }
    if (t < _Beat.shoveStart) {
      final p =
          ((t - _Beat.impact - 0.035) /
                  (_Beat.shoveStart - _Beat.impact - 0.035))
              .clamp(0.0, 1.0);
      return ground + size.height * 0.035 * Curves.easeOutCubic.transform(p);
    }
    if (t < _Beat.shoveEnd) {
      final p = ((t - _Beat.shoveStart) / (_Beat.shoveEnd - _Beat.shoveStart))
          .clamp(0.0, 1.0);
      final shove = Curves.easeInOutCubic.transform(p);
      return ground +
          size.height * 0.035 +
          size.height * 0.045 * shove +
          math.sin(p * math.pi) * size.height * 0.005;
    }
    final settle = ((t - _Beat.shoveEnd) / 0.08).clamp(0.0, 1.0);
    return planted +
        size.height * 0.008 * math.sin(settle * math.pi * 2) * (1 - settle);
  }

  /// The canvas rect the pole-less shared painter draws into; inverting its
  /// margins is what lands the cloth exactly on the ceremony staff.
  static Rect clothCanvas(double t, Size size) {
    final flag = flagSize(size);
    final canvasWidth = flag.width / 0.94;
    final canvasHeight = flag.height / 0.86;
    final top = tipY(t, size) - poleLength(size);
    return Rect.fromLTWH(
      size.width * 0.42 - canvasWidth * 0.02,
      top + 10 - canvasHeight * 0.06,
      canvasWidth,
      canvasHeight,
    );
  }
}

enum _ParticleKind { spark, dust, ember, confetti }

class _Particle {
  _Particle({
    required this.position,
    required this.velocity,
    required this.size,
    required this.color,
    required this.maxLife,
    this.kind = _ParticleKind.spark,
    this.gravity = 460,
    this.drag = 0.97,
    this.rotation = 0,
    this.spin = 0,
  }) : life = maxLife;

  Offset position;
  Offset velocity;
  double size;
  Color color;
  double life;
  final double maxLife;
  final _ParticleKind kind;
  final double gravity;
  final double drag;
  double rotation;
  final double spin;

  bool get alive => life > 0;

  double get opacity => (life / maxLife).clamp(0.0, 1.0);

  void update(double dt) {
    final damping = math.pow(drag, dt * 60).toDouble();
    velocity = Offset(
      velocity.dx * damping,
      velocity.dy * damping + gravity * dt,
    );
    position += velocity * dt;
    rotation += spin * dt;
    life -= dt;
  }
}

class _EpicFlagStakingCeremonyState extends State<EpicFlagStakingCeremony>
    with TickerProviderStateMixin {
  static const Duration _total = Duration(milliseconds: 4600);

  late final AnimationController _timeline;
  late final AnimationController _wind;

  final List<_Particle> _particles = [];
  final Stopwatch _clock = Stopwatch();

  bool _impactDone = false;
  bool _shoveDone = false;
  bool _unfurlCue = false;
  bool _stampDone = false;
  bool _reducedMotion = false;
  double _lastTick = 0;
  Size _lastSize = const Size(400, 800);

  @override
  void initState() {
    super.initState();
    _timeline = AnimationController(vsync: this, duration: _total)
      ..addListener(_onTick);
    _wind = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_reducedMotion) return;
    final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (!reduce) {
      if (!_timeline.isAnimating && _timeline.value == 0) {
        _clock.start();
        _timeline.forward();
      }
      return;
    }
    // Reduced motion: no plunge, no shake, no confetti. Jump to the staked,
    // fully stamped frame so the information is identical.
    _reducedMotion = true;
    _wind.stop();
    _timeline.value = 1;
    _clock.stop();
  }

  @override
  void dispose() {
    _timeline
      ..removeListener(_onTick)
      ..dispose();
    _wind.dispose();
    super.dispose();
  }

  void _onTick() {
    if (!mounted) return;
    final t = _timeline.value;

    if (t >= _Beat.impact && !_impactDone && !_reducedMotion) {
      _impactDone = true;
      HapticFeedback.heavyImpact();
      _spawnImpact();
    }
    if (t >= _Beat.shoveStart && !_shoveDone && !_reducedMotion) {
      _shoveDone = true;
      HapticFeedback.mediumImpact();
      _spawnShove();
    }
    if (t >= _Beat.unfurlStart && !_unfurlCue && !_reducedMotion) {
      _unfurlCue = true;
      HapticFeedback.lightImpact();
      _spawnEmblem();
    }
    if (t >= _Beat.stamp && !_stampDone && !_reducedMotion) {
      _stampDone = true;
      HapticFeedback.mediumImpact();
      _spawnCelebration();
    }

    final now = _clock.elapsedMicroseconds / 1e6;
    final dt = _lastTick == 0 ? 0.016 : (now - _lastTick).clamp(0.0, 0.04);
    _lastTick = now;
    if (dt > 0 && _particles.isNotEmpty) {
      for (final particle in _particles) {
        particle.update(dt);
      }
      _particles.removeWhere((particle) => !particle.alive);
    }
  }

  // ─── Particle bursts ────────────────────────────────────────────────

  void _spawnImpact() {
    final random = math.Random();
    final theme = FlagStyleCatalog.themeFor(widget.style.theme);
    final origin = _impactPoint(_lastSize);
    final accent = widget.isMajorFlag ? TeritoryColors.majorGold : theme.accent;

    for (var i = 0; i < 52; i++) {
      final angle = math.pi + random.nextDouble() * math.pi * 0.9;
      final speed = 140 + random.nextDouble() * 460;
      _particles.add(
        _Particle(
          position: origin,
          velocity: Offset(
            math.cos(angle) * speed,
            math.sin(angle) * speed * 0.55,
          ),
          size: 1.2 + random.nextDouble() * 3.2,
          color: i % 4 == 0
              ? Colors.white
              : (i % 3 == 0 ? Color.lerp(accent, Colors.white, 0.35)! : accent),
          maxLife: 0.5 + random.nextDouble() * 0.8,
          drag: 0.975,
        ),
      );
    }

    for (var i = 0; i < 30; i++) {
      final angle = math.pi + random.nextDouble() * math.pi;
      final speed = 40 + random.nextDouble() * 190;
      _particles.add(
        _Particle(
          position: origin.translate(
            (random.nextDouble() - 0.5) * 26,
            -random.nextDouble() * 10,
          ),
          velocity: Offset(
            math.cos(angle) * speed,
            math.sin(angle) * speed * 0.5,
          ),
          size: 5 + random.nextDouble() * 12,
          color: Color.lerp(
            theme.primary,
            Colors.white,
            0.18,
          )!.withValues(alpha: 0.5),
          maxLife: 0.7 + random.nextDouble() * 0.9,
          kind: _ParticleKind.dust,
          gravity: 90,
          drag: 0.93,
        ),
      );
    }
  }

  void _spawnShove() {
    final random = math.Random();
    final theme = FlagStyleCatalog.themeFor(widget.style.theme);
    final origin = _impactPoint(_lastSize);
    final accent = widget.isMajorFlag ? TeritoryColors.majorGold : theme.accent;

    for (var i = 0; i < 26; i++) {
      final angle = math.pi + random.nextDouble() * math.pi;
      final speed = 90 + random.nextDouble() * 260;
      _particles.add(
        _Particle(
          position: origin.translate((random.nextDouble() - 0.5) * 44, -2),
          velocity: Offset(
            math.cos(angle) * speed,
            math.sin(angle) * speed * 0.4,
          ),
          size: 1.0 + random.nextDouble() * 2.4,
          color: i.isEven ? accent : Colors.white,
          maxLife: 0.35 + random.nextDouble() * 0.5,
          drag: 0.96,
        ),
      );
    }
  }

  void _spawnEmblem() {
    final theme = FlagStyleCatalog.themeFor(widget.style.theme);
    final size = _lastSize;
    final unfurl = _unfurlAt(_timeline.value);
    final cloth = _clothRect(size, unfurl);
    final center = cloth.topLeft.translate(
      cloth.width * 0.02 + cloth.width * 0.94 * 0.27,
      cloth.height * 0.06 + cloth.height * 0.86 * 0.5,
    );
    final random = math.Random();
    for (var i = 0; i < 18; i++) {
      final angle = random.nextDouble() * math.pi * 2;
      final speed = 60 + random.nextDouble() * 150;
      _particles.add(
        _Particle(
          position: center,
          velocity: Offset(math.cos(angle) * speed, math.sin(angle) * speed),
          size: 1.0 + random.nextDouble() * 2.0,
          color: i.isEven ? theme.accent : Colors.white,
          maxLife: 0.35 + random.nextDouble() * 0.45,
          gravity: 120,
        ),
      );
    }
  }

  void _spawnCelebration() {
    final random = math.Random();
    final theme = FlagStyleCatalog.themeFor(widget.style.theme);
    final size = _lastSize;
    final origin = Offset(size.width * 0.5, size.height * 0.42);
    final palette = <Color>[
      theme.accent,
      Color.lerp(theme.accent, Colors.white, 0.5)!,
      if (widget.isMajorFlag) TeritoryColors.majorGold,
      theme.primary,
      Colors.white,
    ];

    for (var i = 0; i < 64; i++) {
      final angle = -math.pi / 2 + (random.nextDouble() - 0.5) * math.pi * 1.5;
      final speed = 160 + random.nextDouble() * 420;
      _particles.add(
        _Particle(
          position: origin,
          velocity: Offset(math.cos(angle) * speed, math.sin(angle) * speed),
          size: 3 + random.nextDouble() * 5,
          color: palette[i % palette.length],
          maxLife: 1.2 + random.nextDouble() * 1.1,
          kind: _ParticleKind.confetti,
          gravity: 380,
          drag: 0.99,
          rotation: random.nextDouble() * math.pi,
          spin: (random.nextDouble() - 0.5) * 12,
        ),
      );
    }

    // A final victory ring of sparks off the ground.
    for (var i = 0; i < 26; i++) {
      final angle = -math.pi + random.nextDouble() * math.pi * 2;
      _particles.add(
        _Particle(
          position: _impactPoint(size),
          velocity: Offset(math.cos(angle) * 240, math.sin(angle) * 120),
          size: 1.2 + random.nextDouble() * 2,
          color: i.isEven ? theme.accent : Colors.white,
          maxLife: 0.5,
          gravity: 60,
        ),
      );
    }
  }

  // ─── Timeline geometry ──────────────────────────────────────────────

  Offset _impactPoint(Size size) =>
      Offset(size.width * 0.42, _StakeGeometry.impactY(size));

  double _unfurlAt(double t) {
    if (t < _Beat.unfurlStart) return 0;
    final p = ((t - _Beat.unfurlStart) / (_Beat.unfurlEnd - _Beat.unfurlStart))
        .clamp(0.0, 1.0);
    return Curves.elasticOut.transform(p).clamp(0.0, 1.0);
  }

  /// The canvas rect the shared painter draws into when it has no pole.
  Rect _clothRect(Size size, double unfurl) =>
      _StakeGeometry.clothCanvas(_timeline.value, size);

  double _shakeIntensity(double t) {
    if (_reducedMotion) return 0;
    if (t >= _Beat.impact && t < _Beat.impact + 0.075) {
      return (1 - (t - _Beat.impact) / 0.075) * 20;
    }
    if (t >= _Beat.shoveStart && t < _Beat.shoveStart + 0.06) {
      return (1 - (t - _Beat.shoveStart) / 0.06) * 10;
    }
    if (t >= _Beat.stamp && t < _Beat.stamp + 0.04) {
      return (1 - (t - _Beat.stamp) / 0.04) * 7;
    }
    return 0;
  }

  Offset _shake(double t) {
    final intensity = _shakeIntensity(t);
    if (intensity <= 0.01) return Offset.zero;
    final phase = t * 90;
    return Offset(
      math.sin(phase) * intensity,
      math.cos(phase * 1.37) * intensity * 0.7,
    );
  }

  double _zoom(double t) {
    // A tiny push-in through the whole ceremony, with a kick on impact.
    final push = 1 + 0.025 * Curves.easeOutCubic.transform(t);
    if (t >= _Beat.impact && t < _Beat.impact + 0.1) {
      final p = (t - _Beat.impact) / 0.1;
      return push + math.sin(p * math.pi) * 0.012;
    }
    return push;
  }

  double _flash(double t) {
    if (_reducedMotion) return 0;
    if (t < _Beat.impact || t > _Beat.impact + 0.09) return 0;
    final p = (t - _Beat.impact) / 0.09;
    return p < 0.18 ? p / 0.18 : (1 - (p - 0.18) / 0.82);
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlagStyleCatalog.themeFor(widget.style.theme);
    final accent = widget.isMajorFlag ? TeritoryColors.majorGold : theme.accent;
    final onAccent = FlagStyleCatalog.foregroundOn(accent);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemNavigationBarColor: Color(0xFF030712),
          systemNavigationBarIconBrightness: Brightness.light,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            _lastSize = Size(constraints.maxWidth, constraints.maxHeight);
            return AnimatedBuilder(
              animation: Listenable.merge([_timeline, _wind]),
              builder: (context, _) {
                final t = _timeline.value;
                return Stack(
                  children: [
                    // Cinematic backdrop tinted by the flag's own palette.
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: const Alignment(0, 0.15),
                            radius: 1.25,
                            colors: [
                              Color.lerp(
                                theme.primary,
                                const Color(0xFF0F172A),
                                0.5,
                              )!.withValues(alpha: 0.94),
                              const Color(0xFF030712).withValues(alpha: 0.985),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Volumetric god rays behind the world.
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _GodRaysPainter(
                          progress: t,
                          accent: accent,
                          intensity: widget.isMajorFlag ? 1.25 : 1.0,
                        ),
                      ),
                    ),

                    // The shaking, zooming world layer.
                    Positioned.fill(
                      child: Transform.scale(
                        scale: _zoom(t),
                        child: Transform.translate(
                          offset: _shake(t),
                          child: CustomPaint(
                            painter: _CeremonyWorldPainter(
                              progress: t,
                              windPhase:
                                  (_wind.value * widget.style.speed) % 1.0,
                              particles: _particles,
                              style: widget.style,
                              isMajor: widget.isMajorFlag,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Impact flash and a permanent soft vignette.
                    Positioned.fill(
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              center: Alignment.center,
                              radius: 0.85,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.38),
                              ],
                              stops: const [0.55, 1.0],
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (_flash(t) > 0)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: ColoredBox(
                            color: Color.lerp(
                              Colors.white,
                              accent,
                              0.25,
                            )!.withValues(alpha: _flash(t) * 0.62),
                          ),
                        ),
                      ),

                    // The telemetry stamp.
                    _buildHud(t, theme, accent, onAccent),

                    // Skip, once the reveal is under way.
                    if (!_reducedMotion && t > 0.08 && t < 0.94)
                      Positioned(
                        top: 0,
                        right: 8,
                        child: SafeArea(
                          child: TextButton(
                            onPressed: () {
                              HapticFeedback.selectionClick();
                              _particles.clear();
                              _timeline.value = 1;
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white.withValues(
                                alpha: 0.55,
                              ),
                            ),
                            child: const Text(
                              'Skip',
                              style: TextStyle(
                                fontSize: 12,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildHud(
    double t,
    FlagThemeData theme,
    Color accent,
    Color onAccent,
  ) {
    final reveal = ((t - _Beat.hudIn) / 0.11).clamp(0.0, 1.0);
    if (reveal <= 0) return const SizedBox.shrink();

    final slide = Curves.easeOutQuart.transform(reveal);
    final cta = ((t - _Beat.ctaIn) / 0.08).clamp(0.0, 1.0);
    final points = widget.isMajorFlag ? 250 : 100;
    final counted =
        (points *
                Curves.easeOutCubic.transform(
                  ((t - _Beat.hudIn) / 0.07).clamp(0.0, 1.0),
                ))
            .round();
    final shine = Curves.easeOutCubic.transform(
      ((t - _Beat.hudIn) / 0.09).clamp(0.0, 1.0),
    );
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final compact = _StakeGeometry.isCompact(_lastSize);
    final veryShort = _lastSize.height < 520;

    return Positioned(
      left: 16,
      right: 16,
      bottom: (veryShort ? 8.0 : (compact ? 14.0 : 28.0)) + safeBottom,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Opacity(
            opacity: slide,
            child: Transform.translate(
              offset: Offset(0, 44 * (1 - slide)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!veryShort)
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 1,
                            color: accent.withValues(alpha: 0.45),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            'TERRITORY CLAIMED',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2.4,
                              color: accent,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            height: 1,
                            color: accent.withValues(alpha: 0.45),
                          ),
                        ),
                      ],
                    ),
                  SizedBox(height: veryShort ? 0 : 10),
                  Container(
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: accent.withValues(alpha: 0.65),
                        width: 1.4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 28,
                          offset: const Offset(0, 12),
                        ),
                        BoxShadow(
                          color: accent.withValues(alpha: 0.28),
                          blurRadius: 34,
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Padding(
                          padding: veryShort
                              ? const EdgeInsets.fromLTRB(14, 12, 14, 12)
                              : const EdgeInsets.fromLTRB(18, 16, 18, 16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Flexible(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: accent.withValues(alpha: 0.16),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          border: Border.all(
                                            color: accent.withValues(
                                              alpha: 0.4,
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              widget.isMajorFlag
                                                  ? Icons.military_tech_rounded
                                                  : Icons.verified_rounded,
                                              size: 15,
                                              color: accent,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              widget.isMajorFlag
                                                  ? 'MAJOR WONDER · +$counted MERIT'
                                                  : 'EXPEDITION FLAG · +$counted MERIT',
                                              style:
                                                  GoogleFonts.plusJakartaSans(
                                                    fontSize: 10.5,
                                                    fontWeight: FontWeight.w900,
                                                    letterSpacing: 0.6,
                                                    color: accent,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: veryShort ? 8 : 12),
                              Text(
                                widget.placeName,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: veryShort ? 18 : 21,
                                  fontWeight: FontWeight.w800,
                                  height: 1.15,
                                  color: Colors.white,
                                  letterSpacing: 2.2 * (1 - slide),
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                '${widget.city} • ${widget.category}',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: veryShort ? 11 : 12,
                                  color: TeritoryColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 7),
                              Text(
                                '${theme.label} · '
                                '${FlagStyleCatalog.emblemFor(widget.style.emblem).label} · '
                                '${FlagStyleCatalog.motionFor(widget.style.motion).label}',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: veryShort ? 10 : 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.4,
                                  color: accent,
                                ),
                              ),
                              if (!veryShort) ...[
                                const SizedBox(height: 3),
                                Text(
                                  'GPS ${widget.coordinates.latitude.toStringAsFixed(4)}° N · '
                                  '${widget.coordinates.longitude.toStringAsFixed(4)}° E',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    letterSpacing: 0.6,
                                    color: TeritoryColors.textMuted,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        // A light sweep across the stamp, once.
                        if (shine < 1)
                          Positioned(
                            top: -60,
                            bottom: -60,
                            left: -140 + 420 * shine,
                            width: 90,
                            child: IgnorePointer(
                              child: Transform.rotate(
                                angle: 0.35,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.white.withValues(alpha: 0),
                                        Colors.white.withValues(alpha: 0.10),
                                        Colors.white.withValues(alpha: 0),
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
                  SizedBox(height: veryShort ? 8 : 12),
                  if (cta > 0.01)
                    Opacity(
                      opacity: cta,
                      child: Transform.scale(
                        scale: 0.96 + 0.04 * Curves.easeOutBack.transform(cta),
                        child: SizedBox(
                          width: double.infinity,
                          height: veryShort ? 46 : 52,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accent,
                              foregroundColor: onAccent,
                              elevation: 8,
                              shadowColor: accent.withValues(alpha: 0.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.travel_explore_rounded,
                                    color: onAccent,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'CONTINUE EXPEDITION',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: veryShort ? 12.5 : 14,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: veryShort ? 0.6 : 1.0,
                                      color: onAccent,
                                    ),
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
          ),
        ),
      ),
    );
  }
}

/// The world: ground seal, fissures, staff, particles and the real flag cloth.
class _CeremonyWorldPainter extends CustomPainter {
  final double progress;
  final double windPhase;
  final List<_Particle> particles;
  final FlagStyle style;
  final bool isMajor;

  _CeremonyWorldPainter({
    required this.progress,
    required this.windPhase,
    required this.particles,
    required this.style,
    required this.isMajor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // The first layout pass can hand a painter a zero-sized canvas; modulo on a
    // zero width would produce NaN and poison every later draw call.
    if (size.width <= 0 || size.height <= 0) return;
    final theme = FlagStyleCatalog.themeFor(style.theme);
    final accent = isMajor ? TeritoryColors.majorGold : theme.accent;
    final centerX = size.width * 0.42;
    final impactPoint = Offset(centerX, _StakeGeometry.impactY(size));

    _paintAmbience(canvas, size, theme, accent);

    if (progress >= _Beat.impact) {
      _paintGround(canvas, size, impactPoint, theme, accent);
    }

    // Dust sits behind the staff; sparks and confetti in front.
    _paintParticles(canvas, dustOnly: true);

    _paintStaff(canvas, size, centerX, _poleTip(size), theme, accent);

    _paintCloth(canvas, size, centerX, theme, accent);
    _paintRaider(canvas, size, centerX, _StakeGeometry.groundY(size), accent);

    if (progress >= _Beat.impact) {
      _paintShockwaves(canvas, size, impactPoint, theme, accent);
    }

    _paintParticles(canvas, dustOnly: false);

    if (progress >= _Beat.stamp) {
      _paintVictoryPulse(canvas, size, impactPoint, accent);
    }
  }

  double _poleTip(Size size) => _StakeGeometry.tipY(progress, size);

  // ─── Atmosphere ─────────────────────────────────────────────────────

  void _paintAmbience(
    Canvas canvas,
    Size size,
    FlagThemeData theme,
    Color accent,
  ) {
    final motion = style.motion;

    if (motion == 'storm') {
      // Rain streaks, thicker after impact, plus a bolt during the stamp.
      final rain = Paint()
        ..strokeWidth = 1.0
        ..strokeCap = StrokeCap.round;
      for (var i = 0; i < 44; i++) {
        final speed = 1.1 + (i % 5) * 0.25;
        final y = ((i / 44 + progress * speed) % 1.0) * size.height;
        final x = (i * 71.3) % size.width;
        rain.color = Colors.white.withValues(alpha: 0.08 + (i % 3) * 0.02);
        canvas.drawLine(Offset(x, y), Offset(x - 3, y + 16), rain);
      }
      if (progress > 0.55 && progress < 0.62) {
        _paintBolt(canvas, size, (1 - (progress - 0.55) / 0.07));
      }
    } else if (motion == 'inferno') {
      for (var i = 0; i < 28; i++) {
        final rise = ((progress * 0.55 + i * 0.083) % 1.0);
        final y = size.height * (0.95 - rise * 0.7);
        final x = (i * 57.7) % size.width + math.sin(progress * 6 + i) * 14;
        final flicker = 0.35 + 0.65 * math.sin(progress * 22 + i * 2).abs();
        canvas.drawCircle(
          Offset(x, y),
          1.2 + (i % 3) * 0.9,
          Paint()
            ..blendMode = BlendMode.plus
            ..color = accent.withValues(alpha: 0.16 * flicker),
        );
      }
    } else if (motion == 'neon_pulse') {
      final line = Paint()..color = accent.withValues(alpha: 0.045);
      for (var y = 0.0; y < size.height; y += 6) {
        canvas.drawRect(Rect.fromLTWH(0, y, size.width, 1), line);
      }
    } else if (motion == 'aurora') {
      _paintAuroraBand(canvas, size, accent, 0.28, 0.16);
      _paintAuroraBand(canvas, size, accent, 0.42, 0.10);
    } else {
      for (var i = 0; i < 16; i++) {
        final x = (i * 93.1) % size.width;
        final y = ((i * 47.7 + progress * size.height * 0.05) % size.height);
        canvas.drawCircle(
          Offset(x, y),
          1.0,
          Paint()..color = Colors.white.withValues(alpha: 0.10),
        );
      }
    }
  }

  void _paintAuroraBand(
    Canvas canvas,
    Size size,
    Color accent,
    double top,
    double alpha,
  ) {
    final path = Path()..moveTo(0, size.height * top);
    for (var i = 1; i <= 6; i++) {
      final x = size.width * i / 6;
      final y =
          size.height * top +
          math.sin(progress * 4 + i * 0.9) * size.height * 0.035;
      path.lineTo(x, y);
    }
    path
      ..lineTo(size.width, size.height * (top + 0.10))
      ..lineTo(0, size.height * (top + 0.10))
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..blendMode = BlendMode.plus
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            accent.withValues(alpha: alpha),
            accent.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromLTWH(0, size.height * top, size.width, 120)),
    );
  }

  void _paintBolt(Canvas canvas, Size size, double alpha) {
    final x = size.width * 0.74;
    final path = Path()..moveTo(x, 0);
    var y = 0.0;
    var dx = 0.0;
    while (y < size.height * 0.5) {
      y += 26 + (y % 3) * 7;
      dx = (y % 2 == 0) ? 14 : -16;
      path.lineTo(x + dx, y);
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..color = Colors.white.withValues(alpha: alpha.clamp(0.0, 0.85) * 0.9),
    );
  }

  // ─── Ground ─────────────────────────────────────────────────────────

  void _paintGround(
    Canvas canvas,
    Size size,
    Offset impact,
    FlagThemeData theme,
    Color accent,
  ) {
    final since = ((progress - _Beat.impact) / 0.55).clamp(0.0, 1.0);

    // Scorch and ground glow under the stake.
    canvas.drawOval(
      Rect.fromCenter(
        center: impact,
        width: size.width * (0.20 + 0.35 * since),
        height: size.width * (0.05 + 0.08 * since),
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.35 * (1 - since * 0.5))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: impact,
        width: size.width * 0.42,
        height: size.width * 0.10,
      ),
      Paint()
        ..blendMode = BlendMode.plus
        ..shader =
            RadialGradient(
              colors: [
                accent.withValues(alpha: 0.22 * (1 - since)),
                Colors.transparent,
              ],
            ).createShader(
              Rect.fromCenter(
                center: impact,
                width: size.width * 0.42,
                height: size.width * 0.10,
              ),
            ),
    );

    _paintCracks(canvas, size, impact, accent);

    // The compass seal draws itself, then keeps a slow turn.
    final seal = ((progress - _Beat.sealStart) / 0.24).clamp(0.0, 1.0);
    if (seal > 0) {
      final eased = Curves.easeOutCubic.transform(seal);
      final alpha = eased * (0.55 + 0.15 * math.sin(progress * 8));
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = accent.withValues(alpha: alpha * 0.8);
      final radius = size.width * 0.23;
      final center = impact;

      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.scale(1, 0.31);
      canvas.translate(-center.dx, -center.dy);
      final circle = Rect.fromCircle(center: center, radius: radius);
      final glow = Paint()
        ..blendMode = BlendMode.plus
        ..color = accent.withValues(alpha: alpha * 0.25);
      canvas.drawCircle(center, radius, glow);

      // Draw each ring by sweeping an arc, so it looks inscribed.
      canvas.drawArc(
        circle,
        -math.pi / 2,
        math.pi * 2 * eased,
        false,
        paint..strokeWidth = 2.0,
      );
      canvas.drawArc(
        circle,
        math.pi / 2,
        math.pi * 2 * eased,
        false,
        paint..strokeWidth = 1.0,
      );
      canvas.drawCircle(
        center,
        radius * 0.62,
        paint..color = accent.withValues(alpha: alpha * 0.5),
      );

      // Compass ticks and star.
      final ticks = 16;
      for (var i = 0; i < ticks * eased; i++) {
        final a = i / ticks * math.pi * 2 + progress * 0.15;
        final inner = radius * (i % 4 == 0 ? 0.78 : 0.86);
        canvas.drawLine(
          center + Offset(math.cos(a) * inner, math.sin(a) * inner),
          center +
              Offset(math.cos(a) * radius * 0.95, math.sin(a) * radius * 0.95),
          paint..strokeWidth = i % 4 == 0 ? 1.8 : 0.8,
        );
      }
      final star = Path();
      for (var i = 0; i < 8; i++) {
        final a = -math.pi / 2 + i * math.pi / 4;
        final r = i.isEven ? radius * 0.55 : radius * 0.2;
        final point = center + Offset(math.cos(a) * r, math.sin(a) * r);
        if (i == 0) {
          star.moveTo(point.dx, point.dy);
        } else {
          star.lineTo(point.dx, point.dy);
        }
      }
      star.close();
      canvas.drawPath(
        star,
        Paint()..color = accent.withValues(alpha: alpha * 0.18),
      );
      canvas.restore();
    }
  }

  void _paintShockwaves(
    Canvas canvas,
    Size size,
    Offset impact,
    FlagThemeData theme,
    Color accent,
  ) {
    final age = (progress - _Beat.impact) / 0.30;
    if (age < 0 || age > 1) return;

    for (var i = 0; i < 3; i++) {
      final p = (age * 1.6 - i * 0.18).clamp(0.0, 1.0);
      if (p <= 0 || p >= 1) continue;
      final radiusX = p * size.width * 0.72;
      final alpha = (1 - p) * (i == 0 ? 0.9 : 0.45);
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = (1 - p) * 5 + 1
        ..color = (i == 0 ? Colors.white : accent).withValues(
          alpha: alpha * 0.8,
        );
      canvas.drawOval(
        Rect.fromCenter(
          center: impact,
          width: radiusX * 2,
          height: radiusX * 0.46,
        ),
        paint,
      );
    }

    // A thin haze ring that lingers after the hard rings are gone.
    final haze = (1 - age * 0.7).clamp(0.0, 1.0);
    canvas.drawOval(
      Rect.fromCenter(
        center: impact,
        width: size.width * 0.55 * (0.6 + age),
        height: size.width * 0.55 * (0.6 + age) * 0.22,
      ),
      Paint()
        ..blendMode = BlendMode.plus
        ..color = accent.withValues(alpha: 0.10 * haze),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: impact,
        width: size.width * 0.30,
        height: size.width * 0.07,
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.18),
    );
  }

  // ─── Cracked ground ─────────────────────────────────────────────────

  /// Fissures radiate from the stake; their count, reach, width and crater all
  /// scale with [_power], so a major claim visibly tears more land than a
  /// standard expedition. Forks grow in behind the main seam instead of
  /// popping into existence at full length.
  void _paintCracks(Canvas canvas, Size size, Offset impact, Color accent) {
    final since = ((progress - _Beat.impact - 0.01) / 0.26).clamp(0.0, 1.0);
    if (since <= 0) return;

    final power = _power;
    final branches = isMajor ? 8 : 4;
    final reach = size.width * (0.08 + power * 0.16);
    final dark = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 3.4 + power * 3.2
      ..color = Colors.black.withValues(alpha: 0.55 * since);
    final seam = Paint()
      ..blendMode = BlendMode.plus
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.2 + power * 1.8
      ..color = accent.withValues(alpha: 0.85 * since * (1 - since * 0.25));

    final random = math.Random(7);
    final paths = <Path>[];
    for (var branch = 0; branch < branches; branch++) {
      var point = impact;
      var angle =
          branch / branches * math.pi * 2 + (random.nextDouble() - 0.5) * 0.5;
      final length = reach * (0.75 + (branch % 3) * 0.18);
      final steps = 4 + (power * 2).round();
      final path = Path()..moveTo(point.dx, point.dy);
      for (var i = 0; i < steps; i++) {
        angle += (random.nextDouble() - 0.5) * 0.55;
        point += Offset(
          math.cos(angle) * length / steps,
          math.sin(angle) * length * 0.30 / steps,
        );
        if ((i + 1) / steps > since) break;
        path.lineTo(point.dx, point.dy);
        if (i != steps ~/ 2) continue;
        final forkLength =
            length * 0.30 * ((since - 0.5) / 0.5).clamp(0.0, 1.0);
        if (forkLength < 1) continue;
        final forkAngle = angle + (branch.isEven ? 0.8 : -0.8);
        paths.add(
          Path()
            ..moveTo(point.dx, point.dy)
            ..lineTo(
              point.dx + math.cos(forkAngle) * forkLength,
              point.dy + math.sin(forkAngle) * 0.24 * forkLength,
            ),
        );
      }
      paths.add(path);
    }
    for (final path in paths) {
      canvas.drawPath(path, dark);
      canvas.drawPath(path, seam);
    }

    // Jagged crater rim, wider and deeper for a major claim.
    final rimGrowth = ((since - 0.15) / 0.85).clamp(0.0, 1.0);
    final rimRadius = size.width * (0.05 + power * 0.06) * rimGrowth;
    if (rimRadius < 1) return;
    final rim = Path();
    for (var i = 0; i < 14; i++) {
      final a = i / 14 * math.pi * 2;
      final r = rimRadius * (i.isEven ? 1.0 : 0.78);
      final p = impact + Offset(math.cos(a) * r, math.sin(a) * r * 0.34);
      if (i == 0) {
        rim.moveTo(p.dx, p.dy);
      } else {
        rim.lineTo(p.dx, p.dy);
      }
    }
    rim.close();
    canvas.drawPath(
      rim,
      Paint()..color = Colors.black.withValues(alpha: 0.34 * since),
    );
    canvas.drawPath(
      rim,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0 + power
        ..color = accent.withValues(alpha: 0.28 * since),
    );
  }

  // ─── Raider ─────────────────────────────────────────────────────────

  /// Claim strength: a major wonder drives the staff roughly twice as hard.
  double get _power => isMajor ? 1.0 : 0.55;

  void _poly(Canvas canvas, List<Offset> points, Paint fill, {Paint? edge}) {
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    path.close();
    canvas.drawPath(path, fill);
    if (edge != null) canvas.drawPath(path, edge);
  }

  /// Outlined round limb segment, so arms and legs read as anatomy instead of
  /// merging into one plate.
  void _tube(Canvas canvas, Offset a, Offset b, double width, Color fill) {
    canvas.drawLine(
      a,
      b,
      Paint()
        ..color = const Color(0xFF060A12)
        ..strokeWidth = width + 3
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      a,
      b,
      Paint()
        ..color = fill
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round,
    );
  }

  void _paintBoot(Canvas canvas, Offset ankle, bool near, Color accent) {
    final toe = ankle.dx + (near ? 11.0 : 9.0);
    _poly(
      canvas,
      [
        Offset(ankle.dx - 6, ankle.dy - 4),
        Offset(toe, ankle.dy - 5),
        Offset(toe + 1, ankle.dy + 2),
        Offset(ankle.dx - 6, ankle.dy + 3),
      ],
      Paint()..color = const Color(0xFF141C2B),
      edge: Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = const Color(0xFF05080F),
    );
    canvas.drawLine(
      Offset(ankle.dx - 6, ankle.dy + 1),
      Offset(toe, ankle.dy),
      Paint()
        ..strokeWidth = 1.2
        ..color = accent.withValues(alpha: near ? 0.7 : 0.4),
    );
    _poly(canvas, [
      Offset(toe - 4, ankle.dy - 4),
      Offset(toe, ankle.dy - 5),
      Offset(toe + 1, ankle.dy + 1),
      Offset(toe - 4, ankle.dy + 1),
    ], Paint()..color = const Color(0xFF2B3A52));
  }

  void _paintScarf(Canvas canvas, double breath, double enter, Color accent) {
    final wave = math.sin(progress * 16) * 4;
    final tail = -30 - enter * 8;
    final path = Path()
      ..moveTo(-2, -83 + breath)
      ..quadraticBezierTo(-14, -86 + wave, tail, -80 + wave)
      ..lineTo(tail + 3, -73 + wave)
      ..quadraticBezierTo(-15, -76 + wave * 0.5, -2, -76 + breath)
      ..close();
    canvas.drawPath(path, Paint()..color = accent.withValues(alpha: 0.32));
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = accent.withValues(alpha: 0.55),
    );
  }

  void _paintHelmet(Canvas canvas, double headY, Color accent) {
    final plate = Paint()..color = const Color(0xFF4A5C7A);
    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7
      ..color = const Color(0xFF060A12);
    // Neck first, so the helmet sits on a body instead of floating.
    _poly(canvas, [
      Offset(1, headY + 12),
      Offset(7, headY + 11),
      Offset(7, headY + 6),
      Offset(1, headY + 7),
    ], Paint()..color = const Color(0xFF121A29));
    _poly(
      canvas,
      [
        Offset(-7, headY + 6),
        Offset(-9, headY - 1),
        Offset(-4, headY - 8),
        Offset(5, headY - 9),
        Offset(11, headY - 5),
        Offset(12, headY + 2),
        Offset(7, headY + 8),
        Offset(0, headY + 9),
      ],
      plate,
      edge: edge,
    );
    // Visor recess and lit slit.
    _poly(canvas, [
      Offset(-5, headY - 1),
      Offset(10, headY - 2),
      Offset(10, headY + 3),
      Offset(-4, headY + 3),
    ], Paint()..color = const Color(0xFF0A111D));
    _poly(
      canvas,
      [
        Offset(-3, headY),
        Offset(9, headY - 0.5),
        Offset(9, headY + 1.8),
        Offset(-3, headY + 2.2),
      ],
      Paint()
        ..blendMode = BlendMode.plus
        ..color = accent.withValues(alpha: 0.9),
    );
    // Chin guard.
    _poly(canvas, [
      Offset(-3, headY + 4),
      Offset(9, headY + 4),
      Offset(7, headY + 7),
      Offset(0, headY + 7.5),
    ], Paint()..color = const Color(0xFF33425C));
    // Small crest at the back of the crown.
    _poly(canvas, [
      Offset(-1, headY - 8),
      Offset(-8, headY - 13),
      Offset(-13, headY - 8),
      Offset(-4, headY - 7),
    ], Paint()..color = accent.withValues(alpha: 0.8));
    // Side vent.
    canvas.drawCircle(
      Offset(9.5, headY - 4),
      1.6,
      Paint()..color = const Color(0xFF0A111D),
    );
  }

  void _paintGlove(Canvas canvas, Offset hand, double radius, Color accent) {
    canvas.drawCircle(
      hand,
      radius + 1.6,
      Paint()..color = const Color(0xFF060A12),
    );
    canvas.drawCircle(hand, radius, Paint()..color = const Color(0xFF22304A));
    canvas.drawCircle(
      hand,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = accent.withValues(alpha: 0.5),
    );
    canvas.drawLine(
      hand + Offset(-radius * 0.55, -radius * 0.2),
      hand + Offset(radius * 0.55, -radius * 0.35),
      Paint()
        ..strokeWidth = 1.4
        ..color = accent.withValues(alpha: 0.7),
    );
  }

  /// The raider who plants the claim: armoured suit, angular helmet with a lit
  /// visor, pauldrons, pack, belt kit and a wind-torn scarf.
  ///
  /// He sprints in, grabs the falling staff, drives it down with his whole
  /// weight (trembling under the strain), staggers back when it catches, then
  /// raises a fist over the cracked ground.
  void _paintRaider(
    Canvas canvas,
    Size size,
    double poleX,
    double groundY,
    Color accent,
  ) {
    if (progress < 0.03) return;

    final h = size.height * (size.height < 620 ? 0.30 : 0.27);
    double beat(
      double from,
      double span, [
      Curve curve = Curves.easeOutCubic,
    ]) =>
        curve.transform(((progress - from) / span).clamp(0.0, 1.0)).toDouble();

    final enter = beat(0.03, 0.17);
    final running = (1 - ((progress - 0.15) / 0.08).clamp(0.0, 1.0)).toDouble();
    final grab = beat(0.17, 0.08);
    final drive = beat(0.33, 0.23, Curves.easeInOutCubic);
    final stagger = beat(0.56, 0.13);
    final victory = ((progress - 0.78) / 0.10).clamp(0.0, 1.0).toDouble();
    final victoryEased = Curves.easeOutBack
        .transform(victory)
        .clamp(0.0, 1.12)
        .toDouble();

    final x =
        poleX -
        math.min(size.width * 0.155, h * 0.38) -
        (1 - enter) * size.width * 0.55;
    final stride = running * math.sin(progress * 120);
    final lean = -0.05 + drive * 0.24 - stagger * 0.28 + victoryEased * 0.12;
    final breath = victory * math.sin(progress * 26) * 1.1;

    // A soft accent glow keeps the silhouette off the dark backdrop.
    canvas.drawCircle(
      Offset(x, groundY - h * 0.5),
      h * 0.62,
      Paint()
        ..blendMode = BlendMode.plus
        ..shader =
            RadialGradient(
              colors: [accent.withValues(alpha: 0.10), Colors.transparent],
            ).createShader(
              Rect.fromCircle(
                center: Offset(x, groundY - h * 0.5),
                radius: h * 0.62,
              ),
            ),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(x, groundY + 2),
        width: h * 0.60,
        height: h * 0.09,
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.40),
    );

    canvas.save();
    canvas.translate(x, groundY);
    canvas.rotate(lean);
    canvas.scale(h / 100);
    final matrix = Matrix4.fromFloat64List(canvas.getTransform());
    Offset world(double lx, double ly) =>
        MatrixUtils.transformPoint(matrix, Offset(lx, ly));

    // Cool slates hold up against the red backdrop; accent stays on trim.
    const suit = Color(0xFF2E3D58);
    const suitDark = Color(0xFF1B2537);
    const plate = Color(0xFF4C5F7E);
    const plateHi = Color(0xFF7186A8);
    const dark = Color(0xFF0A111D);
    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..color = const Color(0xFF060A12);
    final plateFill = Paint()..color = plate;
    final suitFill = Paint()..color = suit;

    _paintScarf(canvas, breath, enter, accent);

    // Pack and antenna.
    _poly(
      canvas,
      [
        const Offset(-21, -56),
        const Offset(-9, -56),
        const Offset(-8, -78),
        const Offset(-20, -80),
      ],
      Paint()..color = const Color(0xFF182130),
      edge: edge,
    );
    canvas.drawLine(
      const Offset(-16, -79),
      Offset(-19, -92 + breath),
      Paint()
        ..strokeWidth = 1.6
        ..color = plate,
    );
    canvas.drawCircle(
      Offset(-19, -92 + breath),
      1.7,
      Paint()
        ..blendMode = BlendMode.plus
        ..color = accent.withValues(alpha: 0.4 + 0.6 * victory),
    );

    // Legs: outlined tubes, knees bent, feet pointing at the staff.
    final hipL = const Offset(-4, -51);
    final hipR = const Offset(4, -51);
    final kneeL = Offset(-7 + stride * 2, -28 - math.max(0.0, stride) * 4);
    final kneeR = Offset(7 - stride * 2, -28 - math.max(0.0, -stride) * 4);
    final ankleL = Offset(-10, -5 - math.max(0.0, stride) * 6);
    final ankleR = Offset(10, -5 - math.max(0.0, -stride) * 6);
    _tube(canvas, hipL, kneeL, 13, suit);
    _tube(canvas, kneeL, ankleL, 10, suitDark);
    _tube(canvas, hipR, kneeR, 13, suit);
    _tube(canvas, kneeR, ankleR, 10, suitDark);
    for (final knee in [kneeL, kneeR]) {
      canvas.drawCircle(knee, 4.2, Paint()..color = plate);
      canvas.drawCircle(
        knee,
        4.2,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = dark,
      );
    }
    _paintBoot(canvas, ankleL, false, accent);
    _paintBoot(canvas, ankleR, true, accent);

    // Torso: tapered chest, armoured front, harness.
    _poly(
      canvas,
      [
        const Offset(-10, -52),
        const Offset(10, -52),
        const Offset(11, -70),
        Offset(8, -83 + breath),
        Offset(-7, -83 + breath),
        const Offset(-11, -70),
      ],
      suitFill,
      edge: edge,
    );
    _poly(
      canvas,
      [
        const Offset(-7, -68),
        const Offset(7, -69),
        Offset(8, -78 + breath),
        Offset(5, -81 + breath),
        Offset(-5, -81 + breath),
        const Offset(-8, -77),
      ],
      plateFill,
      edge: Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = const Color(0xFF1C2638),
    );
    // Collar V and chest lamp.
    canvas.drawPath(
      Path()
        ..moveTo(-5, -81 + breath)
        ..lineTo(0, -75 + breath)
        ..lineTo(6, -81 + breath),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..color = accent.withValues(alpha: 0.75),
    );
    canvas.drawCircle(
      const Offset(0.5, -71),
      1.5,
      Paint()
        ..blendMode = BlendMode.plus
        ..color = accent.withValues(alpha: 0.8),
    );
    // Harness straps.
    for (final side in [-1.0, 1.0]) {
      canvas.drawLine(
        Offset(6 * side, -81 + breath),
        Offset(3 * side, -52),
        Paint()
          ..strokeWidth = 2.4
          ..color = const Color(0xFF131B2A),
      );
    }

    // Belt, buckle and kit pouches.
    _poly(canvas, [
      const Offset(-10, -53),
      const Offset(10, -53),
      const Offset(10, -47),
      const Offset(-10, -47),
    ], Paint()..color = dark);
    _poly(canvas, [
      const Offset(-2, -52.5),
      const Offset(2, -52.5),
      const Offset(2, -48),
      const Offset(-2, -48),
    ], Paint()..color = accent.withValues(alpha: 0.8));
    for (final side in [-1.0, 1.0]) {
      _poly(canvas, [
        Offset(5 * side, -52),
        Offset(9 * side, -52),
        Offset(9 * side, -46),
        Offset(5 * side, -46),
      ], plateFill);
    }

    // Pauldrons sit on the shoulders, clear of the helmet.
    for (final side in [-1.0, 1.0]) {
      _poly(
        canvas,
        [
          Offset(8 * side, -84 + breath),
          Offset(20 * side, -81 + breath),
          Offset(19 * side, -74 + breath),
          Offset(9 * side, -77 + breath),
        ],
        plateFill,
        edge: edge,
      );
      canvas.drawLine(
        Offset(10 * side, -81 + breath),
        Offset(18 * side, -79 + breath),
        Paint()
          ..strokeWidth = 1.4
          ..color = plateHi.withValues(alpha: 0.7),
      );
    }

    _paintHelmet(canvas, -92 + breath, accent);
    canvas.restore();

    // Arms are drawn in world space so the gloves land on the staff. Elbows
    // are explicit: a grip elbow sags below the line, a raised elbow lifts
    // outward, which is what keeps the driving arm from covering the helmet.
    final shoulderNear = world(9, -79 + breath);
    final shoulderFar = world(-6, -80 + breath);
    final gripNear = Offset(
      poleX,
      groundY - h * (0.84 - drive * 0.10) + stagger * h * 0.10,
    );
    final gripFar = Offset(
      poleX,
      groundY - h * (0.62 - drive * 0.08) + stagger * h * 0.10,
    );
    var handNear = Offset.lerp(world(15, -70 + breath), gripNear, grab)!;
    var handFar = Offset.lerp(world(6, -64 + breath), gripFar, grab)!;
    var elbowNear = Offset.lerp(
      Offset(
        (shoulderNear.dx + handNear.dx) / 2 + h * 0.02,
        (shoulderNear.dy + handNear.dy) / 2 + h * 0.07,
      ),
      world(14, -98 + breath),
      victoryEased,
    )!;
    final elbowFar = Offset(
      (shoulderFar.dx + handFar.dx) / 2 - h * 0.03,
      (shoulderFar.dy + handFar.dy) / 2 + h * 0.06,
    );

    final fist = world(12, -116 + breath);
    handNear = Offset.lerp(handNear, fist, victoryEased)!;
    elbowNear = Offset.lerp(elbowNear, world(14, -98 + breath), victoryEased)!;

    _tube(canvas, shoulderFar, elbowFar, h * 0.046, suitDark);
    _tube(canvas, elbowFar, handFar, h * 0.040, suitDark);
    _tube(canvas, shoulderNear, elbowNear, h * 0.052, suit);
    _tube(canvas, elbowNear, handNear, h * 0.045, plate);
    canvas.drawCircle(
      elbowNear,
      h * 0.028,
      Paint()..color = const Color(0xFF22304A),
    );
    _paintGlove(canvas, handFar, h * 0.030, accent);
    _paintGlove(
      canvas,
      handNear,
      h * (victory > 0.2 ? 0.032 + 0.012 * victory : 0.030),
      accent,
    );

    // Strained tendons while he forces the staff down.
    final strain = (drive * (1 - stagger)).clamp(0.0, 1.0);
    if (strain > 0.05) {
      final root = world(-17, -70);
      for (var i = 0; i < 3; i++) {
        final y = root.dy + i * h * 0.05;
        canvas.drawLine(
          Offset(root.dx - h * 0.015, y),
          Offset(root.dx - h * (0.075 + 0.01 * i), y - h * 0.018),
          Paint()
            ..strokeWidth = 1.2
            ..strokeCap = StrokeCap.round
            ..color = accent.withValues(alpha: strain * (0.55 - i * 0.13)),
        );
      }
    }

    // Dust kicked up by the run and the shove.
    final dust = running * 0.45 + drive * 0.5;
    if (dust > 0.05) {
      for (var i = 0; i < 5; i++) {
        final spread = (i / 4 - 0.5) * 2;
        final rise = ((progress * 90 + i * 37) % 100) / 100;
        canvas.drawCircle(
          Offset(
            x + spread * h * 0.32 + math.sin(progress * 20 + i) * 4,
            groundY - 3 - rise * h * 0.12,
          ),
          h * (0.016 + 0.007 * (i % 3)),
          Paint()
            ..color = Colors.white.withValues(alpha: dust * (1 - rise) * 0.16),
        );
      }
    }

    // Gloves biting the staff as the claim catches.
    final grabFlash = (grab - 0.55).abs();
    if (grabFlash < 0.22 && progress < 0.40) {
      final alpha = (1 - grabFlash / 0.22) * 0.75;
      for (var i = 0; i < 5; i++) {
        final angle = i / 5 * math.pi * 2;
        canvas.drawCircle(
          handNear + Offset(math.cos(angle), math.sin(angle)) * h * 0.06,
          1.2,
          Paint()
            ..blendMode = BlendMode.plus
            ..color = accent.withValues(alpha: alpha),
        );
      }
    }
  }

  // ─── Staff ──────────────────────────────────────────────────────────

  void _paintStaff(
    Canvas canvas,
    Size size,
    double x,
    double tipY,
    FlagThemeData theme,
    Color accent,
  ) {
    final poleLength = _StakeGeometry.poleLength(size);
    final topY = tipY - poleLength;
    final shaftWidth = math.max(4.0, size.width * 0.011);

    // Motion ghosts while the staff is still falling.
    if (progress < _Beat.impact) {
      for (var i = 1; i <= 3; i++) {
        final ghostTip = tipY - i * size.height * 0.055;
        canvas.drawLine(
          Offset(x, ghostTip - poleLength),
          Offset(x, ghostTip),
          Paint()
            ..strokeWidth = shaftWidth * (1 - i * 0.18)
            ..strokeCap = StrokeCap.round
            ..color = Colors.white.withValues(alpha: 0.16 / i),
        );
      }
      // Speed lines behind the fall.
      for (var i = 0; i < 5; i++) {
        final offset = (i - 2) * shaftWidth * 3.2;
        canvas.drawLine(
          Offset(x + offset, topY - 40 - i * 22),
          Offset(x + offset, topY - 100 - i * 30),
          Paint()
            ..strokeWidth = 1
            ..color = Colors.white.withValues(alpha: 0.12),
        );
      }
    }

    final shaft = Rect.fromLTRB(
      x - shaftWidth / 2,
      topY,
      x + shaftWidth / 2,
      tipY - shaftWidth * 1.4,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(shaft, Radius.circular(shaftWidth)),
      Paint()
        ..shader = LinearGradient(
          colors: [
            const Color(0xFFF8FAFC),
            const Color(0xFF94A3B8),
            const Color(0xFFE2E8F0),
            const Color(0xFF334155),
          ],
          stops: const [0.0, 0.35, 0.65, 1.0],
        ).createShader(shaft),
    );

    // A warm highlight down the lit side of the metal.
    canvas.drawLine(
      Offset(x - shaftWidth * 0.22, topY + 6),
      Offset(x - shaftWidth * 0.22, tipY - 8),
      Paint()
        ..strokeWidth = math.max(1, shaftWidth * 0.18)
        ..color = Colors.white.withValues(alpha: 0.35),
    );

    // Grip rings.
    final grip = Paint()
      ..color = const Color(0xFF0F172A)
      ..strokeWidth = shaftWidth * 0.55;
    for (var i = 0; i < 4; i++) {
      final y = topY + poleLength * 0.52 + i * 9;
      canvas.drawLine(
        Offset(x - shaftWidth * 0.75, y),
        Offset(x + shaftWidth * 0.75, y),
        grip,
      );
    }

    // Spike, with a brief molten glow after impact.
    final spike = Path()
      ..moveTo(x - shaftWidth / 2, tipY - shaftWidth * 1.6)
      ..lineTo(x + shaftWidth / 2, tipY - shaftWidth * 1.6)
      ..lineTo(x, tipY + size.height * 0.012)
      ..close();
    canvas.drawPath(spike, Paint()..color = const Color(0xFFE2E8F0));
    if (progress >= _Beat.impact) {
      final heat = (1 - (progress - _Beat.impact) / 0.25).clamp(0.0, 1.0);
      if (heat > 0) {
        canvas.drawCircle(
          Offset(x, tipY),
          size.width * 0.03 * heat,
          Paint()
            ..blendMode = BlendMode.plus
            ..color = accent.withValues(alpha: 0.55 * heat),
        );
      }
    }

    // Finial.
    final metal = isMajor ? TeritoryColors.majorGold : theme.finial;
    final finial = Paint()
      ..shader = RadialGradient(
        colors: [Colors.white, metal, Color.lerp(metal, Colors.black, 0.45)!],
      ).createShader(Rect.fromCircle(center: Offset(x, topY - 8), radius: 15));
    canvas.drawCircle(Offset(x, topY - 1), 7, finial);
    final tip = Path()
      ..moveTo(x - 5, topY - 2)
      ..lineTo(x + 5, topY - 2)
      ..lineTo(x, topY - 22)
      ..close();
    canvas.drawPath(tip, finial);
  }

  // ─── Flag cloth ─────────────────────────────────────────────────────

  void _paintCloth(
    Canvas canvas,
    Size size,
    double poleX,
    FlagThemeData theme,
    Color accent,
  ) {
    final unfurl = _unfurl(size);
    if (unfurl < 0.02) return;

    final flag = _StakeGeometry.flagSize(size);
    final canvasWidth = flag.width / 0.94;
    final canvasHeight = flag.height / 0.86;
    final canvasRect = _StakeGeometry.clothCanvas(progress, size);

    canvas.save();
    canvas.translate(canvasRect.left, canvasRect.top);

    // The whip crack: short accent streaks off the fly edge while it snaps open.
    if (unfurl > 0.55 && progress < _Beat.unfurlEnd + 0.05) {
      final whip = (1 - ((progress - _Beat.unfurlStart) / 0.3)).clamp(0.0, 1.0);
      final edgeX = canvasWidth * 0.02 + canvasWidth * 0.94 * unfurl;
      final edgeTop = canvasHeight * 0.06 + canvasHeight * 0.08;
      final paint = Paint()
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: 0.35 * whip);
      for (var i = 0; i < 3; i++) {
        canvas.drawLine(
          Offset(edgeX - 2, edgeTop + canvasHeight * 0.30 + i * 4),
          Offset(edgeX + 16 + i * 8, edgeTop + canvasHeight * 0.28 + i * 5),
          paint,
        );
      }
    }

    FlagClothPainter(
      style: style,
      phase: windPhase,
      showPole: false,
      isMajor: isMajor,
      unfurl: unfurl,
    ).paint(canvas, Size(canvasWidth, canvasHeight));

    // Emblem burn-in: a hot ring snaps tight around the disc and cools.
    if (progress >= _Beat.emblem) {
      final p = ((progress - _Beat.emblem) / 0.10).clamp(0.0, 1.0);
      final center = Offset(
        canvasWidth * 0.02 + canvasWidth * 0.94 * unfurl * 0.27,
        canvasHeight * 0.06 + canvasHeight * 0.86 * 0.5,
      );
      final radius =
          math.min(canvasWidth, canvasHeight) * (0.16 + 0.16 * (1 - p));
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4 * (1 - p) + 0.6
          ..blendMode = BlendMode.plus
          ..color = accent.withValues(alpha: 0.7 * (1 - p)),
      );
      canvas.drawCircle(
        center,
        radius * 0.62,
        Paint()
          ..blendMode = BlendMode.plus
          ..color = Colors.white.withValues(alpha: 0.10 * (1 - p)),
      );
    }

    canvas.restore();
  }

  double _unfurl(Size size) {
    if (progress < _Beat.unfurlStart) return 0;
    final p =
        ((progress - _Beat.unfurlStart) / (_Beat.unfurlEnd - _Beat.unfurlStart))
            .clamp(0.0, 1.0);
    return Curves.elasticOut.transform(p).clamp(0.0, 1.0);
  }

  // ─── Particles ──────────────────────────────────────────────────────

  void _paintParticles(Canvas canvas, {required bool dustOnly}) {
    for (final particle in particles) {
      if ((particle.kind == _ParticleKind.dust) != dustOnly) continue;
      final alpha = particle.opacity;
      switch (particle.kind) {
        case _ParticleKind.dust:
          // Two soft circles read as dust without a per-particle blur filter,
          // which is expensive on phone GPUs.
          canvas.drawCircle(
            particle.position,
            particle.size * (2 - alpha),
            Paint()
              ..color = particle.color.withValues(
                alpha: particle.color.a * alpha * 0.12,
              ),
          );
          canvas.drawCircle(
            particle.position,
            particle.size * (1.3 - alpha * 0.3),
            Paint()
              ..color = particle.color.withValues(
                alpha: particle.color.a * alpha * 0.18,
              ),
          );
          break;
        case _ParticleKind.confetti:
          canvas.save();
          canvas.translate(particle.position.dx, particle.position.dy);
          canvas.rotate(particle.rotation);
          canvas.drawRect(
            Rect.fromCenter(
              center: Offset.zero,
              width: particle.size * 1.6,
              height: particle.size * 0.8,
            ),
            Paint()..color = particle.color.withValues(alpha: alpha),
          );
          canvas.restore();
          break;
        case _ParticleKind.spark:
        case _ParticleKind.ember:
          final trail = particle.position - particle.velocity * 0.018;
          canvas.drawLine(
            trail,
            particle.position,
            Paint()
              ..strokeWidth = particle.size * 0.7
              ..strokeCap = StrokeCap.round
              ..blendMode = BlendMode.plus
              ..color = particle.color.withValues(alpha: alpha),
          );
          canvas.drawCircle(
            particle.position,
            particle.size * 0.5,
            Paint()
              ..blendMode = BlendMode.plus
              ..color = Colors.white.withValues(alpha: alpha * 0.6),
          );
          break;
      }
    }
  }

  void _paintVictoryPulse(
    Canvas canvas,
    Size size,
    Offset impact,
    Color accent,
  ) {
    final p = ((progress - _Beat.stamp) / 0.22).clamp(0.0, 1.0);
    if (p <= 0 || p >= 1) return;
    canvas.drawOval(
      Rect.fromCenter(
        center: impact,
        width: size.width * (0.2 + p * 1.1),
        height: size.width * (0.05 + p * 0.30),
      ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = (1 - p) * 3 + 0.5
        ..blendMode = BlendMode.plus
        ..color = accent.withValues(alpha: (1 - p) * 0.5),
    );
  }

  @override
  bool shouldRepaint(covariant _CeremonyWorldPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.windPhase != windPhase ||
        oldDelegate.particles != particles ||
        oldDelegate.style != style ||
        oldDelegate.isMajor != isMajor;
  }
}

/// Rotating volumetric rays tinted by the flag accent.
class _GodRaysPainter extends CustomPainter {
  final double progress;
  final Color accent;
  final double intensity;

  _GodRaysPainter({
    required this.progress,
    required this.accent,
    required this.intensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress < 0.12) return;

    final bloom = ((progress - 0.12) / 0.45).clamp(0.0, 1.0);
    final origin = Offset(
      size.width * 0.42,
      _StakeGeometry.groundY(size) + size.height * 0.04,
    );
    final rayPaint = Paint()..blendMode = BlendMode.plus;

    canvas.save();
    canvas.translate(origin.dx, origin.dy);
    canvas.rotate(-0.25 + math.sin(progress * 2) * 0.04);

    for (var i = 0; i < 9; i++) {
      final angle = -math.pi * 0.85 + i * (math.pi * 0.85 / 8);
      final width = 0.03 + (i % 3) * 0.012;
      final path = Path()
        ..moveTo(0, 0)
        ..lineTo(
          math.cos(angle - width) * size.height * 1.5,
          math.sin(angle - width) * size.height * 1.5,
        )
        ..lineTo(
          math.cos(angle + width) * size.height * 1.5,
          math.sin(angle + width) * size.height * 1.5,
        )
        ..close();
      rayPaint.color = accent.withValues(
        alpha: 0.055 * bloom * intensity * (0.6 + (i % 4) * 0.15),
      );
      canvas.drawPath(path, rayPaint);
    }
    canvas.restore();

    // Ground bloom.
    canvas.drawCircle(
      origin,
      size.width * 0.4,
      Paint()
        ..blendMode = BlendMode.plus
        ..shader =
            RadialGradient(
              colors: [
                accent.withValues(alpha: 0.16 * bloom),
                Colors.transparent,
              ],
            ).createShader(
              Rect.fromCircle(center: origin, radius: size.width * 0.4),
            ),
    );
  }

  @override
  bool shouldRepaint(covariant _GodRaysPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.accent != accent ||
        oldDelegate.intensity != intensity;
  }
}
