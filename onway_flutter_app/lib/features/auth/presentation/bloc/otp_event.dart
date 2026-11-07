import 'package:equatable/equatable.dart';

abstract class OtpEvent extends Equatable {
  const OtpEvent();

  @override
  List<Object?> get props => [];
}

class OtpCodeChanged extends OtpEvent {
  final String code;
  const OtpCodeChanged(this.code);

  @override
  List<Object?> get props => [code];
}

class OtpVerifyPressed extends OtpEvent {
  const OtpVerifyPressed();
}

class OtpResendPressed extends OtpEvent {
  const OtpResendPressed();
}

class OtpTimerTicked extends OtpEvent {
  final int duration;
  const OtpTimerTicked(this.duration);

  @override
  List<Object?> get props => [duration];
}
