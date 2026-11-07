import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/network/api_service.dart';

part 'login_event.dart';
part 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final _api = BuyerApiService();

  LoginBloc() : super(const LoginState()) {
    on<LoginPhoneChanged>(_onPhoneChanged);
    on<LoginSendOtpPressed>(_onSendOtp);
  }

  void _onPhoneChanged(
    LoginPhoneChanged event,
    Emitter<LoginState> emit,
  ) {
    emit(state.copyWith(
      phone: event.phone,
      status: LoginStatus.initial,
      errorMessage: null,
    ));
  }

  Future<void> _onSendOtp(
    LoginSendOtpPressed event,
    Emitter<LoginState> emit,
  ) async {
    emit(state.copyWith(status: LoginStatus.loading));

    try {
      final response = await _api.sendOtp(state.phone);

      if (response['success'] == true) {
        emit(state.copyWith(status: LoginStatus.success));
      } else {
        emit(state.copyWith(
          status: LoginStatus.failure,
          errorMessage: response['message'] ?? 'Failed to send OTP',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: LoginStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }
}
