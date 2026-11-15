import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_models.dart';
import '../services/mock_data_service.dart';

final currentUserProvider = Provider<User>((ref) {
  return MockDataService.instance.currentUser;
});

final isLoggedInProvider = Provider<bool>((ref) {
  return true;
});
