part of 'login_bloc.dart';

abstract class LoginEvent extends Equatable {
  const LoginEvent();

  @override
  List<Object?> get props => [];
}

/// Phone number text changed
class LoginPhoneChanged extends LoginEvent {
  final String phone;
  const LoginPhoneChanged(this.phone);

  @override
  List<Object?> get props => [phone];
}

/// Send OTP button tapped
class LoginSendOtpPressed extends LoginEvent {
  const LoginSendOtpPressed();
}
