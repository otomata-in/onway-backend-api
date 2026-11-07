import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/network/api_service.dart';
import 'core/theme/app_colors.dart';
import 'core/widgets/vendor_bottom_nav_bar.dart';
import 'core/widgets/vendor_top_bar.dart';
import 'features/auth/presentation/pages/vendor_login_page.dart';
import 'features/splash/presentation/pages/vendor_splash_page.dart';
import 'features/home/presentation/bloc/vendor_home_bloc.dart';
import 'features/home/presentation/bloc/vendor_home_event.dart';
import 'features/home/presentation/bloc/vendor_home_state.dart';
import 'features/home/presentation/pages/vendor_home_page.dart';
import 'features/inventory/presentation/pages/vendor_inventory_page.dart';
import 'features/orders/presentation/pages/vendor_orders_page.dart';
import 'features/profile/presentation/pages/vendor_profile_page.dart';
import 'features/qr/presentation/pages/vehicle_qr_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await VendorApiService().init();
  runApp(const OnWayVendorApp());
}

class OnWayVendorApp extends StatelessWidget {
  const OnWayVendorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => VendorHomeBloc(),
      child: MaterialApp(
        title: 'OnWay Partner - Vendor App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primary,
            primary: AppColors.primary,
            surface: AppColors.surface,
          ),
          scaffoldBackgroundColor: AppColors.surface,
        ),
        home: const VendorAppMainScreen(),
      ),
    );
  }
}

class VendorAppMainScreen extends StatefulWidget {
  const VendorAppMainScreen({super.key});

  @override
  State<VendorAppMainScreen> createState() => _VendorAppMainScreenState();
}

class _VendorAppMainScreenState extends State<VendorAppMainScreen> {
  bool _showSplash = true;
  late bool _isLoggedIn;

  @override
  void initState() {
    super.initState();
    _isLoggedIn = VendorApiService().jwtToken != null;
  }

  static const _tabTitles = [
    'Vendor Dashboard',
    'Product Inventory',
    'Vehicle QR Code',
    'Buyer Pre-Bookings',
    'Vendor Profile',
  ];

  static const _tabSubtitles = [
    'Live route status & daily business overview',
    'Manage product stock & item pricing',
    'Display or print your vehicle QR code',
    'Manage incoming buyer reservations',
    'Store details & vehicle configuration',
  ];

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return VendorSplashPage(
        onSplashComplete: () {
          setState(() {
            _showSplash = false;
          });
        },
      );
    }

    if (!_isLoggedIn) {
      return VendorLoginPage(
        onLoginSuccess: () {
          setState(() => _isLoggedIn = true);
          context.read<VendorHomeBloc>().add(const VendorLoadRequested());
        },
      );
    }

    return BlocBuilder<VendorHomeBloc, VendorHomeState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.surface,
          body: Stack(
            children: [
              CustomScrollView(
                slivers: [
                  VendorTopBar(
                    title: _tabTitles[state.navIndex],
                    subtitle: _tabSubtitles[state.navIndex],
                    icon: state.navIndex == 4 ? Icons.logout : null,
                    onIconTap: state.navIndex == 4
                        ? () async {
                            await VendorApiService().clearAuthToken();
                            if (mounted) setState(() => _isLoggedIn = false);
                          }
                        : null,
                  ),
                  SliverFillRemaining(
                    child: IndexedStack(
                      index: state.navIndex,
                      children: [
                        VendorHomePage(state: state),
                        VendorInventoryPage(state: state),
                        VehicleQrPage(state: state),
                        VendorOrdersPage(state: state),
                        VendorProfilePage(
                          state: state,
                          onLogout: () async {
                            await VendorApiService().clearAuthToken();
                            if (mounted) setState(() => _isLoggedIn = false);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Floating Bottom Navigation Bar
              Positioned(
                bottom: 24,
                left: 0,
                right: 0,
                child: VendorBottomNavBar(
                  selectedIndex: state.navIndex,
                  onItemTapped: (index) {
                    context.read<VendorHomeBloc>().add(VendorNavIndexChanged(index));
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
