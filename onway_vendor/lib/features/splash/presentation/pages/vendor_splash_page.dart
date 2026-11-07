import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';

/// OnWay Partner Splash Page - Exactly matching buyer app design
class VendorSplashPage extends StatefulWidget {
  final VoidCallback onSplashComplete;
  const VendorSplashPage({super.key, required this.onSplashComplete});

  @override
  State<VendorSplashPage> createState() => _VendorSplashPageState();
}

class _VendorSplashPageState extends State<VendorSplashPage> with TickerProviderStateMixin {
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

    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _scaleController.forward();
        _fadeController.forward();
      }
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        widget.onSplashComplete();
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
      backgroundColor: AppColors.surface,
      body: Stack(
        children: [
          // Background Grid Pattern
          Positioned.fill(
            child: Opacity(
              opacity: 0.04,
              child: CustomPaint(
                painter: _GridPatternPainter(),
              ),
            ),
          ),

          // Main Content
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo with Particle Orbit Animation
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: _buildParticleOrbitLogo(),
                  ),
                  const SizedBox(height: 24),
                  // Brand Name
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
                  // Tagline
                  Text(
                    'Freshness, delivered efficiently.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: AppColors.outline,
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

  Widget _buildParticleOrbitLogo() {
    return SizedBox(
      width: 200,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
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
                      color: AppColors.primary.withValues(alpha: 0.18 * _glowAnimation.value),
                      blurRadius: 35 + 12 * _glowAnimation.value,
                      spreadRadius: 6 * _glowAnimation.value,
                    ),
                  ],
                ),
              );
            },
          ),
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.surfaceContainerHigh.withValues(alpha: 0.15),
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
      _RingDef(radius: 75, particles: 6, speed: 1.0, clockwise: true, color: const Color(0xFF22C55E), particleSize: 3.0, trailSweep: 0.4),
      _RingDef(radius: 86, particles: 4, speed: -0.7, clockwise: false, color: const Color(0xFF15803D), particleSize: 2.5, trailSweep: 0.5),
      _RingDef(radius: 97, particles: 8, speed: 0.5, clockwise: true, color: const Color(0xFF4ADE80), particleSize: 2.0, trailSweep: 0.3),
    ];

    for (final ring in rings) {
      final guidePaint = Paint()
        ..color = ring.color.withValues(alpha: 0.06 + 0.04 * glowIntensity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8;
      canvas.drawCircle(center, ring.radius, guidePaint);
    }

    for (final ring in rings) {
      final angle = progress * 2 * pi * ring.speed;

      for (int i = 0; i < ring.particles; i++) {
        final particleBaseAngle = angle + (2 * pi / ring.particles) * i;
        const trailSegments = 14;
        for (int s = 0; s < trailSegments; s++) {
          final t = s / trailSegments.toDouble();
          final trailAngle = particleBaseAngle - t * ring.trailSweep * (ring.clockwise ? 1 : -1);
          final trailX = center.dx + ring.radius * cos(trailAngle);
          final trailY = center.dy + ring.radius * sin(trailAngle);
          final trailOpacity = (1.0 - t) * (0.4 + 0.2 * glowIntensity);
          final trailSize = ring.particleSize * (1.0 - t * 0.6);

          final trailPaint = Paint()
            ..color = ring.color.withValues(alpha: trailOpacity)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, trailSize * 0.8);
          canvas.drawCircle(Offset(trailX, trailY), trailSize, trailPaint);
        }

        final px = center.dx + ring.radius * cos(particleBaseAngle);
        final py = center.dy + ring.radius * sin(particleBaseAngle);

        final glowPaint = Paint()
          ..color = ring.color.withValues(alpha: 0.25 * glowIntensity)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, ring.particleSize * 3);
        canvas.drawCircle(Offset(px, py), ring.particleSize * 2, glowPaint);

        final corePaint = Paint()
          ..color = ring.color.withValues(alpha: 0.9)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(px, py), ring.particleSize, corePaint);

        final brightPaint = Paint()
          ..color = Colors.white.withValues(alpha: 0.8)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(px, py), ring.particleSize * 0.4, brightPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ParticleOrbitPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.glowIntensity != glowIntensity;
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
