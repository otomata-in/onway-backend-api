import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/network/api_service.dart';

part 'splash_event.dart';
part 'splash_state.dart';

class SplashBloc extends Bloc<SplashEvent, SplashState> {
  final _api = BuyerApiService();

  SplashBloc() : super(const SplashState()) {
    on<SplashStarted>(_onStarted);
    on<SplashAnimationCompleted>(_onAnimationCompleted);
  }

  Future<void> _onStarted(
    SplashStarted event,
    Emitter<SplashState> emit,
  ) async {
    emit(state.copyWith(status: SplashStatus.loading));

    // Initialize SharedPreferences and load stored auth token
    await _api.init();

    // Check for stored auth token / session
    if (_api.jwtToken != null && _api.jwtToken!.isNotEmpty) {
      try {
        final response = await _api.getSession();
        if (response['success'] == true) {
          emit(state.copyWith(status: SplashStatus.authenticated));
          return;
        }
      } catch (_) {
        // Token invalid or server unreachable
      }
    }

    // No valid session — show login after splash delay
    await Future.delayed(const Duration(milliseconds: 1500));
    emit(state.copyWith(status: SplashStatus.unauthenticated));
  }

  Future<void> _onAnimationCompleted(
    SplashAnimationCompleted event,
    Emitter<SplashState> emit,
  ) async {
    if (state.status == SplashStatus.initial) {
      emit(state.copyWith(status: SplashStatus.unauthenticated));
    }
  }
}
