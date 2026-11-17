import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/teritory_theme.dart';

/// Phone + OTP sign-in against `POST /auth/send-otp` and `/auth/verify-otp`.
/// The router sends authenticated users away from this route automatically.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _otpFocus = FocusNode();

  bool _otpSent = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _otpFocus.dispose();
    super.dispose();
  }

  /// Backend expects E.164-ish input; keep digits and a single leading `+`.
  String _normalisePhone(String raw) {
    final trimmed = raw.trim().replaceAll(RegExp(r'[\s\-()]'), '');
    if (trimmed.startsWith('+')) return '+${trimmed.substring(1).replaceAll(RegExp(r'\D'), '')}';
    final digits = trimmed.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 10) return '+91$digits';
    return '+$digits';
  }

  Future<void> _sendOtp() async {
    final phone = _normalisePhone(_phoneController.text);
    if (phone.length < 8) {
      setState(() => _error = 'Enter a valid phone number');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await ref.read(authStatusProvider.notifier).sendOtp(phone);
      if (!mounted) return;
      setState(() {
        _otpSent = true;
        _busy = false;
      });
      _otpFocus.requestFocus();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Could not reach the server. Check your connection and retry.';
      });
    }
  }

  Future<void> _verify() async {
    final phone = _normalisePhone(_phoneController.text);
    final otp = _otpController.text.trim();
    if (otp.isEmpty) {
      setState(() => _error = 'Enter the code you received');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await ref.read(authStatusProvider.notifier).signIn(phone: phone, otp: otp);
      // The router redirect takes over from here.
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Could not reach the server. Check your connection and retry.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TeritoryColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildBrand(),
                  const SizedBox(height: 32),
                  _buildFormCard(),
                  const SizedBox(height: 20),
                  Text(
                    'By continuing you agree to the Terms of Service and Privacy Policy.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      height: 1.5,
                      color: TeritoryColors.textMuted,
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

  Widget _buildBrand() {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: TeritoryColors.primaryLight,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(
            Icons.flag_rounded,
            size: 32,
            color: TeritoryColors.primary,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Teritory',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: TeritoryColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Your Map. Your Crew.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: TeritoryColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: TeritoryColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: TeritoryColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _otpSent ? 'Enter the code' : 'Sign in with your phone',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: TeritoryColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _otpSent
                ? 'We sent a 5-digit code to ${_normalisePhone(_phoneController.text)}.'
                : 'We will text you a one-time code.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              height: 1.4,
              color: TeritoryColors.textSecondary,
            ),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _phoneController,
            enabled: !_otpSent && !_busy,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            decoration: _decoration('Phone number', '+91 98765 43210'),
            onSubmitted: (_) => _sendOtp(),
          ),
          if (_otpSent) ...[
            const SizedBox(height: 14),
            TextField(
              controller: _otpController,
              focusNode: _otpFocus,
              enabled: !_busy,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              maxLength: 6,
              decoration: _decoration('One-time code', '12345').copyWith(
                counterText: '',
              ),
              onSubmitted: (_) => _verify(),
            ),
            if (kDebugMode) ...[
              const SizedBox(height: 8),
              Text(
                'Dev build: the backend accepts OTP 12345.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: TeritoryColors.textMuted,
                ),
              ),
            ],
          ],
          if (_error != null) ...[
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 16,
                  color: TeritoryColors.expiredRed,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _error!,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      height: 1.4,
                      color: TeritoryColors.expiredRed,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: _busy ? null : (_otpSent ? _verify : _sendOtp),
            style: ElevatedButton.styleFrom(
              backgroundColor: TeritoryColors.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: TeritoryColors.primary.withValues(alpha: 0.4),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    _otpSent ? 'Verify & Continue' : 'Send Code',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
          ),
          if (_otpSent)
            TextButton(
              onPressed: _busy
                  ? null
                  : () {
                      setState(() {
                        _otpSent = false;
                        _otpController.clear();
                        _error = null;
                      });
                    },
              child: Text(
                'Use a different number',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: TeritoryColors.textSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  InputDecoration _decoration(String label, String hint) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: TeritoryColors.surfaceContainer,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: TeritoryColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: TeritoryColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: TeritoryColors.primary, width: 1.6),
      ),
    );
  }
}
