import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/network/api_service.dart';

/// OnWay Partner Login & OTP Page - Exactly matching buyer app design
class VendorLoginPage extends StatefulWidget {
  final VoidCallback onLoginSuccess;
  const VendorLoginPage({super.key, required this.onLoginSuccess});

  @override
  State<VendorLoginPage> createState() => _VendorLoginPageState();
}

class _VendorLoginPageState extends State<VendorLoginPage> with TickerProviderStateMixin {
  late final AnimationController _orbitController;
  late final AnimationController _fadeController;
  late final AnimationController _pulseController;
  late final AnimationController _glowController;

  late final Animation<double> _fadeAnimation;
  late final Animation<double> _pulseAnimation;
  late final Animation<double> _glowAnimation;

  final _phoneController = TextEditingController(text: '9876543210');
  final _phoneFocusNode = FocusNode();

  final List<TextEditingController> _otpControllers = List.generate(5, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(5, (_) => FocusNode());

  bool _isOtpStep = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    for (int i = 0; i < 5; i++) {
      _otpControllers[i].addListener(() => _onOtpCodeInput(i));
    }
  }

  void _onOtpCodeInput(int index) {
    if (_otpControllers[index].text.isNotEmpty && index < 4) {
      _otpFocusNodes[index + 1].requestFocus();
    }
  }

