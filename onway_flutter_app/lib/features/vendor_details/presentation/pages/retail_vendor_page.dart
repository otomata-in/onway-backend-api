import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/network/api_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../home/presentation/bloc/home_state.dart';
import '../bloc/vendor_details_bloc.dart';
import '../bloc/vendor_details_event.dart';
import '../bloc/vendor_details_state.dart';
import '../../../../core/widgets/standard_top_bar.dart';
import 'live_tracking_page.dart';
import '../../../orders/presentation/pages/active_deliveries_page.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'booking_page.dart';
import '../../../home/presentation/bloc/home_bloc.dart';
import '../../../home/presentation/bloc/home_event.dart';

class RetailVendorPage extends StatelessWidget {
  final VendorInfo vendorInfo;

  const RetailVendorPage({super.key, required this.vendorInfo});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => VendorDetailsBloc()..add(VendorDetailsLoadRequested(vendorId: vendorInfo.id)),
      child: _RetailVendorView(vendorInfo: vendorInfo),
    );
  }
}

class _RetailVendorView extends StatelessWidget {
  final VendorInfo vendorInfo;

  const _RetailVendorView({required this.vendorInfo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8),
      body: BlocBuilder<VendorDetailsBloc, VendorDetailsState>(
        builder: (context, state) {
          if (state.status == VendorDetailsStatus.loading) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          return Stack(
            children: [
              CustomScrollView(
                slivers: [
                  StandardTopBar(
                    title: 'Seller Details',
                    subtitle: 'Vendor information & available items',
                    icon: Icons.local_shipping,
                    onIconTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ActiveDeliveriesPage())),
                    showBackButton: true,
                  ),
                  _buildVendorDetailsCard(),
                  _buildInventoryList(context, state),
                  const SliverToBoxAdapter(child: SizedBox(height: 100)), // Bottom padding
                ],
              ),
              _buildBottomActionBar(context, state),
            ],
          );
        },
      ),
    );
  }

  Widget _buildVendorDetailsCard() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.surfaceContainerLow),
          boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Small vendor image
                Container(
                  width: 60, height: 60,
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.surfaceContainer),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: Image.asset(
                      vendorInfo.imagePath,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: AppColors.primaryContainer,
                        child: const Icon(Icons.store, color: AppColors.primary, size: 28),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              vendorInfo.name,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.onSurface,
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              _SaveSellerButton(vendorInfo: vendorInfo),
                              if (vendorInfo.isLive) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.error.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text('LIVE', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.error)),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(vendorInfo.subtitle, style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AppColors.outline)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatItem(Icons.star, Colors.orange, '${vendorInfo.rating}'),
                _buildStatItem(Icons.schedule, AppColors.primary, vendorInfo.eta),
                _buildStatItem(Icons.location_on, AppColors.onSurfaceVariant, vendorInfo.distance),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: AppColors.surfaceContainerHigh, height: 1),
            const SizedBox(height: 16),
            _buildProgressBar(),
            const SizedBox(height: 16),
            _VendorToggleGrid(vendorInfo: vendorInfo),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, Color color, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(text, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.onSurfaceVariant)),
      ],
    );
  }

  Widget _buildProgressBar() {
    const double progress = 0.75;
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 32,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                return Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.centerLeft,
                  children: [
                    Container(
                      height: 6,
                      width: width,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E3DD),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    Container(
                      height: 6,
                      width: width * progress,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      child: Container(
                        width: 10, height: 10,
                        decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                      ),
                    ),
                    Positioned(
                      left: (width * progress) - 16,
                      child: Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.primary, width: 2),
                        ),
                        child: const Icon(Icons.local_shipping, size: 16, color: AppColors.primary),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        const SizedBox(width: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F8EE),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            children: [
              const Icon(Icons.schedule, size: 14, color: Color(0xFF1EB956)),
              const SizedBox(width: 4),
              Text(
                vendorInfo.eta,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1EB956),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }



  Widget _buildInventoryList(BuildContext context, VendorDetailsState state) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text('Available Items', style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
              );
            }
            final product = state.products[index - 1];
            final qty = state.cartQuantity[product.id] ?? 0;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.surfaceContainerLow),
              ),
              child: Row(
                children: [
                  Container(
                    width: 60, height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: AppColors.surfaceContainerHigh,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(product.imagePath, fit: BoxFit.cover, errorBuilder: (c,e,s) => const Icon(Icons.image, color: AppColors.outline)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(product.name, style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.onSurface)),
                        Text(
                          product.description.isNotEmpty
                              ? '${product.description} • ${product.unit}'
                              : product.unit,
                          style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.outline),
                        ),
                      ],
                    ),
                  ),
                  qty > 0
                      ? Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline, color: AppColors.primary),
                              onPressed: () => context.read<VendorDetailsBloc>().add(RemoveFromCartRequested(product)),
                            ),
                            Text('$qty', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: const Icon(Icons.add_circle, color: AppColors.primary),
                              onPressed: () => context.read<VendorDetailsBloc>().add(AddToCartRequested(product)),
                            ),
                          ],
                        )
                      : IconButton(
                          icon: const Icon(Icons.add_circle, color: AppColors.primary, size: 28),
                          onPressed: () => context.read<VendorDetailsBloc>().add(AddToCartRequested(product)),
                        ),
                ],
              ),
            );
          },
          childCount: state.products.length + 1,
        ),
      ),
    );
  }

  Widget _buildBottomActionBar(BuildContext context, VendorDetailsState state) {
    return Positioned(
      bottom: 0, left: 0, right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [BoxShadow(color: AppColors.onSurface.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, -4))],
        ),
        child: ElevatedButton(
          onPressed: () {
            final addedProducts = state.products
                .where((p) => (state.cartQuantity[p.id] ?? 0) > 0)
                .toList();

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BookingPage(
                  vendorInfo: vendorInfo,
                  bookedProducts: addedProducts,
                  cartQuantity: state.cartQuantity,
                ),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 0,
          ),
          child: Text('Book Now', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}

class _VendorToggleGrid extends StatefulWidget {
  final VendorInfo vendorInfo;

  const _VendorToggleGrid({required this.vendorInfo});

  @override
  State<_VendorToggleGrid> createState() => _VendorToggleGridState();
}

class _VendorToggleGridState extends State<_VendorToggleGrid> {
  final _api = BuyerApiService();
  bool notifyOnReach = true;
  bool dailyTracking = false;
  bool ringOnReach = true;
  bool showMap = false;

  Future<void> _toggleDailyTracking() async {
    final nextState = !dailyTracking;
    setState(() => dailyTracking = nextState);

    final vendorId = widget.vendorInfo.id.isNotEmpty
        ? widget.vendorInfo.id
        : widget.vendorInfo.name;

    if (nextState) {
      await _api.updateTrackingPreferences(
        vendorId,
        dailyTracking: true,
        notifyOnReach: notifyOnReach,
        ringOnReach: ringOnReach,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Added ${widget.vendorInfo.name} to Daily Trackings!',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } else {
      await _api.removeTracking(vendorId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Removed ${widget.vendorInfo.name} from Daily Trackings',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: AppColors.outline,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  Future<void> _toggleNotifyOnReach() async {
    final nextState = !notifyOnReach;
    setState(() => notifyOnReach = nextState);
    final vendorId = widget.vendorInfo.id.isNotEmpty ? widget.vendorInfo.id : widget.vendorInfo.name;
    await _api.updateTrackingPreferences(vendorId, notifyOnReach: nextState);
  }

  Future<void> _toggleRingOnReach() async {
    final nextState = !ringOnReach;
    setState(() => ringOnReach = nextState);
    final vendorId = widget.vendorInfo.id.isNotEmpty ? widget.vendorInfo.id : widget.vendorInfo.name;
    await _api.updateTrackingPreferences(vendorId, ringOnReach: nextState);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildToggleButton(
                icon: Icons.notifications_none,
                label: 'Notify on reach',
                isActive: notifyOnReach,
                onTap: _toggleNotifyOnReach,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildToggleButton(
                icon: Icons.calendar_today_outlined,
                label: 'Daily Tracking',
                isActive: dailyTracking,
                onTap: _toggleDailyTracking,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildToggleButton(
                icon: Icons.notifications_active,
                label: 'Ring on Reach',
                isActive: ringOnReach,
                onTap: _toggleRingOnReach,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildToggleButton(
                icon: showMap ? Icons.map : Icons.map_outlined,
                label: showMap ? 'Hide Map' : 'View Map',
                isActive: showMap,
                isAction: true,
                onTap: () => setState(() => showMap = !showMap),
              ),
            ),
          ],
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 400),
          curve: Curves.fastOutSlowIn,
          child: showMap
              ? BlocBuilder<VendorDetailsBloc, VendorDetailsState>(
                  builder: (context, state) => Column(
                    children: [
                      const SizedBox(height: 16),
                      _buildInlineLiveVendorRoute(state),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  List<LatLng> _generateRoadwayPolyline(List<LatLng> waypoints) {
    if (waypoints.isEmpty) return [];
    if (waypoints.length == 1) return waypoints;

    final List<LatLng> result = [];
    for (int i = 0; i < waypoints.length - 1; i++) {
      final start = waypoints[i];
      final end = waypoints[i + 1];
      result.add(start);

      final midLat = (start.latitude + end.latitude) / 2;
      final midLng = (start.longitude + end.longitude) / 2;
      final latOffset = (end.longitude - start.longitude) * 0.15;
      final lngOffset = (start.latitude - end.latitude) * 0.15;

      result.add(LatLng(
        start.latitude * 0.7 + end.latitude * 0.3 + latOffset * 0.5,
        start.longitude * 0.7 + end.longitude * 0.3 + lngOffset * 0.5,
      ));
      result.add(LatLng(midLat + latOffset, midLng + lngOffset));
      result.add(LatLng(
        start.latitude * 0.3 + end.latitude * 0.7 + latOffset * 0.5,
        start.longitude * 0.3 + end.longitude * 0.7 + lngOffset * 0.5,
      ));
    }
    result.add(waypoints.last);
    return result;
  }

  Widget _buildInlineLiveVendorRoute(VendorDetailsState state) {
    final routePoints = _generateRoadwayPolyline(state.routePoints);
    final vendorPos = LatLng(state.vendorLat, state.vendorLng);
    const buyerPos = LatLng(9.9790, 76.2760);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LiveTrackingPage(
              orderInfo: ActiveOrderInfo(
                vendorName: widget.vendorInfo.name,
                eta: widget.vendorInfo.eta,
                distance: widget.vendorInfo.distance,
                progress: 0.75,
              ),
              vendorId: widget.vendorInfo.id,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAF8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.surfaceContainerHigh),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Live Vendor Route',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.onSurface,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'LIVE TRACKING',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFdae2fd),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFbccbb9)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: vendorPos,
                    initialZoom: 15.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.onway_market',
                    ),
                    if (routePoints.isNotEmpty)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: routePoints,
                            color: AppColors.primary,
                            strokeWidth: 4.0,
                          ),
                        ],
                      ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: buyerPos,
                          width: 40,
                          height: 40,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                                ),
                              ),
                              const SizedBox(height: 2),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'YOU',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                    height: 1,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Marker(
                          point: vendorPos,
                          width: 36,
                          height: 36,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8)],
                            ),
                            child: const Icon(Icons.local_shipping, color: Colors.white, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(color: AppColors.outline, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        widget.vendorInfo.name,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Arriving Soon (${widget.vendorInfo.eta})',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

  Widget _buildToggleButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    bool isAction = false,
  }) {
    if (isAction) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1EB956),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1EB956).withValues(alpha: 0.25),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: Colors.white),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
    }
    final primaryColor = AppColors.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isActive
              ? primaryColor.withValues(alpha: 0.08)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive
                ? primaryColor
                : const Color(0xFFE2E3DD),
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isActive ? primaryColor : AppColors.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive ? primaryColor : AppColors.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive ? primaryColor : Colors.transparent,
                border: Border.all(
                  color: isActive ? primaryColor : AppColors.outline,
                  width: 1.5,
                ),
              ),
              child: isActive
                  ? const Icon(Icons.check, size: 10, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _SaveSellerButton extends StatelessWidget {
  final VendorInfo vendorInfo;
  const _SaveSellerButton({required this.vendorInfo});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        final currentVendor = state.vendors.firstWhere(
          (v) => v.name == vendorInfo.name,
          orElse: () => vendorInfo,
        );
        final isFavorite = currentVendor.isFavorite;

        return GestureDetector(
          onTap: () {
            final newStatus = !isFavorite;
            context.read<HomeBloc>().add(
                  HomeVendorToggleFavorite(
                    currentVendor.copyWith(isFavorite: newStatus),
                  ),
                );
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  newStatus ? 'Saved to Favorite Sellers!' : 'Removed from Saved Sellers',
                  style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                backgroundColor: AppColors.primary,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            );
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: isFavorite ? AppColors.primary.withValues(alpha: 0.1) : AppColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: isFavorite ? AppColors.primary.withValues(alpha: 0.3) : AppColors.outlineVariant,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isFavorite ? 'Saved' : 'Save',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isFavorite ? AppColors.primary : AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  isFavorite ? Icons.bookmark : Icons.bookmark_border,
                  color: isFavorite ? AppColors.primary : AppColors.onSurfaceVariant,
                  size: 14,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
