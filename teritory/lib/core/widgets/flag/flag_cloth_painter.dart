import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/models/flag_style.dart';
import '../../../core/theme/flag_style_catalog.dart';

/// The single renderer for every flag in the app.
///
/// [FlagClothPainter] is size-agnostic: it lays the pole and cloth out from the
/// logical size it is given, scales the pattern and emblem with the cloth, and
/// applies the style's motion as a wind offset. A 36 px map pin, a 96 px badge
/// and a 300 px hero all come from this one code path, so the flag a traveller
/// designs is literally the flag they see everywhere.
///
/// [phase] is a wind clock in the 0–1 range. Static surfaces pass 0; animated
/// surfaces drive it from one shared clock. [still] styles ignore it entirely.
class FlagClothPainter extends CustomPainter {
  final FlagStyle style;
  final double phase;
  final bool showPole;
  final bool isMajor;
  final double unfurl;

  const FlagClothPainter({
    required this.style,
    this.phase = 0,
    this.showPole = true,
    this.isMajor = false,
    this.unfurl = 1.0,
  });

  static const Map<String, double> _waveAmplitude = {
    'still': 0.0,
    'breeze': 0.055,
    'gust': 0.085,
    'ripple': 0.050,
    'shimmer': 0.038,
    'aurora': 0.055,
    'storm': 0.120,
    'inferno': 0.075,
    'neon_pulse': 0.045,
  };

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final theme = FlagStyleCatalog.themeFor(style.theme);
    final poleX = showPole ? size.width * 0.075 : size.width * 0.02;
    final poleTop = size.height * (showPole ? 0.12 : 0.04);
    final poleTip = size.height * 0.96;

    if (showPole) {
      _paintPole(canvas, size, theme, poleX, poleTop, poleTip);
    }

    final double clothLeft;
    final double clothTop;
    final double fullWidth;
    final double clothHeight;
    if (showPole) {
      clothLeft = poleX + math.max(0.8, size.width * 0.008);
      clothTop = poleTop + size.height * 0.05;
      fullWidth = size.width - clothLeft - size.width * 0.03;
      clothHeight = math.min(size.height * 0.52, fullWidth * 0.52);
    } else {
      clothLeft = size.width * 0.02;
      clothTop = size.height * 0.06;
      fullWidth = size.width * 0.94;
      clothHeight = size.height * 0.86;
    }

    final progress = unfurl.clamp(0.0, 1.0);
    if (progress > 0.01 && clothHeight > 0.5) {
      final rect = Rect.fromLTWH(
        clothLeft,
        clothTop,
        math.max(0.5, fullWidth * progress),
        clothHeight,
      );
      _paintCloth(canvas, rect, theme);
    }

