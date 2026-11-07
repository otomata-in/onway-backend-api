import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';

/// OnWay Market Splash Page
///
/// Uses the same particle orbit animation, background grid, and logo component
/// as the login and OTP pages for a seamless visual experience.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  late final AnimationController _orbitController;
  late final AnimationController _fadeController;
  late final AnimationController _scaleController;
  late final AnimationController _glowController;

  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();

    // Continuous particle orbit animation
    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    // Fade-in animation for the content
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    // Scale-up animation for the logo
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );

    // Logo glow breathe
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    // Start entrance animations
    Future.delayed(const Duration(milliseconds: 200), () {
      _scaleController.forward();
      _fadeController.forward();
    });

    // Auto-navigate to login after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            context.go('/login');
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _orbitController.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ─── Background Grid Pattern (same as login) ───
          Positioned.fill(
            child: Opacity(
              opacity: 0.04,
              child: CustomPaint(
                painter: _GridPatternPainter(),
              ),
            ),
          ),

          // ─── Main Content ───
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ─── Logo with Particle Orbit Animation ───
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: _buildParticleOrbitLogo(),
                  ),

                  const SizedBox(height: 24),

                  // ─── Brand Name ───
                  Text(
                    'OnWay Market',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                      letterSpacing: -0.02 * 32,
                      height: 40 / 32,
                    ),
                  ),

                  const SizedBox(height: 6),

                  // ─── Tagline ───
                  Text(
                    'Freshness, delivered efficiently.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: AppColors.onSurfaceVariant,
                      height: 20 / 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Logo with multi-ring particle orbit animation + breathing glow (same as login)
  Widget _buildParticleOrbitLogo() {
    return SizedBox(
      width: 200,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Particle orbit rings + comet trails
          AnimatedBuilder(
            animation: Listenable.merge([_orbitController, _glowController]),
            builder: (context, _) {
              return CustomPaint(
                size: const Size(200, 200),
                painter: _ParticleOrbitPainter(
                  progress: _orbitController.value,
                  glowIntensity: _glowAnimation.value,
                ),
              );
            },
          ),

          // Breathing glow behind logo
          AnimatedBuilder(
            animation: _glowAnimation,
            builder: (context, child) {
              return Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryContainer
                          .withValues(alpha: 0.18 * _glowAnimation.value),
                      blurRadius: 35 + 12 * _glowAnimation.value,
                      spreadRadius: 6 * _glowAnimation.value,
                    ),
                  ],
                ),
              );
            },
          ),

          // Central logo circle
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.surfaceDim.withValues(alpha: 0.15),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  blurRadius: 30,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: ClipOval(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Image.asset(
                  'assets/images/onway_logo.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Custom Painters (same as login_page.dart / otp_page.dart)
// ──────────────────────────────────────────────────────────────────────────────

/// Draws multiple rings of glowing particles orbiting around the logo center.
class _ParticleOrbitPainter extends CustomPainter {
  final double progress;
  final double glowIntensity;

  _ParticleOrbitPainter({
    required this.progress,
    required this.glowIntensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    final rings = [
      _RingDef(
          radius: 75,
          particles: 6,
          speed: 1.0,
          clockwise: true,
          color: const Color(0xFF22C55E),
          particleSize: 3.0,
          trailSweep: 0.4),
      _RingDef(
          radius: 86,
          particles: 4,
          speed: -0.7,
          clockwise: false,
          color: const Color(0xFF15803D),
          particleSize: 2.5,
          trailSweep: 0.5),
      _RingDef(
          radius: 97,
          particles: 8,
          speed: 0.5,
          clockwise: true,
          color: const Color(0xFF4ADE80),
          particleSize: 2.0,
          trailSweep: 0.3),
    ];

    // Draw subtle guide rings
    for (final ring in rings) {
      final guidePaint = Paint()
        ..color = ring.color.withValues(alpha: 0.06 + 0.04 * glowIntensity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8;
      canvas.drawCircle(center, ring.radius, guidePaint);
    }

    // Draw particles with comet trails
    for (final ring in rings) {
      final angle = progress * 2 * pi * ring.speed;

      for (int i = 0; i < ring.particles; i++) {
        final particleBaseAngle = angle + (2 * pi / ring.particles) * i;

        // Comet trail
        const trailSegments = 14;
        for (int s = 0; s < trailSegments; s++) {
          final t = s / trailSegments.toDouble();
          final trailAngle = particleBaseAngle -
              t * ring.trailSweep * (ring.clockwise ? 1 : -1);
          final trailX = center.dx + ring.radius * cos(trailAngle);
          final trailY = center.dy + ring.radius * sin(trailAngle);
          final trailOpacity = (1.0 - t) * (0.4 + 0.2 * glowIntensity);
          final trailSize = ring.particleSize * (1.0 - t * 0.6);

          final trailPaint = Paint()
            ..color = ring.color.withValues(alpha: trailOpacity)
            ..maskFilter =
                MaskFilter.blur(BlurStyle.normal, trailSize * 0.8);
          canvas.drawCircle(Offset(trailX, trailY), trailSize, trailPaint);
        }

        // Particle head
        final px = center.dx + ring.radius * cos(particleBaseAngle);
        final py = center.dy + ring.radius * sin(particleBaseAngle);

        // Outer glow
        final glowPaint = Paint()
          ..color = ring.color.withValues(alpha: 0.25 * glowIntensity)
          ..maskFilter =
              MaskFilter.blur(BlurStyle.normal, ring.particleSize * 3);
        canvas.drawCircle(Offset(px, py), ring.particleSize * 2, glowPaint);

        // Core
        final corePaint = Paint()
          ..color = ring.color.withValues(alpha: 0.9)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(px, py), ring.particleSize, corePaint);

        // Bright center
        final brightPaint = Paint()
          ..color = Colors.white.withValues(alpha: 0.8)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(
            Offset(px, py), ring.particleSize * 0.4, brightPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ParticleOrbitPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.glowIntensity != glowIntensity;
  }
}

class _RingDef {
  final double radius;
  final int particles;
  final double speed;
  final bool clockwise;
  final Color color;
  final double particleSize;
  final double trailSweep;

  _RingDef({
    required this.radius,
    required this.particles,
    required this.speed,
    required this.clockwise,
    required this.color,
    required this.particleSize,
    required this.trailSweep,
  });
}

/// Subtle background grid pattern (same as login)
class _GridPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    const spacing = 100.0;

    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    final diagPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    for (double i = 0; i < size.width + size.height; i += spacing * 2) {
      canvas.drawLine(Offset(i, 0), Offset(0, i), diagPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
