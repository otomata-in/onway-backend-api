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
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF144F87).withValues(alpha: 0.30),
            blurRadius: size * 0.25,
            offset: Offset(0, size * 0.08),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/images/teritory_logo.png',
          width: size,
          height: size,
          fit: BoxFit.contain,
        ),
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

