import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../bloc/login_bloc.dart';

/// OnWay Market Login Page
///
/// Features:
/// - Multi-ring particle orbit animation around logo
/// - Glassmorphism login card
/// - Indian flag + +91 country code prefix
/// - Gradient "Send OTP" button with pulsing glow
/// - Secure login footer badge
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LoginBloc(),
      child: const _LoginView(),
    );
  }
}

class _LoginView extends StatefulWidget {
  const _LoginView();

  @override
  State<_LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<_LoginView> with TickerProviderStateMixin {
  late final AnimationController _orbitController;
  late final AnimationController _fadeController;
  late final AnimationController _pulseController;
  late final AnimationController _glowController;

  late final Animation<double> _fadeAnimation;
  late final Animation<double> _pulseAnimation;
  late final Animation<double> _glowAnimation;

  final _phoneController = TextEditingController();
  final _phoneFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    // Main orbit spin — controls all particle rings
    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    // Entrance fade-in
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();

    // Button pulse
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );

    // Logo glow breathe
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _orbitController.dispose();
    _fadeController.dispose();
    _pulseController.dispose();
    _glowController.dispose();
    _phoneController.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<LoginBloc, LoginState>(
      listener: (context, state) {
        if (state.status == LoginStatus.failure && state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
        if (state.status == LoginStatus.success) {
          context.push('/otp', extra: state.phone);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom,
                child: Stack(
                  children: [
                    // ─── Background Grid Pattern ───
                    _buildBackgroundPattern(),

                    // ─── Main Content ───
                    Positioned.fill(
                      child: Column(
                        children: [
                          const Spacer(flex: 1),

                          // ─── Logo + Particle Orbit Animation ───
                          _buildParticleOrbitLogo(),

                          const SizedBox(height: 12),

                          // ─── Welcome Text ───
                          _buildWelcomeText(),

                          const SizedBox(height: 20),

                          // ─── Login Card ───
                          _buildLoginCard(context),

                          const Spacer(flex: 2),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Subtle floating grid background
  Widget _buildBackgroundPattern() {
    return Positioned.fill(
      child: Opacity(
        opacity: 0.04,
        child: CustomPaint(
          painter: _GridPatternPainter(),
        ),
      ),
    );
  }

  /// Logo with multi-ring particle orbit animation + breathing glow
  Widget _buildParticleOrbitLogo() {
    return SizedBox(
      width: 180,
      height: 180,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Particle orbit rings + comet trails
          AnimatedBuilder(
            animation: Listenable.merge([_orbitController, _glowController]),
            builder: (context, _) {
              return CustomPaint(
                size: const Size(180, 180),
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
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryContainer.withValues(alpha: 0.15 * _glowAnimation.value),
                      blurRadius: 30 + 10 * _glowAnimation.value,
                      spreadRadius: 5 * _glowAnimation.value,
                    ),
                  ],
                ),
              );
            },
          ),

          // Central logo circle
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.surface,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipOval(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Image.asset(
                  'assets/images/onway_login_logo.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// "Welcome to OnWay" heading + subtitle (scaled down)
  Widget _buildWelcomeText() {
    return Column(
      children: [
        Text(
          'Welcome to OnWay',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
            height: 28 / 20,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Fresh groceries delivered fast.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: AppColors.outline,
            height: 18 / 12,
          ),
        ),
      ],
    );
  }

  /// Glassmorphism login card with phone input + Send OTP button (scaled down)
  Widget _buildLoginCard(BuildContext context) {
    return BlocBuilder<LoginBloc, LoginState>(
      builder: (context, state) {
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.5),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryContainer.withValues(alpha: 0.05),
                blurRadius: 24,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 16,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              // Title
              Text(
                'Login / Sign Up',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                  height: 24 / 18,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Enter your mobile number',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: AppColors.outline,
                  height: 18 / 12,
                ),
              ),
              const SizedBox(height: 20),

              // ─── Phone Input ───
              _buildPhoneInput(context, state),

              const SizedBox(height: 12),

              // ─── Send OTP Button ───
              _buildSendOtpButton(context, state),

              const SizedBox(height: 10),

              // ─── Secure Login Badge ───
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 14,
                    color: AppColors.onSurface.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Secure & Fast Login with OTP',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: AppColors.onSurface,
                      height: 14 / 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  /// Phone number input field with 🇮🇳 +91 prefix (scaled down)
  Widget _buildPhoneInput(BuildContext context, LoginState state) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _phoneFocusNode.hasFocus
              ? AppColors.primaryContainer
              : AppColors.surfaceVariant,
          width: _phoneFocusNode.hasFocus ? 2 : 1,
        ),
        boxShadow: _phoneFocusNode.hasFocus
            ? [
                BoxShadow(
                  color: AppColors.primaryContainer.withValues(alpha: 0.2),
                  blurRadius: 10,
                  spreadRadius: 0,
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Row(
        children: [
          // Country code section
          Container(
            padding: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(
                  color: AppColors.surfaceVariant,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                const Text('🇮🇳', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Text(
                  '+91',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                    letterSpacing: 0.12,
                    height: 16 / 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Phone number input
          Expanded(
            child: TextField(
              controller: _phoneController,
              focusNode: _phoneFocusNode,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: AppColors.onSurface,
                height: 20 / 14,
              ),
              decoration: InputDecoration(
                hintText: 'Mobile Number',
                hintStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: AppColors.outline.withValues(alpha: 0.5),
                  height: 20 / 14,
                ),
                border: InputBorder.none,
                counterText: '',
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                isDense: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              onChanged: (value) {
                context.read<LoginBloc>().add(LoginPhoneChanged(value));
                setState(() {}); // Refresh focus border
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Gradient "Send OTP" button with pulse animation (scaled down)
  Widget _buildSendOtpButton(BuildContext context, LoginState state) {
    final isLoading = state.status == LoginStatus.loading;

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        final pulseValue = _pulseAnimation.value;
        final pulseOpacity = (1.0 - pulseValue) * 0.4;
        final pulseRadius = pulseValue * 8;

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            boxShadow: state.isPhoneValid
                ? [
                    BoxShadow(
                      color: AppColors.primaryContainer.withValues(alpha: pulseOpacity),
                      blurRadius: pulseRadius,
                      spreadRadius: pulseRadius * 0.5,
                    ),
                  ]
                : null,
          ),
          child: child,
        );
      },
      child: SizedBox(
        width: double.infinity,
        height: 42,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primaryContainer,
                AppColors.secondary,
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.25),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isLoading
                  ? null
                  : () {
                      context.read<LoginBloc>().add(const LoginSendOtpPressed());
                    },
              borderRadius: BorderRadius.circular(999),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    const SizedBox(width: 32), // Balance the arrow on the right
                    Expanded(
                      child: Center(
                        child: isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                'Send OTP',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.onPrimary,
                                  letterSpacing: 0.12,
                                  height: 16 / 12,
                                ),
                              ),
                      ),
                    ),
                    // Arrow circle
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_forward,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Custom Painters
// ──────────────────────────────────────────────────────────────────────────────

/// Draws multiple rings of glowing particles orbiting around the logo center.
/// Each ring has different speed, direction, particle count, and color.
/// Particles leave comet-like gradient trails.
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

    // ── Ring definitions ──
    // Each ring: radius, particle count, speed multiplier, direction, color, particle size, trail length
    final rings = [
      _RingDef(radius: 68, particles: 6, speed: 1.0, clockwise: true,
          color: const Color(0xFF22C55E), particleSize: 3.0, trailSweep: 0.4),
      _RingDef(radius: 78, particles: 4, speed: -0.7, clockwise: false,
          color: const Color(0xFF15803D), particleSize: 2.5, trailSweep: 0.5),
      _RingDef(radius: 88, particles: 8, speed: 0.5, clockwise: true,
          color: const Color(0xFF4ADE80), particleSize: 2.0, trailSweep: 0.3),
    ];

    // Draw subtle guide rings
    for (final ring in rings) {
      final guidePaint = Paint()
        ..color = ring.color.withValues(alpha: 0.06 + 0.04 * glowIntensity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8;
      canvas.drawCircle(center, ring.radius, guidePaint);
    }

    // Draw particles with comet trails for each ring
    for (final ring in rings) {
      final angle = progress * 2 * pi * ring.speed;

      for (int i = 0; i < ring.particles; i++) {
        final particleBaseAngle = angle + (2 * pi / ring.particles) * i;

        // ── Draw comet trail ──
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

        // ── Draw particle head ──
        final px = center.dx + ring.radius * cos(particleBaseAngle);
        final py = center.dy + ring.radius * sin(particleBaseAngle);

        // Outer glow
        final glowPaint = Paint()
          ..color = ring.color.withValues(alpha: 0.25 * glowIntensity)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, ring.particleSize * 3);
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
        canvas.drawCircle(Offset(px, py), ring.particleSize * 0.4, brightPaint);
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

/// Subtle background grid pattern
class _GridPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    const spacing = 100.0;

    // Horizontal lines
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    // Vertical lines
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Diagonal accents
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
