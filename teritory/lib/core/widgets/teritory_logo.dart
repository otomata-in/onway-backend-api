import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/teritory_theme.dart';

class TeritoryLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final bool isDark;
  final String? subtitle;

  const TeritoryLogo({
    super.key,
    this.size = 40,
    this.showText = true,
    this.isDark = false,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final iconWidget = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFF5330), // Territory Coral
            Color(0xFFF59E0B), // Radiant Gold
          ],
        ),
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF5330).withValues(alpha: 0.35),
            blurRadius: size * 0.35,
            offset: Offset(0, size * 0.12),
          ),
        ],
      ),
      child: CustomPaint(
        size: Size(size, size),
        painter: _TeritoryLogoPainter(),
      ),
    );

    if (!showText) return iconWidget;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        iconWidget,
        SizedBox(width: size * 0.25),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'TERITORY',
              style: GoogleFonts.plusJakartaSans(
                fontSize: size * 0.44,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.4,
                color: isDark ? Colors.white : TeritoryColors.textPrimary,
                height: 1.1,
              ),
            ),
            if (subtitle != null)
              Text(
                subtitle!,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: size * 0.22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: isDark
                      ? const Color(0xFFF59E0B)
                      : TeritoryColors.textSecondary,
                  height: 1.2,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// Custom painter for the iconic Teritory Flag-Pin & Globe mark
class _TeritoryLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Globe latitude/contour arc in background
    final arcPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.06
      ..strokeCap = StrokeCap.round;

    final arcPath = Path()
      ..addArc(
        Rect.fromCircle(center: Offset(w * 0.5, h * 0.65), radius: w * 0.32),
        3.14 * 0.8,
        3.14 * 1.4,
      );
    canvas.drawPath(arcPath, arcPaint);

    // 2. Stylized Mast & Staked Pin (Letter 'T' stem)
    final mastPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.09
      ..strokeCap = StrokeCap.round;

    // Mast vertical line
    canvas.drawLine(
      Offset(w * 0.38, h * 0.22),
      Offset(w * 0.38, h * 0.78),
      mastPaint,
    );

    // 3. Staked flag pin base (Ground target dot)
    final dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.38, h * 0.78), w * 0.055, dotPaint);

    // 4. Stylized Hoisted Flag (Upper T bar extending into dynamic flag pennant)
    final flagPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final flagPath = Path()
      ..moveTo(w * 0.38, h * 0.22)
      ..lineTo(w * 0.76, h * 0.30)
      ..lineTo(w * 0.64, h * 0.42)
      ..lineTo(w * 0.78, h * 0.52)
      ..lineTo(w * 0.38, h * 0.56)
      ..close();

    canvas.drawPath(flagPath, flagPaint);

    // Subtle inner notch / shadow for 3D depth
    final innerShadowPaint = Paint()
      ..color = const Color(0xFFFF5330).withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;

    final innerPath = Path()
      ..moveTo(w * 0.38, h * 0.28)
      ..lineTo(w * 0.54, h * 0.34)
      ..lineTo(w * 0.38, h * 0.44)
      ..close();

    canvas.drawPath(innerPath, innerShadowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
