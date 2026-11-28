import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/flag_style.dart';
import '../../theme/flag_style_catalog.dart';
import 'flag_cloth_painter.dart';

/// One flag, drawn by the shared [FlagClothPainter].
///
/// Static surfaces pass no [phase] and get the same flag at rest. Animated
/// surfaces either drive [phase] themselves ([AnimatedTeritoryFlag]) or read it
/// from one shared [FlagMotionClock] so a dense map field costs one ticker, not
/// one per pin.
class TeritoryFlag extends StatelessWidget {
  final FlagStyle style;
  final double width;
  final double phase;
  final bool showPole;
  final bool isMajor;
  final double unfurl;
  final double? heightOverride;
  final String? semanticLabel;

  const TeritoryFlag({
    super.key,
    required this.style,
    this.width = 96,
    this.phase = 0,
    this.showPole = true,
    this.isMajor = false,
    this.unfurl = 1.0,
    this.heightOverride,
    this.semanticLabel,
  });

  double get height => heightOverride ?? width * (showPole ? 0.78 : 0.62);

  String get _label {
    if (semanticLabel != null) return semanticLabel!;
    final theme = FlagStyleCatalog.themeFor(style.theme);
    final emblem = FlagStyleCatalog.emblemFor(style.emblem);
    final suffix = emblem.id == 'none' ? '' : ', ${emblem.label.toLowerCase()} emblem';
    return '${theme.label} flag$suffix';
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: _label,
      image: true,
      child: SizedBox(
        width: width,
        height: height,
        child: CustomPaint(
          painter: FlagClothPainter(
            style: style,
            phase: phase,
            showPole: showPole,
            isMajor: isMajor,
            unfurl: unfurl,
          ),
        ),
      ),
    );
  }
}

/// A flag widget for dense surfaces such as map pins.
///
/// By default it renders the complete flag with a medium-long pole planted into
/// the map ([showPole] = true). It follows the nearest [FlagMotionScope], so
/// one shared wind clock animates every pin on a map without giving each pin
/// its own ticker. With no scope, or with reduced motion enabled on the
/// platform, it rests at phase 0.
class FlagPinFlag extends StatelessWidget {
  final FlagStyle style;
  final double width;
  final double? height;
  final bool showPole;
  final bool isMajor;

  const FlagPinFlag({
    super.key,
    required this.style,
    this.width = 38,
    this.height,
    this.showPole = true,
    this.isMajor = false,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedHeight =
        height ?? (showPole ? width * 1.26 : null);
    return FlagMotionScope.animatedBuilder(
      context: context,
      speed: style.speed,
      builder: (context, phase) => TeritoryFlag(
        style: style,
        width: width,
        heightOverride: resolvedHeight,
        showPole: showPole,
        isMajor: isMajor,
        phase: phase,
      ),
    );
  }
}

/// Sculpted miniature terrain mound / volcano hill basement where a map flag's
/// pole is staked into the map.
///
/// Standard flags sit on a crisp, layered rocky/emerald hillock; Major flags
/// sit on a glowing obsidian lava volcano summit.
class FlagTerrainBase extends StatelessWidget {
  final Color accentColor;
  final bool isMajor;
  final double width;

  const FlagTerrainBase({
    super.key,
    required this.accentColor,
    this.isMajor = false,
    this.width = 26,
  });

  @override
  Widget build(BuildContext context) {
    final height = isMajor ? width * 0.56 : width * 0.48;
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _FlagTerrainBasePainter(
          accentColor: accentColor,
          isMajor: isMajor,
        ),
      ),
    );
  }
}

class _FlagTerrainBasePainter extends CustomPainter {
  final Color accentColor;
  final bool isMajor;

