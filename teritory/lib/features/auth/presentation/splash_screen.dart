import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/teritory_theme.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TeritoryColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: TeritoryColors.primaryLight,
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.flag_rounded,
                size: 36,
                color: TeritoryColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Teritory',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: TeritoryColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Restoring your session…',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: TeritoryColors.textSecondary,
              ),
            ),
            const SizedBox(height: 28),
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: TeritoryColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
