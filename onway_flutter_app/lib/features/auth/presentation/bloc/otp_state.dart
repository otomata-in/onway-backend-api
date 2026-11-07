import 'package:equatable/equatable.dart';

enum OtpStatus { initial, loading, success, failure }

class OtpState extends Equatable {
  final String code;
  final OtpStatus status;
  final String? errorMessage;
  final int timerDuration;
  final bool canResend;

  const OtpState({
    this.code = '',
    this.status = OtpStatus.initial,
    this.errorMessage,
    this.timerDuration = 45,
    this.canResend = false,
  });

  bool get isCodeValid => code.length == 5;

  OtpState copyWith({
    String? code,
    OtpStatus? status,
    String? errorMessage,
    int? timerDuration,
    bool? canResend,
  }) {
    return OtpState(
      code: code ?? this.code,
      status: status ?? this.status,
      errorMessage: errorMessage,
      timerDuration: timerDuration ?? this.timerDuration,
      canResend: canResend ?? this.canResend,
    );
  }

  @override
  List<Object?> get props => [code, status, errorMessage, timerDuration, canResend];
}
