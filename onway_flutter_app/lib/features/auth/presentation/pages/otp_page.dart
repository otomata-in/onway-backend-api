import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../bloc/otp_bloc.dart';
import '../bloc/otp_event.dart';
import '../bloc/otp_state.dart';

/// OnWay Market OTP Verification Page
///
/// Uses the exact same layout, background, logo, and particle orbit animation
/// as the Login page. Only the glassmorphic card content differs (OTP input
/// instead of phone input). Back button is preserved.
class OtpPage extends StatelessWidget {
  final String phone;
  const OtpPage({super.key, required this.phone});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => OtpBloc(phone: phone),
      child: _OtpView(phone: phone),
    );
  }
}

class _OtpView extends StatefulWidget {
  final String phone;
  const _OtpView({required this.phone});

  @override
  State<_OtpView> createState() => _OtpViewState();
}

class _OtpViewState extends State<_OtpView> with TickerProviderStateMixin {
  late final AnimationController _orbitController;
  late final AnimationController _fadeController;
  late final AnimationController _glowController;

  late final Animation<double> _fadeAnimation;
  late final Animation<double> _glowAnimation;

  final List<TextEditingController> _controllers =
      List.generate(5, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(5, (_) => FocusNode());

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

    // Logo glow breathe
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    for (int i = 0; i < 5; i++) {
      _controllers[i].addListener(() => _onCodeInput(i));
    }
  }

  void _onCodeInput(int index) {
    if (_controllers[index].text.isNotEmpty && index < 4) {
      _focusNodes[index + 1].requestFocus();
    }

    // Update BLoC
    final code = _controllers.map((c) => c.text).join();
    context.read<OtpBloc>().add(OtpCodeChanged(code));
  }

  @override
  void dispose() {
    _orbitController.dispose();
    _fadeController.dispose();
    _glowController.dispose();
    for (var c in _controllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<OtpBloc, OtpState>(
      listener: (context, state) {
        if (state.status == OtpStatus.failure && state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
        if (state.status == OtpStatus.success) {
          context.go('/home');
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Stack(
              children: [
                // ─── Background Grid Pattern (same as login) ───
                _buildBackgroundPattern(),

                // ─── Main Content ───
                Positioned.fill(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height -
                          MediaQuery.of(context).padding.top -
                          MediaQuery.of(context).padding.bottom,
                      child: Column(
                        children: [
                          const Spacer(flex: 1),

                          // ─── Logo + Particle Orbit Animation (same as login) ───
                          _buildParticleOrbitLogo(),

                          const SizedBox(height: 12),

                          // ─── Heading Text ───
                          _buildHeadingText(),

                          const SizedBox(height: 20),

                          // ─── OTP Verification Card ───
                          _buildOtpCard(context),

                          const Spacer(flex: 2),
                        ],
                      ),
                    ),
                  ),
                ),

                // ─── Back Button ───
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, size: 20),
                      onPressed: () => context.pop(),
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Subtle floating grid background (same as login)
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

  /// Logo with multi-ring particle orbit animation + breathing glow (same as login)
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
                      color: AppColors.primaryContainer
                          .withValues(alpha: 0.15 * _glowAnimation.value),
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

  /// Heading text (same style as login "Welcome to OnWay")
  Widget _buildHeadingText() {
    return Column(
      children: [
        Text(
          'Verify Your Number',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
            height: 28 / 20,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'One last step to get started.',
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

  /// Glassmorphic OTP verification card
  Widget _buildOtpCard(BuildContext context) {
    return BlocBuilder<OtpBloc, OtpState>(
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
                color:
                    AppColors.primaryContainer.withValues(alpha: 0.05),
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
              // Card title
              Text(
                'Verify Number',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                  height: 24 / 18,
                ),
              ),
              const SizedBox(height: 4),

              // Subtitle with phone number + edit icon
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'Code sent to ',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    widget.phone.isNotEmpty ? '+91 ${widget.phone}' : '+91 ••••••••••',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: () => context.pop(),
                    child: Icon(
                      Icons.edit,
                      size: 14,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ─── OTP Fields ───
              _buildOtpFields(state),

              const SizedBox(height: 16),

              // ─── Verify Button ───
              _buildVerifyButton(context, state),

              const SizedBox(height: 14),

              // ─── Resend Timer ───
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Didn\'t receive the code? ',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  InkWell(
                    onTap: state.canResend
                        ? () => context
                            .read<OtpBloc>()
                            .add(const OtpResendPressed())
                        : null,
                    child: Text(
                      state.canResend
                          ? 'Resend Now'
                          : 'Resend in 00:${state.timerDuration.toString().padLeft(2, '0')}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: state.canResend
                            ? AppColors.primary
                            : AppColors.primary.withValues(alpha: 0.5),
                        decoration: state.canResend
                            ? TextDecoration.underline
                            : null,
                      ),
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

  /// 5-digit OTP input fields (compact)
  Widget _buildOtpFields(OtpState state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(5, (index) {
        return SizedBox(
          width: 44,
          height: 48,
          child: TextField(
            controller: _controllers[index],
            focusNode: _focusNodes[index],
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 1,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
            decoration: InputDecoration(
              counterText: '',
              hintText: '-',
              hintStyle: TextStyle(
                color: AppColors.outlineVariant,
                fontSize: 14,
              ),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.5),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppColors.outlineVariant),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppColors.outlineVariant),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                    color: AppColors.primaryContainer, width: 2),
              ),
            ),
            onChanged: (value) {
              if (value.isEmpty && index > 0) {
                _focusNodes[index - 1].requestFocus();
              }
            },
          ),
        );
      }),
    );
  }

  /// Gradient "Verify & Proceed" button (same style as login's Send OTP)
  Widget _buildVerifyButton(BuildContext context, OtpState state) {
    final isLoading = state.status == OtpStatus.loading;

    return SizedBox(
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
                    context
                        .read<OtpBloc>()
                        .add(const OtpVerifyPressed());
                  },
            borderRadius: BorderRadius.circular(999),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  const SizedBox(width: 32),
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
                              'Verify & Proceed',
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
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Custom Painters (identical to login_page.dart)
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
          radius: 68,
          particles: 6,
          speed: 1.0,
          clockwise: true,
          color: const Color(0xFF22C55E),
          particleSize: 3.0,
          trailSweep: 0.4),
      _RingDef(
          radius: 78,
          particles: 4,
          speed: -0.7,
          clockwise: false,
          color: const Color(0xFF15803D),
          particleSize: 2.5,
          trailSweep: 0.5),
      _RingDef(
          radius: 88,
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
