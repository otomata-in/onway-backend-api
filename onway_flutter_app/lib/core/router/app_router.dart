import 'package:go_router/go_router.dart';

import '../../features/splash/presentation/pages/splash_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/otp_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/home/presentation/bloc/home_state.dart';
import '../../features/vendor_details/presentation/pages/live_tracking_page.dart';
import '../../features/vendor_details/presentation/pages/retail_vendor_page.dart';

class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/otp',
        name: 'otp',
        builder: (context, state) {
          final phone = state.extra as String? ?? '';
          return OtpPage(phone: phone);
        },
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: '/live-tracking',
        name: 'live-tracking',
        builder: (context, state) {
          final orderInfo = state.extra as ActiveOrderInfo;
          return LiveTrackingPage(orderInfo: orderInfo);
        },
      ),
      GoRoute(
        path: '/retail-vendor',
        name: 'retail-vendor',
        builder: (context, state) {
          final vendorInfo = state.extra as VendorInfo;
          return RetailVendorPage(vendorInfo: vendorInfo);
        },
      ),
    ],
  );
}