  Future<void> _handleSendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a valid 10-digit mobile number', style: GoogleFonts.plusJakartaSans()),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }
    setState(() => _isLoading = true);
    final response = await VendorApiService().sendOtp(phone);
    if (mounted) {
      setState(() => _isLoading = false);
      if (response['success'] == true) {
        setState(() => _isOtpStep = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('OTP sent to +91 $phone via Twilio', style: GoogleFonts.plusJakartaSans(color: Colors.white)),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['error'] ?? 'Failed to send OTP. Please try again.', style: GoogleFonts.plusJakartaSans()),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Future<void> _handleVerifyOtp() async {
    final otpCode = _otpControllers.map((c) => c.text).join().trim();
    if (otpCode.length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter 5-digit OTP code', style: GoogleFonts.plusJakartaSans()),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }
    setState(() => _isLoading = true);
    final phone = _phoneController.text.trim();
    final response = await VendorApiService().verifyOtp(
      phone: phone,
      otpCode: otpCode,
    );
    if (mounted) {
      setState(() => _isLoading = false);
      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login verified successfully!', style: GoogleFonts.plusJakartaSans(color: Colors.white)),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        widget.onLoginSuccess();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['error'] ?? 'Invalid or expired OTP', style: GoogleFonts.plusJakartaSans()),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _orbitController.dispose();
    _fadeController.dispose();
    _pulseController.dispose();
    _glowController.dispose();
    _phoneController.dispose();
    _phoneFocusNode.dispose();
    for (var c in _otpControllers) {
      c.dispose();
    }
    for (var f in _otpFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
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
                  Positioned.fill(
                    child: Column(
                      children: [
                        const Spacer(flex: 1),

                        // Logo + Particle Orbit Animation
                        _buildParticleOrbitLogo(),

                        const SizedBox(height: 12),

                        // Welcome Text / Heading Text
                        _buildHeadingText(),

                        const SizedBox(height: 20),

                        // Login / OTP Card
                        if (!_isOtpStep)
                          _buildLoginCard(context)
                        else
                          _buildOtpCard(context),

                        const Spacer(flex: 2),
                      ],
                    ),
                  ),

                  // Back button when on OTP step
                  if (_isOtpStep)
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
                          onPressed: () => setState(() => _isOtpStep = false),
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
      ),
    );
  }

  Widget _buildParticleOrbitLogo() {
    return SizedBox(
      width: 180,
      height: 180,
      child: Stack(
        alignment: Alignment.center,
        children: [
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
                      color: AppColors.primary.withValues(alpha: 0.15 * _glowAnimation.value),
                      blurRadius: 30 + 10 * _glowAnimation.value,
                      spreadRadius: 5 * _glowAnimation.value,
                    ),
                  ],
                ),
              );
            },
          ),
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

  Widget _buildHeadingText() {
    return Column(
      children: [
        Text(
          !_isOtpStep ? 'Welcome to OnWay' : 'Verify Your Number',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
            height: 28 / 20,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          !_isOtpStep ? 'Fresh groceries delivered fast.' : 'One last step to get started.',
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

  Widget _buildLoginCard(BuildContext context) {
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
            color: AppColors.primary.withValues(alpha: 0.05),
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

          // Phone Input
          _buildPhoneInput(context),

          const SizedBox(height: 12),

          // Send OTP Button
          _buildSendOtpButton(context),

          const SizedBox(height: 10),

          // Secure Login Badge
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
  }

  Widget _buildPhoneInput(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _phoneFocusNode.hasFocus
              ? AppColors.primary
              : AppColors.surfaceContainerHigh,
          width: _phoneFocusNode.hasFocus ? 2 : 1,
        ),
        boxShadow: _phoneFocusNode.hasFocus
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.2),
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
          Container(
            padding: const EdgeInsets.only(right: 10),
            decoration: const BoxDecoration(
              border: Border(
                right: BorderSide(
                  color: AppColors.surfaceContainerHigh,
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
                setState(() {});
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSendOtpButton(BuildContext context) {
    final isPhoneValid = _phoneController.text.trim().length == 10;

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        final pulseValue = _pulseAnimation.value;
        final pulseOpacity = (1.0 - pulseValue) * 0.4;
        final pulseRadius = pulseValue * 8;

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            boxShadow: isPhoneValid
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: pulseOpacity),
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
            gradient: const LinearGradient(
              colors: [
                AppColors.primary,
                Color(0xFF15803D),
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
              onTap: _isLoading ? null : _handleSendOtp,
              borderRadius: BorderRadius.circular(999),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    const SizedBox(width: 32),
                    Expanded(
                      child: Center(
                        child: _isLoading
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
                                  color: Colors.white,
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
      ),
    );
  }

  Widget _buildOtpCard(BuildContext context) {
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
            color: AppColors.primary.withValues(alpha: 0.05),
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
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Code sent to ',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: AppColors.outline,
                ),
              ),
              Text(
                '+91 ${_phoneController.text}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(width: 4),
              InkWell(
                onTap: () => setState(() => _isOtpStep = false),
                child: const Icon(
                  Icons.edit,
                  size: 14,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 6-Digit OTP Fields
          _buildOtpFields(),

          const SizedBox(height: 16),

          // Verify Button
          _buildVerifyButton(context),

          const SizedBox(height: 14),

          // Resend Timer Link
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Didn\'t receive the code? ',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: AppColors.outline,
                ),
              ),
              InkWell(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('OTP Resent to +91 ${_phoneController.text}', style: GoogleFonts.plusJakartaSans()),
                      backgroundColor: AppColors.primary,
                    ),
                  );
                },
                child: Text(
                  'Resend Now',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOtpFields() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(5, (index) {
        return SizedBox(
          width: 44,
          height: 48,
          child: TextField(
            controller: _otpControllers[index],
            focusNode: _otpFocusNodes[index],
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
              hintStyle: const TextStyle(
                color: AppColors.outline,
                fontSize: 14,
              ),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.5),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.surfaceContainerHigh),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.surfaceContainerHigh),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
            onChanged: (value) {
              if (value.isEmpty && index > 0) {
                _otpFocusNodes[index - 1].requestFocus();
              }
            },
          ),
        );
      }),
    );
  }

  Widget _buildVerifyButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 42,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              AppColors.primary,
              Color(0xFF15803D),
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
            onTap: _isLoading ? null : _handleVerifyOtp,
            borderRadius: BorderRadius.circular(999),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  const SizedBox(width: 32),
                  Expanded(
                    child: Center(
                      child: _isLoading
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
                                color: Colors.white,
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
      _RingDef(radius: 68, particles: 6, speed: 1.0, clockwise: true, color: const Color(0xFF22C55E), particleSize: 3.0, trailSweep: 0.4),
      _RingDef(radius: 78, particles: 4, speed: -0.7, clockwise: false, color: const Color(0xFF15803D), particleSize: 2.5, trailSweep: 0.5),
      _RingDef(radius: 88, particles: 8, speed: 0.5, clockwise: true, color: const Color(0xFF4ADE80), particleSize: 2.0, trailSweep: 0.3),
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
