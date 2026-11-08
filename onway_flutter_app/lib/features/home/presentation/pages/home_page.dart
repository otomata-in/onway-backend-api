import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../bloc/home_bloc.dart';
import '../bloc/home_event.dart';
import '../bloc/home_state.dart';
import '../widgets/bottom_nav_bar.dart';
import 'simple_home_page.dart';
import 'advanced_map_page.dart';
import 'profile_page.dart';
import 'saved_vendors_page.dart';
import '../../../orders/presentation/pages/bookings_page.dart';
import '../../../vendor_details/presentation/pages/scan_vendor_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _HomeView();
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: const Color(0xFFF8FAF8),
          body: state.status == HomeStatus.loading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : Stack(
                  children: [
                    IndexedStack(
                      index: state.navIndex,
                      children: [
                        // Tab 0: New Simple, Non-Tech Friendly Home Page
                        SimpleHomePage(state: state),

                        // Tab 1: Advanced Live Map Page (Exact Previous Home Page with OSM Map)
                        AdvancedMapPage(state: state),

                        // Tab 2: Saved / Favorite Vendors
                        SavedVendorsPage(savedVendors: state.vendors.where((v) => v.isFavorite).toList()),

                        // Tab 3: Scan QR Code
                        const ScanVendorPage(),

                        // Tab 4: Orders & Bookings
                        const BookingsPage(),

                        // Tab 5: User Profile & Settings
                        const ProfilePage(),
                      ],
                    ),

                    // Floating 6-Item Bottom Navigation Bar
                    Positioned(
                      bottom: 24,
                      left: 0,
                      right: 0,
                      child: BottomNavBar(
                        currentIndex: state.navIndex,
                        onTap: (i) => context.read<HomeBloc>().add(HomeNavIndexChanged(i)),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}
