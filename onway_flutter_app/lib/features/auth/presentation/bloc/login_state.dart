part of 'login_bloc.dart';

enum LoginStatus { initial, loading, success, failure }

class LoginState extends Equatable {
  final String phone;
  final LoginStatus status;
  final String? errorMessage;

  const LoginState({
    this.phone = '',
    this.status = LoginStatus.initial,
    this.errorMessage,
  });

  /// Whether the phone number is valid (10 digits for India)
  bool get isPhoneValid => phone.length == 10 && RegExp(r'^[6-9]\d{9}$').hasMatch(phone);

  LoginState copyWith({
    String? phone,
    LoginStatus? status,
    String? errorMessage,
  }) {
    return LoginState(
      phone: phone ?? this.phone,
      status: status ?? this.status,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [phone, status, errorMessage];
}
