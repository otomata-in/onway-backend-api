import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/network/api_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../orders/presentation/pages/active_deliveries_page.dart';
import '../../../vendor_details/presentation/pages/live_tracking_page.dart';
import '../bloc/home_bloc.dart';
import '../bloc/home_event.dart';
import '../bloc/home_state.dart';
import '../pages/location_selection_page.dart';
import '../pages/notifications_page.dart';
import '../pages/settings_page.dart';

class HomeAppBar extends StatefulWidget {
  final bool showBackButton;

  const HomeAppBar({super.key, this.showBackButton = false});

  @override
  State<HomeAppBar> createState() => _HomeAppBarState();
}

class _HomeAppBarState extends State<HomeAppBar> {
  final _api = BuyerApiService();

  @override
  void initState() {
    super.initState();
  }

  Future<void> _openLocationSelection(BuildContext context) async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => const LocationSelectionPage()),
    );

    if (result != null && mounted) {
      final title = result['title'] ?? 'Selected Address';
      final subtitle = result['subtitle'] ?? result['addressLine'] ?? '';
      final lat = (result['lat'] as num?)?.toDouble() ?? 9.9790;
      final lng = (result['lng'] as num?)?.toDouble() ?? 76.2760;

      context.read<HomeBloc>().add(HomeLocationSelected(
        latitude: lat,
        longitude: lng,
        title: title,
        addressLine: subtitle,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        final addressTitle = state.isLocationSelected ? state.selectedAddressTitle : 'Select Location';
        final addressLine = state.isLocationSelected ? state.selectedAddressLine : 'Tap to choose delivery address';

        return SliverAppBar(
          floating: true,
          snap: true,
          pinned: true,
          backgroundColor: Colors.white.withValues(alpha: 0.95),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          toolbarHeight: 64,
          automaticallyImplyLeading: false,
          titleSpacing: widget.showBackButton ? 0 : NavigationToolbar.kMiddleSpacing,
          title: Row(
            children: [
              // ─── Left Side: App Brand / Logo or Back Button ───
              if (widget.showBackButton)
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
                  onPressed: () => Navigator.of(context).maybePop(),
                )
              else
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.shopping_bag, size: 18, color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'OnWay',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.onSurface,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),

              const Spacer(),

              // ─── Right Side: Selected Delivery Address Pill ───
              GestureDetector(
                onTap: () => _openLocationSelection(context),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 155),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: state.isLocationSelected
                        ? AppColors.primary.withValues(alpha: 0.1)
                        : Colors.amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: state.isLocationSelected
                          ? AppColors.primary.withValues(alpha: 0.3)
                          : Colors.amber.shade700,
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: state.isLocationSelected ? AppColors.primary : Colors.amber.shade800,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              addressTitle,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: state.isLocationSelected ? AppColors.primary : Colors.amber.shade900,
                                height: 1.1,
                              ),
                            ),
                            Text(
                              addressLine,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.onSurfaceVariant,
                                height: 1.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.keyboard_arrow_down,
                        size: 14,
                        color: state.isLocationSelected ? AppColors.primary : Colors.amber.shade800,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),

              // ─── Action Icon: Vehicle / Active Deliveries ───
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ActiveDeliveriesPage(),
                    ),
                  );
                },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.local_shipping_outlined, color: AppColors.primary, size: 20),
                ),
              ),
              const SizedBox(width: 6),

              // ─── Action Icon: Notifications Bell ───
              GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsPage()));
                },
                child: Stack(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow.withValues(alpha: 0.8),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.notifications_outlined, color: AppColors.onSurfaceVariant, size: 20),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),

              // ─── Action Icon: Settings ───
              GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage()));
                },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow.withValues(alpha: 0.8),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.settings_outlined, color: AppColors.onSurfaceVariant, size: 20),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
