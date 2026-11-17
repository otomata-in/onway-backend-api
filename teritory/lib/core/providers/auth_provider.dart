import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_models.dart';
import '../services/api_service.dart';
import '../services/mock_data_service.dart';
import '../services/socket_service.dart';
import '../services/teritory_repository.dart';

/// Session state that the router uses as its gate.
enum AuthStatus { restoring, signedOut, signedIn }

final authStatusProvider =
    NotifierProvider<AuthNotifier, AuthStatus>(AuthNotifier.new);

class AuthNotifier extends Notifier<AuthStatus> {
  @override
  AuthStatus build() {
    // Restore the stored token pair without blocking the first frame; the
    // router shows the splash route until this settles.
    Future.microtask(_restoreSession);
    return AuthStatus.restoring;
  }

  Future<void> _restoreSession() async {
    final api = TeritoryApiService.instance;
    if (!api.isAuthenticated) {
      state = AuthStatus.signedOut;
      return;
    }

    try {
      final user = await TeritoryRepository.instance.fetchMyProfileOrThrow();
      ref.read(currentUserNotifierProvider.notifier).updateUser(user);
      SocketService.instance.connect();
      state = AuthStatus.signedIn;
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        // Access and refresh tokens are both dead: start over at login.
        await api.clearTokens();
        state = AuthStatus.signedOut;
        return;
      }
      // Session is intact, the server just could not serve the profile.
      state = AuthStatus.signedIn;
    } catch (_) {
      // Offline cold start: keep the stored session, screens show retry.
      state = AuthStatus.signedIn;
    }
  }

  Future<void> sendOtp(String phone) {
    return TeritoryRepository.instance.sendOtp(phone);
  }

  Future<void> signIn({required String phone, required String otp}) async {
    final user = await TeritoryRepository.instance.loginWithOtp(phone, otp);
    ref.read(currentUserNotifierProvider.notifier).updateUser(user);
    SocketService.instance.connect();
    state = AuthStatus.signedIn;
  }

  Future<void> signOut() async {
    await TeritoryRepository.instance.logout();
    SocketService.instance.disconnect();
    state = AuthStatus.signedOut;
  }
}

class CurrentUserNotifier extends Notifier<User> {
  @override
  User build() {
    // Placeholder until the session gate resolves; signed-out traffic never
    // reaches a screen that reads this.
    return MockDataService.instance.currentUser;
  }

  void updateUser(User user) {
    state = user;
  }

  Future<void> refreshFromServer() async {
    state = await TeritoryRepository.instance.fetchMyProfileOrThrow();
  }
}

final currentUserNotifierProvider =
    NotifierProvider<CurrentUserNotifier, User>(CurrentUserNotifier.new);

final currentUserProvider = Provider<User>((ref) {
  return ref.watch(currentUserNotifierProvider);
});

final isLoggedInProvider = Provider<bool>((ref) {
  return ref.watch(authStatusProvider) == AuthStatus.signedIn;
});