  const _FlagTerrainBasePainter({
    required this.accentColor,
    required this.isMajor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Ground contact shadow ellipse.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.5, h * 0.86),
        width: w * 0.96,
        height: h * 0.28,
      ),
      Paint()
        ..color = (isMajor ? const Color(0xFFFF5330) : Colors.black)
            .withValues(alpha: isMajor ? 0.34 : 0.28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    if (isMajor) {
      // Sculpted obsidian lava volcano cone.
      final volcano = Path()
        ..moveTo(w * 0.06, h * 0.86)
        ..quadraticBezierTo(w * 0.26, h * 0.62, w * 0.37, h * 0.22)
        ..lineTo(w * 0.63, h * 0.22)
        ..quadraticBezierTo(w * 0.74, h * 0.62, w * 0.94, h * 0.86)
        ..quadraticBezierTo(w * 0.5, h * 0.96, w * 0.06, h * 0.86)
        ..close();

      final rockPaint = Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF44403C),
            Color(0xFF1C1917),
            Color(0xFF0C0A09),
          ],
        ).createShader(Rect.fromLTWH(0, 0, w, h));
      canvas.drawPath(volcano, rockPaint);

      // Glowing lava crater rim & molten magma veins.
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(w * 0.5, h * 0.23),
          width: w * 0.30,
          height: h * 0.14,
        ),
        Paint()..color = const Color(0xFFFEF08A),
      );
      final lavaVein = Path()
        ..moveTo(w * 0.48, h * 0.25)
        ..quadraticBezierTo(w * 0.42, h * 0.52, w * 0.34, h * 0.80)
        ..moveTo(w * 0.53, h * 0.25)
        ..quadraticBezierTo(w * 0.62, h * 0.48, w * 0.68, h * 0.78);
      canvas.drawPath(
        lavaVein,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1.3, w * 0.06)
          ..strokeCap = StrokeCap.round
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFEF08A), Color(0xFFF59E0B), Color(0xFFFF5330)],
          ).createShader(Rect.fromLTWH(0, 0, w, h)),
      );

      // Crisp warm ridge outline.
      canvas.drawPath(
        volcano,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.9
          ..color = const Color(0xFFFBBF24).withValues(alpha: 0.75),
      );
    } else {
      // Classy layered rocky mountain hillock matching the flag's accent.
      final hill = Path()
        ..moveTo(w * 0.08, h * 0.85)
        ..quadraticBezierTo(w * 0.28, h * 0.35, w * 0.50, h * 0.20)
        ..quadraticBezierTo(w * 0.72, h * 0.35, w * 0.92, h * 0.85)
        ..quadraticBezierTo(w * 0.50, h * 0.95, w * 0.08, h * 0.85)
        ..close();

      final hillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(accentColor, Colors.white, 0.35)!,
            Color.lerp(accentColor, const Color(0xFF1E293B), 0.35)!,
            const Color(0xFF0F172A),
          ],
        ).createShader(Rect.fromLTWH(0, 0, w, h));
      canvas.drawPath(hill, hillPaint);

      // Sunlit summit ridge highlight.
      final ridge = Path()
        ..moveTo(w * 0.50, h * 0.20)
        ..quadraticBezierTo(w * 0.38, h * 0.46, w * 0.26, h * 0.76)
        ..lineTo(w * 0.50, h * 0.52)
        ..close();
      canvas.drawPath(
        ridge,
        Paint()..color = Colors.white.withValues(alpha: 0.28),
      );

      canvas.drawPath(
        hill,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.85
          ..color = Colors.white.withValues(alpha: 0.65),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FlagTerrainBasePainter oldDelegate) =>
      oldDelegate.accentColor != accentColor || oldDelegate.isMajor != isMajor;
}

/// A flag that waves on its own ticker, for a hero surface (studio, detail
/// sheet, ceremony) where there is exactly one flag on screen.
///
/// Respects the platform's reduce-motion setting, and a `still` style never
/// starts a ticker at all.
class AnimatedTeritoryFlag extends StatefulWidget {
  final FlagStyle style;
  final double width;
  final bool showPole;
  final bool isMajor;
  final bool animate;
  final double unfurl;
  final String? semanticLabel;

  const AnimatedTeritoryFlag({
    super.key,
    required this.style,
    this.width = 160,
    this.showPole = true,
    this.isMajor = false,
    this.animate = true,
    this.unfurl = 1.0,
    this.semanticLabel,
  });

  @override
  State<AnimatedTeritoryFlag> createState() => _AnimatedTeritoryFlagState();
}

