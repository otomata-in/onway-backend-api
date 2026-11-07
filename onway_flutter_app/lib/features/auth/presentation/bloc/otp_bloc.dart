import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/api_service.dart';
import 'otp_event.dart';
import 'otp_state.dart';

class OtpBloc extends Bloc<OtpEvent, OtpState> {
  final String phone;
  final _api = BuyerApiService();
  StreamSubscription<int>? _timerSubscription;

  OtpBloc({required this.phone}) : super(const OtpState()) {
    on<OtpCodeChanged>(_onCodeChanged);
    on<OtpVerifyPressed>(_onVerifyPressed);
    on<OtpResendPressed>(_onResendPressed);
    on<OtpTimerTicked>(_onTimerTicked);

    _startTimer();
  }

  void _onCodeChanged(OtpCodeChanged event, Emitter<OtpState> emit) {
    emit(state.copyWith(
      code: event.code,
      status: OtpStatus.initial,
      errorMessage: null,
    ));
  }

  Future<void> _onVerifyPressed(OtpVerifyPressed event, Emitter<OtpState> emit) async {
    emit(state.copyWith(status: OtpStatus.loading));

    try {
      final response = await _api.verifyOtp(
        phone: phone,
        otpCode: state.code,
      );

      if (response['success'] == true && response['token'] != null) {
        await _api.setAuthToken(response['token']);
        emit(state.copyWith(status: OtpStatus.success));
      } else {
        emit(state.copyWith(
          status: OtpStatus.failure,
          errorMessage: response['error'] ?? response['message'] ?? 'Invalid OTP code',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: OtpStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onResendPressed(OtpResendPressed event, Emitter<OtpState> emit) async {
    if (!state.canResend) return;
    
    // Fire and forget - send OTP again
    _api.sendOtp(phone);
    
    emit(state.copyWith(
      canResend: false,
      timerDuration: 45,
      status: OtpStatus.initial,
      errorMessage: null,
    ));
    _startTimer();
  }

  void _onTimerTicked(OtpTimerTicked event, Emitter<OtpState> emit) {
    if (event.duration > 0) {
      emit(state.copyWith(timerDuration: event.duration));
    } else {
      emit(state.copyWith(timerDuration: 0, canResend: true));
    }
  }

  void _startTimer() {
    _timerSubscription?.cancel();
    _timerSubscription = Stream.periodic(const Duration(seconds: 1), (x) => 45 - x - 1)
        .take(45)
        .listen((duration) => add(OtpTimerTicked(duration)));
  }

  @override
  Future<void> close() {
    _timerSubscription?.cancel();
    return super.close();
  }
}