    if (showPole) {
      _paintFinial(canvas, size, theme, poleX, poleTop);
    }
  }

  // ─── Pole & finial ───────────────────────────────────────────────────

  void _paintPole(
    Canvas canvas,
    Size size,
    FlagThemeData theme,
    double x,
    double top,
    double tip,
  ) {
    final shaftWidth = math.max(isMajor ? 2.8 : 2.2, size.width * (isMajor ? 0.024 : 0.018));
    final rect = Rect.fromLTRB(x - shaftWidth / 2, top, x + shaftWidth / 2, tip);
    final basePole = isMajor ? const Color(0xFFD97706) : theme.pole;
    final polePaint = Paint()
      ..shader = LinearGradient(
        colors: isMajor
            ? const [
                Color(0xFFFEF08A),
                Color(0xFFF59E0B),
                Color(0xFF92400E),
              ]
            : [
                Color.lerp(basePole, Colors.white, 0.55)!,
                basePole,
                Color.lerp(basePole, Colors.black, 0.35)!,
              ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(rect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(shaftWidth / 2)),
      polePaint,
    );

    // A tapered stake sunk into the ground.
    final spike = Path()
      ..moveTo(x - shaftWidth / 2, tip - shaftWidth * 1.6)
      ..lineTo(x + shaftWidth / 2, tip - shaftWidth * 1.6)
      ..lineTo(x, tip)
      ..close();
    canvas.drawPath(
      spike,
      Paint()..color = isMajor ? const Color(0xFF92400E) : Color.lerp(basePole, Colors.black, 0.2)!,
    );

    // Grip rings only where they can actually be seen.
    if (size.width >= 64) {
      final gripPaint = Paint()
        ..color = Color.lerp(theme.pole, Colors.black, 0.45)!
        ..strokeWidth = math.max(1.0, shaftWidth * 0.55)
        ..strokeCap = StrokeCap.round;
      for (var i = 0; i < 3; i++) {
        final y = top + size.height * (0.42 + i * 0.035);
        canvas.drawLine(Offset(x - shaftWidth * 0.9, y), Offset(x + shaftWidth * 0.9, y), gripPaint);
      }
    }
  }

  void _paintFinial(
    Canvas canvas,
    Size size,
    FlagThemeData theme,
    double x,
    double top,
  ) {
    final radius = math.max(1.8, size.width * 0.026);
    final center = Offset(x, top);

    if (isMajor) {
      // A major wonder gets a radiant golden halo + star crown above the pole.
      final starCenter = center.translate(0, -radius * 0.85);
      canvas.drawCircle(
        starCenter,
        radius * 2.3,
        Paint()
          ..color = const Color(0xFFF59E0B).withValues(alpha: 0.32)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      _paintStar(
        canvas,
        starCenter,
        radius * 1.65,
        const Color(0xFFFBBF24),
        stroke: Colors.white,
      );
      return;
    }

    final shaderRect = Rect.fromCircle(center: center, radius: radius * 2);
    final orbPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white,
          theme.finial,
          Color.lerp(theme.finial, Colors.black, 0.4)!,
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(shaderRect);
    canvas.drawCircle(center, radius, orbPaint);

    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.7, radius * 0.22)
      ..color = Colors.white.withValues(alpha: 0.55);
    canvas.drawCircle(center, radius * 0.55, ring);
  }

  // ─── Cloth ───────────────────────────────────────────────────────────

  void _paintCloth(Canvas canvas, Rect rect, FlagThemeData theme) {
    final path = _buildClothPath(rect);
    final primary = FlagStyleCatalog.primaryColor(style);
    final motion = style.motion;

    // A hairline shadow separates the cloth from bright map tiles without an
    // expensive blur. Major flags get an extra legendary golden aura.
    if (isMajor) {
      canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0xFFF59E0B).withValues(alpha: 0.42)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
    } else if (showPole) {
      canvas.drawPath(
        path.shift(const Offset(0.8, 1.2)),
        Paint()..color = Colors.black.withValues(alpha: 0.18),
      );
    }

    canvas.save();
    canvas.clipPath(path);

    _paintClothGradient(canvas, rect, theme, primary, motion);
    _paintPattern(canvas, rect, theme, primary);
    _paintMotionLight(canvas, rect, motion);

    canvas.restore();

    _paintEmblem(canvas, rect, theme, primary);
    _paintBorder(canvas, path, rect, primary);
    // Crisp luminous rim makes every custom flag pop cleanly off bright map tiles.
    if (!isMajor) {
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(0.9, rect.height * 0.032)
          ..color = Colors.white.withValues(alpha: 0.38),
      );
    }
    if (isMajor) {
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1.2, rect.height * 0.05)
          ..color = const Color(0xFFFEF08A).withValues(alpha: 0.92),
      );
      _paintMajorSparkles(canvas, rect);
    }
    if (style.motion == 'neon_pulse') {
      _paintNeonEdge(canvas, path, theme, rect);
    }
    _paintTassels(canvas, rect, theme);

    // Metallic hoist grommet rings where the cloth attaches to the pole.
    if (showPole) {
      final ringPaint = Paint()
        ..color = isMajor ? const Color(0xFFFEF08A) : Colors.white.withValues(alpha: 0.85)
        ..strokeWidth = math.max(1.3, rect.height * 0.05)
        ..strokeCap = StrokeCap.round;
      final rLeft = rect.left - math.max(1.8, rect.width * 0.04);
      final rRight = rect.left + math.max(1.0, rect.width * 0.02);
      canvas.drawLine(Offset(rLeft, rect.top + rect.height * 0.14), Offset(rRight, rect.top + rect.height * 0.14), ringPaint);
      canvas.drawLine(Offset(rLeft, rect.bottom - rect.height * 0.14), Offset(rRight, rect.bottom - rect.height * 0.14), ringPaint);
    }
  }

  void _paintMajorSparkles(Canvas canvas, Rect rect) {
    final sparklePositions = [
      Offset(rect.right - rect.width * 0.14, rect.top + rect.height * 0.18),
      Offset(rect.left + rect.width * 0.25, rect.bottom - rect.height * 0.16),
      Offset(rect.right + rect.width * 0.06, rect.center.dy),
    ];
    for (var i = 0; i < sparklePositions.length; i++) {
      final pulse = 0.55 + 0.45 * math.sin((phase * math.pi * 2) + i * 2.1);
      final p = sparklePositions[i];
      final r = math.max(2.0, rect.height * 0.12) * (0.7 + 0.45 * pulse);
      final paint = Paint()
        ..color = const Color(0xFFFEF08A).withValues(alpha: 0.45 + 0.55 * pulse)
        ..strokeWidth = math.max(1.0, r * 0.34)
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(p.dx - r, p.dy), Offset(p.dx + r, p.dy), paint);
      canvas.drawLine(Offset(p.dx, p.dy - r), Offset(p.dx, p.dy + r), paint);
    }
  }

  void _paintClothGradient(
    Canvas canvas,
    Rect rect,
    FlagThemeData theme,
    Color primary,
    String motion,
  ) {
    var start = primary;
    var middle = theme.secondary;
    // The accent is a trailing highlight, not a third of the cloth. Dark themes
    // (pirate, hacker, rider) get only a whisper of accent so they stay dark;
    // brighter themes can carry a little more warmth at the fly.
    final accentMix = primary.computeLuminance() < 0.10 ? 0.10 : 0.30;
    var end = Color.lerp(theme.secondary, theme.accent, accentMix)!;

    if (motion == 'aurora') {
      // Evidence of life without moving a single vertex: the palette drifts.
      final shift = math.sin(phase * math.pi * 2) * 0.06;
      start = _shiftLightness(primary, shift);
      middle = _shiftLightness(theme.secondary, -shift);
      end = _shiftLightness(end, shift * 0.6);
    }

    final shader = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [start, middle, end],
      stops: const [0.0, 0.78, 1.0],
    ).createShader(rect);

    canvas.drawRect(rect, Paint()..shader = shader);

    // Silk wave fold creases give the cloth a tactile, rippling fabric look.
    final foldCount = 3;
    for (var i = 0; i < foldCount; i++) {
      final center = ((i + 0.5) / foldCount + phase * 0.35) % 1.0;
      final foldRect = Rect.fromLTWH(
        rect.left + (center - 0.14) * rect.width,
        rect.top,
        rect.width * 0.28,
        rect.height,
      );
      final foldPaint = Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.0),
            Colors.white.withValues(alpha: i.isEven ? 0.16 : 0.10),
            Colors.black.withValues(alpha: 0.12),
            Colors.black.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.35, 0.7, 1.0],
        ).createShader(foldRect);
      canvas.drawRect(foldRect, foldPaint);
    }

    // Diagonal silk sheen + bottom depth fold give every flag crisp 3D depth,
    // even at compact map pin sizes.
    final sheen = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.white.withValues(alpha: 0.24),
        Colors.white.withValues(alpha: 0.0),
        Colors.black.withValues(alpha: 0.16),
      ],
      stops: const [0.0, 0.45, 1.0],
    ).createShader(rect);
    canvas.drawRect(rect, Paint()..shader = sheen);

    // Hoist-side shading makes the cloth read as fabric rather than a rectangle.
    final shade = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        Colors.black.withValues(alpha: 0.22),
        Colors.black.withValues(alpha: 0.0),
      ],
      stops: const [0.0, 0.35],
    ).createShader(rect);
    canvas.drawRect(rect, Paint()..shader = shade);
  }

  void _paintPattern(Canvas canvas, Rect rect, FlagThemeData theme, Color primary) {
    final width = rect.width;
    final height = rect.height;
    if (width < 8 || height < 5) return;

    final ink = FlagStyleCatalog.foregroundOn(primary).withValues(alpha: 0.30);
    final accentLine = theme.accent.withValues(alpha: 0.45);
    final stroke = math.max(0.8, math.min(width, height) * 0.035);

    switch (style.pattern) {
      case 'horizon':
        final band = Rect.fromLTRB(
          rect.left,
          rect.top + height * 0.66,
          rect.right,
          rect.bottom,
        );
        canvas.drawRect(
          band,
          Paint()
            ..color = FlagStyleCatalog.foregroundOn(primary)
                .withValues(alpha: 0.18),
        );
        canvas.drawLine(
          Offset(rect.left, rect.top + height * 0.66),
          Offset(rect.right, rect.top + height * 0.66),
          Paint()
            ..color = accentLine
            ..strokeWidth = math.max(0.8, height * 0.03),
        );
        break;

      case 'chevron':
        final paint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..color = ink;
        final step = width / 4.5;
        for (var i = -1; i < 5; i++) {
          final x = rect.left + i * step;
          final path = Path()
            ..moveTo(x, rect.top)
            ..lineTo(x + step / 2, rect.center.dy)
            ..lineTo(x, rect.bottom);
          canvas.drawPath(path, paint);
        }
        break;

      case 'tide':
        final paint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..color = accentLine;
        for (var row = 1; row <= 3; row++) {
          final baseY = rect.top + height * (row / 4);
          final path = Path();
          final step = math.max(2.0, width / 16);
          for (var x = 0.0; x <= width; x += step) {
            final y = baseY + math.sin((x / width) * math.pi * 3 + row) * height * 0.045;
            if (x == 0) {
              path.moveTo(rect.left + x, y);
            } else {
              path.lineTo(rect.left + x, y);
            }
          }
          canvas.drawPath(path, paint);
        }
        break;

      case 'sunburst':
        final paint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke * 0.9
          ..color = accentLine;
        final origin = Offset(rect.left, rect.center.dy);
        final radius = width * 1.25;
        for (var i = 0; i < 14; i++) {
          final angle = -math.pi / 2 + (i / 13) * math.pi;
          canvas.drawLine(
            origin,
            origin + Offset(math.cos(angle), math.sin(angle)) * radius,
            paint,
          );
        }
        break;

      case 'constellation':
        const stars = <Offset>[
          Offset(0.30, 0.24), Offset(0.44, 0.40), Offset(0.36, 0.62),
          Offset(0.58, 0.30), Offset(0.66, 0.56), Offset(0.80, 0.38),
          Offset(0.86, 0.68), Offset(0.52, 0.78),
        ];
        final linkPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(0.6, stroke * 0.5)
          ..color = Colors.white.withValues(alpha: 0.35);
        final link = Path();
        for (var i = 0; i < stars.length; i++) {
          final point = Offset(
            rect.left + stars[i].dx * width,
            rect.top + stars[i].dy * height,
          );
          if (i == 0) {
            link.moveTo(point.dx, point.dy);
          } else {
            link.lineTo(point.dx, point.dy);
          }
        }
        canvas.drawPath(link, linkPaint);
        for (final star in stars) {
          canvas.drawCircle(
            Offset(rect.left + star.dx * width, rect.top + star.dy * height),
            math.max(0.6, math.min(width, height) * 0.018),
            Paint()..color = Colors.white.withValues(alpha: 0.85),
          );
        }
        break;

      case 'topographic':
        final paint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(0.7, stroke * 0.7)
          ..color = Colors.white.withValues(alpha: 0.28);
        final center = Offset(rect.left + width * 0.68, rect.center.dy);
        for (var i = 1; i <= 4; i++) {
          canvas.drawOval(
            Rect.fromCenter(
              center: center,
              width: width * 0.18 * i,
              height: height * 0.32 * i,
            ),
            paint,
          );
        }
        break;

      case 'weave':
        final paint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(0.5, stroke * 0.45)
          ..color = Colors.white.withValues(alpha: 0.16);
        final gap = math.max(3.0, width / 12);
        for (var x = rect.left - height; x < rect.right; x += gap) {
          canvas.drawLine(Offset(x, rect.bottom), Offset(x + height, rect.top), paint);
          canvas.drawLine(Offset(x, rect.top), Offset(x + height, rect.bottom), paint);
        }
        break;

      case 'solid':
      default:
        // The gradient is the pattern.
        break;
    }
  }

  void _paintMotionLight(Canvas canvas, Rect rect, String motion) {
    if (motion == 'storm') {
      _paintStormStreaks(canvas, rect, FlagStyleCatalog.themeFor(style.theme));
      return;
    }
    if (motion == 'inferno') {
      _paintEmbers(canvas, rect, FlagStyleCatalog.themeFor(style.theme));
      return;
    }
    if (motion != 'ripple' && motion != 'shimmer' && motion != 'gust') return;

    if (motion == 'shimmer') {
      final travel = (phase % 1.0) * 2.2 - 0.6;
      final bandX = rect.left + rect.width * travel;
      final paint = Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.0),
            Colors.white.withValues(alpha: 0.30),
            Colors.white.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromLTWH(bandX - rect.width * 0.22, rect.top, rect.width * 0.44, rect.height));
      canvas.save();
      canvas.translate(bandX, 0);
      canvas.rotate(-0.35);
      canvas.translate(-bandX, 0);
      canvas.drawRect(
        Rect.fromLTWH(bandX - rect.width * 0.22, rect.top - rect.height, rect.width * 0.44, rect.height * 3),
        paint,
      );
      canvas.restore();
      return;
    }

    // Ripple and gust: a soft highlight that travels with the wind.
    final travel = (math.sin(phase * math.pi * 2) + 1) / 2;
    final x = rect.left + rect.width * (0.15 + travel * 0.7);
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.white.withValues(alpha: 0.0),
          Colors.white.withValues(alpha: motion == 'gust' ? 0.12 : 0.18),
          Colors.white.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(rect.left, rect.top, rect.width, rect.height));
    canvas.drawRect(
      Rect.fromLTWH(x - rect.width * 0.18, rect.top, rect.width * 0.36, rect.height),
      paint,
    );
  }

  void _paintStormStreaks(Canvas canvas, Rect rect, FlagThemeData theme) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.13)
      ..strokeWidth = math.max(0.6, rect.height * 0.02)
      ..strokeCap = StrokeCap.round;
    final travel = phase % 1.0;

    for (var i = 0; i < 5; i++) {
      final x = rect.left + ((i / 5 + travel * 0.6) % 1.0) * rect.width;
      final y = rect.top + rect.height * (0.18 + i * 0.16);
      canvas.drawLine(
        Offset(x, y),
        Offset(x + rect.width * 0.16, y + rect.height * 0.12),
        paint,
      );
    }

    final edgeRect = Rect.fromLTWH(
      rect.right - rect.width * 0.06,
      rect.top,
      rect.width * 0.06,
      rect.height,
    );
    canvas.drawRect(
      edgeRect,
      Paint()
        ..shader = LinearGradient(
          colors: [Colors.transparent, theme.accent.withValues(alpha: 0.20)],
        ).createShader(edgeRect),
    );
  }

  void _paintEmbers(Canvas canvas, Rect rect, FlagThemeData theme) {
    const seeds = [0.14, 0.28, 0.41, 0.55, 0.68, 0.81, 0.92];
    final flicker = 0.55 + 0.45 * math.sin(phase * math.pi * 2 * 3);

    for (var i = 0; i < seeds.length; i++) {
      final speed = 0.6 + (i % 3) * 0.25;
      final rise = (phase * speed + i * 0.13) % 1.0;
      final x = rect.left + seeds[i] * rect.width;
      final y = rect.bottom - rise * rect.height;
      final radius = math.max(0.6, rect.height * 0.018 * (1 - rise * 0.5));
      final color = i.isEven
          ? theme.accent.withValues(alpha: 0.55 * flicker)
          : Colors.white.withValues(alpha: 0.35 * flicker);
      canvas.drawCircle(Offset(x, y), radius, Paint()..color = color);
    }
  }

  void _paintNeonEdge(
    Canvas canvas,
    Path path,
    FlagThemeData theme,
    Rect rect,
  ) {
    final pulse = 0.55 + 0.45 * math.sin(phase * math.pi * 2);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(2.0, rect.height * 0.10)
        ..color = theme.accent.withValues(alpha: 0.16 * pulse),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.9, rect.height * 0.035)
        ..color = theme.accent.withValues(alpha: 0.55 + 0.35 * pulse),
    );
  }

  void _paintBorder(Canvas canvas, Path path, Rect rect, Color primary) {
    final ink = FlagStyleCatalog.foregroundOn(primary);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.9, rect.height * 0.035)
        // A miter join spikes far past an acute pennant tip; round is calm.
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..color = ink.withValues(alpha: 0.55),
    );
  }

  void _paintTassels(Canvas canvas, Rect rect, FlagThemeData theme) {
    if (rect.width < 40) return;
    if (style.shape == 'pennant') return;

    final paint = Paint()
      ..color = theme.finial
      ..strokeWidth = math.max(1.0, rect.height * 0.03)
      ..strokeCap = StrokeCap.round;
    final wave = _waveAt(1.0) * _amplitude(rect) * 0.8;
    final top = Offset(rect.right, rect.top + wave);
    final bottom = Offset(rect.right, rect.bottom + wave * 0.8);
    final length = math.max(2.0, rect.width * 0.035);
    canvas.drawLine(top, top + Offset(length, length * 0.4), paint);
    canvas.drawLine(bottom, bottom + Offset(length, -length * 0.4), paint);
  }

  // ─── Emblem ──────────────────────────────────────────────────────────

  void _paintEmblem(Canvas canvas, Rect rect, FlagThemeData theme, Color primary) {
    if (style.emblem == 'none') return;

    final unit = math.min(rect.width, rect.height);
    final radius = unit * 0.16;
    if (radius < 3.0) return;

    final center = Offset(rect.left + rect.width * 0.27, rect.top + rect.height * 0.50);
    final discColor = theme.accent;
    canvas.drawCircle(center, radius, Paint()..color = discColor);

    final ink = FlagStyleCatalog.foregroundOn(discColor);
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(radius);
    _paintEmblemGlyph(canvas, ink, discColor, radius);
    canvas.restore();

    // A thin ring lifts the disc off a same-hue cloth.
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.6, radius * 0.10)
        ..color = ink.withValues(alpha: 0.25),
    );
  }

  /// Glyphs live in a unit circle and are scaled by the caller. [pixelRadius]
  /// keeps a hairline readable even on a 24 px pin.
  void _paintEmblemGlyph(
    Canvas canvas,
    Color ink,
    Color disc,
    double pixelRadius,
  ) {
    final fill = Paint()..color = ink;
    final cut = Paint()..color = disc;
    final stroke = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.06, 1.1 / pixelRadius)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    switch (style.emblem) {
      case 'compass':
        canvas.drawCircle(Offset.zero, 0.62, stroke);
        final needle = Path()
          ..moveTo(0.0, -0.42)
          ..lineTo(0.22, 0.12)
          ..lineTo(-0.22, 0.12)
          ..close();
        canvas.drawPath(needle, fill);
        break;

      case 'peak':
        final path = Path()
          ..moveTo(-0.62, 0.44)
          ..lineTo(-0.18, -0.42)
          ..lineTo(0.06, -0.02)
          ..lineTo(0.24, -0.24)
          ..lineTo(0.62, 0.44)
          ..close();
        canvas.drawPath(path, fill);
        break;

      case 'anchor':
        canvas.drawCircle(const Offset(0, -0.52), 0.13, stroke);
        canvas.drawLine(const Offset(0, -0.38), const Offset(0, 0.42), stroke);
        canvas.drawLine(const Offset(-0.26, -0.12), const Offset(0.26, -0.12), stroke);
        final hook = Path()
          ..moveTo(-0.44, 0.16)
          ..quadraticBezierTo(-0.34, 0.58, 0.0, 0.58)
          ..quadraticBezierTo(0.34, 0.58, 0.44, 0.16);
        canvas.drawPath(hook, stroke);
        break;

      case 'star':
        _paintStarPath(canvas, 0.62, fill);
        break;

      case 'flame':
        final flame = Path()
          ..moveTo(0.0, -0.62)
          ..cubicTo(0.38, -0.24, 0.46, 0.06, 0.22, 0.36)
          ..cubicTo(0.10, 0.52, -0.16, 0.52, -0.24, 0.30)
          ..cubicTo(-0.40, -0.02, -0.20, -0.28, 0.0, -0.62)
          ..close();
        canvas.drawPath(flame, fill);
        break;

      case 'compass_rose':
        final rose = Path()
          ..moveTo(0.0, -0.66)
          ..lineTo(0.16, -0.16)
          ..lineTo(0.66, 0.0)
          ..lineTo(0.16, 0.16)
          ..lineTo(0.0, 0.66)
          ..lineTo(-0.16, 0.16)
          ..lineTo(-0.66, 0.0)
          ..lineTo(-0.16, -0.16)
          ..close();
        canvas.drawPath(rose, fill);
        break;

      case 'paw':
        canvas.drawOval(
          Rect.fromCenter(center: const Offset(0, 0.20), width: 0.62, height: 0.50),
          fill,
        );
        for (final toe in const <Offset>[
          Offset(-0.34, -0.26),
          Offset(-0.11, -0.42),
          Offset(0.13, -0.42),
          Offset(0.35, -0.25),
        ]) {
          canvas.drawCircle(toe, 0.13, fill);
        }
        break;

      case 'skull':
        canvas.drawCircle(const Offset(0, -0.12), 0.42, fill);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: const Offset(0, 0.26),
              width: 0.46,
              height: 0.30,
            ),
            const Radius.circular(0.09),
          ),
          fill,
        );
        canvas.drawCircle(const Offset(-0.15, -0.16), 0.115, cut);
        canvas.drawCircle(const Offset(0.15, -0.16), 0.115, cut);
        canvas.drawPath(
          Path()
            ..moveTo(0, -0.02)
            ..lineTo(0.07, 0.10)
            ..lineTo(-0.07, 0.10)
            ..close(),
          cut,
        );
        for (final dx in const [-0.09, 0.0, 0.09]) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(
                center: Offset(dx, 0.27),
                width: 0.035,
                height: 0.18,
              ),
              const Radius.circular(0.01),
            ),
            cut,
          );
        }
        break;

      case 'terminal':
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: 1.05, height: 0.80),
            const Radius.circular(0.14),
          ),
          stroke,
        );
        canvas.drawPath(
          Path()
            ..moveTo(-0.34, -0.18)
            ..lineTo(-0.10, 0.02)
            ..lineTo(-0.34, 0.22),
          stroke,
        );
        canvas.drawLine(
          const Offset(0.02, 0.22),
          const Offset(0.36, 0.22),
          stroke,
        );
        break;

      case 'helmet':
        canvas.drawCircle(const Offset(0, 0.0), 0.46, fill);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: const Offset(0.04, -0.05),
              width: 0.62,
              height: 0.20,
            ),
            const Radius.circular(0.07),
          ),
          cut,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: const Offset(-0.02, 0.30),
              width: 0.42,
              height: 0.09,
            ),
            const Radius.circular(0.04),
          ),
          cut,
        );
        break;

      case 'bike_road':
        _paintBikeFrame(canvas, stroke, mountain: false);
        break;

      case 'bike_mountain':
        _paintBikeFrame(canvas, stroke, mountain: true);
        break;

      case 'bike_moto':
        _paintMotorbike(canvas, stroke, fill, cut);
        break;

      case 'car_sedan':
        _paintCar(canvas, stroke, fill, cut, 'sedan');
        break;

      case 'car_suv':
        _paintCar(canvas, stroke, fill, cut, 'suv');
        break;

      case 'car_sports':
        _paintCar(canvas, stroke, fill, cut, 'sports');
        break;

      default:
        break;
    }
  }

  void _paintBikeFrame(Canvas canvas, Paint stroke, {required bool mountain}) {
    final tire = Paint()
      ..color = stroke.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = mountain ? stroke.strokeWidth * 1.9 : stroke.strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(const Offset(-0.40, 0.28), 0.20, tire);
    canvas.drawCircle(const Offset(0.40, 0.28), 0.20, tire);

    canvas.drawPath(
      Path()
        ..moveTo(-0.40, 0.28)
        ..lineTo(-0.04, 0.28)
        ..lineTo(-0.20, -0.10)
        ..lineTo(0.10, -0.10)
        ..lineTo(0.40, 0.28)
        ..moveTo(-0.04, 0.28)
        ..lineTo(0.10, -0.10),
      stroke,
    );

    canvas.drawLine(const Offset(-0.30, -0.14), const Offset(-0.08, -0.14), stroke);

    if (mountain) {
      canvas.drawLine(const Offset(0.18, -0.10), const Offset(0.12, 0.08), stroke);
      canvas.drawLine(const Offset(0.02, -0.28), const Offset(0.24, -0.28), stroke);
      canvas.drawLine(const Offset(0.10, -0.10), const Offset(0.13, -0.28), stroke);
    } else {
      canvas.drawPath(
        Path()
          ..moveTo(0.10, -0.10)
          ..lineTo(0.02, -0.28)
          ..lineTo(0.22, -0.28),
        stroke,
      );
    }
  }

  void _paintMotorbike(Canvas canvas, Paint stroke, Paint fill, Paint cut) {
    final tire = Paint()
      ..color = stroke.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke.strokeWidth * 1.6
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(const Offset(-0.38, 0.28), 0.17, tire);
    canvas.drawCircle(const Offset(0.38, 0.28), 0.17, tire);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(0, 0.06), width: 0.58, height: 0.22),
        const Radius.circular(0.07),
      ),
      fill,
    );

    canvas.drawPath(
      Path()
        ..moveTo(0.26, 0.06)
        ..lineTo(0.38, 0.28)
        ..moveTo(0.20, -0.02)
        ..lineTo(0.30, -0.24)
        ..lineTo(0.42, -0.24),
      stroke,
    );
    canvas.drawCircle(const Offset(-0.24, 0.20), 0.07, cut);
  }

  void _paintCar(
    Canvas canvas,
    Paint stroke,
    Paint fill,
    Paint cut,
    String kind,
  ) {
    final tires = Paint()..color = stroke.color;
    final hub = Paint()..color = cut.color;
    final wheelRadius = kind == 'suv' ? 0.16 : 0.13;

    if (kind == 'suv') {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: const Offset(0, 0.04), width: 1.20, height: 0.38),
          const Radius.circular(0.10),
        ),
        fill,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: const Offset(0, -0.22), width: 0.86, height: 0.32),
          const Radius.circular(0.08),
        ),
        fill,
      );
      canvas.drawLine(const Offset(-0.36, -0.40), const Offset(0.36, -0.40), stroke);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: const Offset(0, -0.20), width: 0.64, height: 0.16),
          const Radius.circular(0.04),
        ),
        cut,
      );
    } else if (kind == 'sports') {
      canvas.drawPath(
        Path()
          ..moveTo(-0.66, 0.20)
          ..lineTo(-0.48, 0.02)
          ..lineTo(-0.16, -0.08)
          ..lineTo(0.08, -0.26)
          ..lineTo(0.34, -0.10)
          ..lineTo(0.60, 0.04)
          ..lineTo(0.64, 0.20)
          ..close(),
        fill,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: const Offset(0.42, -0.34), width: 0.26, height: 0.06),
          const Radius.circular(0.02),
        ),
        fill,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: const Offset(0.08, -0.14), width: 0.34, height: 0.13),
          const Radius.circular(0.03),
        ),
        cut,
      );
    } else {
      canvas.drawPath(
        Path()
          ..moveTo(-0.62, 0.20)
          ..lineTo(-0.56, -0.02)
          ..lineTo(-0.28, -0.06)
          ..lineTo(-0.10, -0.30)
          ..lineTo(0.22, -0.30)
          ..lineTo(0.42, -0.06)
          ..lineTo(0.62, -0.02)
          ..lineTo(0.62, 0.20)
          ..close(),
        fill,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: const Offset(0, -0.15), width: 0.46, height: 0.16),
          const Radius.circular(0.04),
        ),
        cut,
      );
    }

    for (final x in const [-0.38, 0.38]) {
      canvas.drawCircle(Offset(x, 0.28), wheelRadius, tires);
      canvas.drawCircle(Offset(x, 0.28), wheelRadius * 0.45, hub);
    }
  }

  void _paintStar(Canvas canvas, Offset center, double radius, Color color, {Color? stroke}) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(radius);
    _paintStarPath(canvas, 1.0, Paint()..color = color);
    if (stroke != null) {
      canvas.drawPath(
        _starPath(1.0),
        Paint()
          ..color = stroke
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.12
          ..strokeJoin = StrokeJoin.round,
      );
    }
    canvas.restore();
  }

  void _paintStarPath(Canvas canvas, double radius, Paint paint) {
    canvas.drawPath(_starPath(radius), paint);
  }

  Path _starPath(double radius) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final r = i.isEven ? radius : radius * 0.44;
      final angle = -math.pi / 2 + i * math.pi / 5;
      final point = Offset(math.cos(angle) * r, math.sin(angle) * r);
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    return path..close();
  }

  // ─── Geometry ────────────────────────────────────────────────────────

  /// Normalised outline, clockwise from the hoist's top corner.
  List<Offset> _outlineFor(String shape) {
    switch (shape) {
      case 'swallowtail':
        return const [
          Offset(0, 0),
          Offset(1, 0),
          Offset(0.78, 0.5),
          Offset(1, 1),
          Offset(0, 1),
        ];
      case 'pennant':
        return const [Offset(0, 0), Offset(1, 0.5), Offset(0, 1)];
      case 'burgee':
        return const [
          Offset(0, 0),
          Offset(1, 0),
          Offset(0.62, 0.5),
          Offset(1, 1),
          Offset(0, 1),
        ];
      case 'classic':
      default:
        return const [Offset(0, 0), Offset(1, 0), Offset(1, 1), Offset(0, 1)];
    }
  }

  Path _buildClothPath(Rect rect) {
    final outline = _outlineFor(style.shape);
    final steps = ((rect.width / 7).clamp(2, 14)).round();
    final amplitude = _amplitude(rect);
    final path = Path();
    var started = false;

    for (var edge = 0; edge < outline.length; edge++) {
      final from = outline[edge];
      final to = outline[(edge + 1) % outline.length];
      for (var step = 0; step <= steps; step++) {
        if (edge > 0 && step == 0) continue; // shared corner
        final t = step / steps;
        final x = from.dx + (to.dx - from.dx) * t;
        final y = from.dy + (to.dy - from.dy) * t;
        final wave = _waveAt(x) * amplitude * (0.25 + 0.75 * x);
        final point = Offset(
          rect.left + x * rect.width,
          rect.top + y * rect.height + wave,
        );
        if (!started) {
          path.moveTo(point.dx, point.dy);
          started = true;
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
    }

    return path..close();
  }

  double _amplitude(Rect rect) {
    final factor = _waveAmplitude[style.motion] ?? 0.0;
    if (factor == 0) return 0;
    return rect.height * factor;
  }

  /// One wind cycle as a function of the normalised position across the cloth.
  /// The hoist is pinned by the caller's [0.25 + 0.75x] weight, so the pole
  /// edge never detaches from the staff.
  double _waveAt(double x) {
    if (style.motion == 'still') return 0;
    final p = phase * math.pi * 2;

    switch (style.motion) {
      case 'gust':
        return math.sin(x * 3.1 * math.pi - p) * 0.62 +
            math.sin(x * 7.3 * math.pi - p * 1.6) * 0.28 +
            math.sin(x * 12.0 * math.pi - p * 0.8) * 0.10;
      case 'ripple':
        return math.sin(x * 3.4 * math.pi - p) * 0.78 +
            math.sin(x * 6.1 * math.pi - p * 1.3) * 0.22;
      case 'shimmer':
        return math.sin(x * 2.2 * math.pi - p) * 0.55;
      case 'aurora':
        return math.sin(x * 1.7 * math.pi - p) * 0.65 +
            math.sin(x * 4.2 * math.pi - p * 0.6) * 0.35;
      case 'storm':
        return math.sin(x * 2.6 * math.pi - p) * 0.45 +
            math.sin(x * 6.4 * math.pi - p * 1.8) * 0.30 +
            math.sin(x * 13.0 * math.pi - p * 0.9) * 0.25;
      case 'inferno':
        return math.sin(x * 4.2 * math.pi - p * 1.6) * 0.70 +
            math.sin(x * 9.1 * math.pi - p * 2.4) * 0.30;
      case 'neon_pulse':
        return math.sin(x * 1.8 * math.pi - p) * 0.80;
      case 'breeze':
      default:
        return math.sin(x * 2.4 * math.pi - p);
    }
  }

  Color _shiftLightness(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness + amount).clamp(0.05, 0.95))
        .toColor();
  }

  @override
  bool shouldRepaint(covariant FlagClothPainter oldDelegate) {
    return oldDelegate.style != style ||
        oldDelegate.phase != phase ||
        oldDelegate.showPole != showPole ||
        oldDelegate.isMajor != isMajor ||
        oldDelegate.unfurl != unfurl;
  }
}