class _AnimatedTeritoryFlagState extends State<AnimatedTeritoryFlag>
    with SingleTickerProviderStateMixin {
  static const Duration _basePeriod = Duration(milliseconds: 2600);

  late final AnimationController _controller;
  bool _running = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _basePeriod);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncTicker();
  }

  @override
  void didUpdateWidget(covariant AnimatedTeritoryFlag oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncTicker();
  }

  void _syncTicker() {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final shouldRun =
        widget.animate && widget.style.isAnimated && !reduceMotion;

    final period = Duration(
      milliseconds:
          (_basePeriod.inMilliseconds / widget.style.speed.clamp(0.5, 2.0))
              .round(),
    );
    if (_controller.duration != period) _controller.duration = period;

    if (shouldRun && !_running) {
      _controller.repeat();
      _running = true;
    } else if (!shouldRun && _running) {
      _controller.stop();
      _running = false;
    }
    if (!shouldRun && _controller.value != 0) {
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => TeritoryFlag(
        style: widget.style,
        width: widget.width,
        phase: _running ? _controller.value : 0,
        showPole: widget.showPole,
        isMajor: widget.isMajor,
        unfurl: widget.unfurl,
        semanticLabel: widget.semanticLabel,
      ),
    );
  }
}

/// The single wind clock shared by a group of flags (the home map in phase 3,
/// a gallery here). Widgets subscribe to it with an [AnimatedBuilder] on
/// [clock], so only the flags that actually need a new phase repaint.
class FlagMotionClock extends ChangeNotifier {
  double _phase = 0;

  /// Cycles in the 0–1 range.
  double get phase => _phase;

  void advance(double value) {
    if (value == _phase) return;
    _phase = value;
    notifyListeners();
  }
}

class FlagMotionScope extends InheritedWidget {
  final FlagMotionClock clock;

  const FlagMotionScope({super.key, required this.clock, required super.child});

  static FlagMotionClock? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<FlagMotionScope>()
        ?.clock;
  }

  /// Current phase, adjusted for a style's own speed.
  static double phaseOf(BuildContext context, {double speed = 1.0}) {
    final clock = maybeOf(context);
    if (clock == null) return 0;
    return (clock.phase * speed) % 1.0;
  }

  /// Builds [builder] once per wind tick instead of rebuilding the entire
  /// subtree the scope wraps.
  static Widget animatedBuilder({
    required BuildContext context,
    required Widget Function(BuildContext context, double phase) builder,
    double speed = 1.0,
  }) {
    final clock = maybeOf(context);
    if (clock == null) return builder(context, 0);
    return AnimatedBuilder(
      animation: clock,
      builder: (context, _) => builder(
        context,
        (clock.phase * speed) % 1.0,
      ),
    );
  }

  @override
  bool updateShouldNotify(FlagMotionScope oldWidget) =>
      oldWidget.clock != clock;
}

/// Owns one ticker for every flag beneath it and stops it when the platform
/// asks for reduced motion or [enabled] is false.
class FlagMotionHost extends StatefulWidget {
  final Widget child;
  final bool enabled;
  final Duration period;

  const FlagMotionHost({
    super.key,
    required this.child,
    this.enabled = true,
    this.period = const Duration(milliseconds: 2600),
  });

  @override
  State<FlagMotionHost> createState() => _FlagMotionHostState();
}

class _FlagMotionHostState extends State<FlagMotionHost>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final FlagMotionClock _clock = FlagMotionClock();
  bool _running = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.period)
      ..addListener(() => _clock.advance(_controller.value));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(covariant FlagMotionHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.period != widget.period) {
      _controller.duration = widget.period;
    }
    _sync();
  }

  void _sync() {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final shouldRun = widget.enabled && !reduceMotion;
    if (shouldRun && !_running) {
      _controller.repeat();
      _running = true;
    } else if (!shouldRun && _running) {
      _controller.stop();
      _running = false;
      _clock.advance(0);
    }
  }

  @override
  void dispose() {
    _clock.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FlagMotionScope(clock: _clock, child: widget.child);
  }
}

/// Small helper used by previews and tests: the period one full wave of
/// [style] should take, or null when it should not animate.
Duration? flagWavePeriod(FlagStyle style) {
  if (!style.isAnimated) return null;
  final ms = (2600 / style.speed.clamp(0.5, 2.0)).round();
  return Duration(milliseconds: math.max(600, ms));
}
