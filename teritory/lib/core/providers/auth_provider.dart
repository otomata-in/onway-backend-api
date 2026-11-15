import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_models.dart';
import '../services/teritory_repository.dart';
import '../services/api_service.dart';
import '../services/mock_data_service.dart';
import '../services/socket_service.dart';

class CurrentUserNotifier extends Notifier<User> {
  @override
  User build() {
    _initializeUser();
    return MockDataService.instance.currentUser;
  }

  Future<void> _initializeUser() async {
    // If not authenticated yet, auto-login with test credentials & bypass OTP 12345
    if (!TeritoryApiService.instance.isAuthenticated) {
      await TeritoryRepository.instance.loginWithOtp('+919876543210', '12345');
    }
    final user = await TeritoryRepository.instance.fetchMyProfile();
    state = user;
    SocketService.instance.connect();
  }

  void updateUser(User user) {
    state = user;
  }

  Future<bool> login(String phone, String otp) async {
    final user = await TeritoryRepository.instance.loginWithOtp(phone, otp);
    if (user != null) {
      state = user;
      SocketService.instance.connect();
      return true;
    }
    return false;
  }

  Future<void> logout() async {
    SocketService.instance.disconnect();
    await TeritoryApiService.instance.clearToken();
    state = MockDataService.instance.currentUser;
  }
}

final currentUserNotifierProvider =
    NotifierProvider<CurrentUserNotifier, User>(CurrentUserNotifier.new);

final currentUserProvider = Provider<User>((ref) {
  return ref.watch(currentUserNotifierProvider);
});

final isLoggedInProvider = Provider<bool>((ref) {
  return TeritoryApiService.instance.isAuthenticated;
});
