import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../routes/presentation/widgets/route_manager_modal.dart';
import '../bloc/vendor_home_bloc.dart';
import '../bloc/vendor_home_event.dart';
import '../bloc/vendor_home_state.dart';

class VendorHomePage extends StatefulWidget {
  final VendorHomeState state;
  const VendorHomePage({super.key, required this.state});

  @override
  State<VendorHomePage> createState() => _VendorHomePageState();
}

class _VendorHomePageState extends State<VendorHomePage> {
  final MapController _mapController = MapController();

  @override
  void didUpdateWidget(covariant VendorHomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.activeRoute.id != widget.state.activeRoute.id ||
        oldWidget.state.activeRoute.waypoints != widget.state.activeRoute.waypoints) {
      _centerMapOnActiveRoute();
    }
  }

  bool _isOrderPassedAndCovered(LatLng vehicleLoc, LatLng orderLoc, List<RouteWaypoint> waypoints) {
    const distanceCalc = Distance();
    final directDistance = distanceCalc.as(LengthUnit.Meter, vehicleLoc, orderLoc);

    // If order is within 500 meters of the vehicle, it's near/active, so NOT passed
    if (directDistance <= 500) {
      return false;
    }

    // Check projection along the route vector if distance > 500m
    if (waypoints.length >= 2) {
      final startPt = waypoints.first.point;
      final endPt = waypoints.last.point;

      final routeLatVector = endPt.latitude - startPt.latitude;
      final routeLngVector = endPt.longitude - startPt.longitude;

      final vehLatOffset = vehicleLoc.latitude - startPt.latitude;
      final vehLngOffset = vehicleLoc.longitude - startPt.longitude;

      final ordLatOffset = orderLoc.latitude - startPt.latitude;
      final ordLngOffset = orderLoc.longitude - startPt.longitude;

      final vehicleProgress = (vehLatOffset * routeLatVector) + (vehLngOffset * routeLngVector);
      final orderProgress = (ordLatOffset * routeLatVector) + (ordLngOffset * routeLngVector);

      // If order is behind the vehicle trajectory AND direct distance > 500m, it's covered/passed!
      if (orderProgress < vehicleProgress) {
        return true;
      }
    }

    return false;
  }

  void _centerMapOnActiveRoute() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final waypoints = widget.state.activeRoute.waypoints;
      if (waypoints.isNotEmpty) {
        _mapController.move(waypoints.first.point, 13.2);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDeliveryMode = widget.state.isDeliveryModeActive;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Delivery Mode Active Banner (Visible when Delivery Mode is ON) ──
          if (isDeliveryMode) ...[
            _buildDeliveryModeActiveBanner(context),
            const SizedBox(height: 16),
          ],

          // ── Setup & Management Cards (HIDDEN when Delivery Mode is ON) ──
          if (!isDeliveryMode) ...[
            // 1. Standalone Location & Selling Route Selection Card (Placed right before Live Broadcast!)
            _buildLocationSelectionCard(context),
            const SizedBox(height: 16),

            // 2. Live Route Switch Card
            _buildLiveRouteSwitchCard(context),
            const SizedBox(height: 16),

            // 3. Daily Business Stats Grid (Total Enquiries, Completed, Incompleted, Missed)
            _buildBusinessStatsGrid(context),
            const SizedBox(height: 16),
          ],

          // ── Always Visible Core Operation Components ──
          // 4. Interactive Vehicle Map Section
          _buildLiveVehicleMapSection(context),
          const SizedBox(height: 20),

          // 5. Today's Enquiries Section (Ordered by proximity along selling route)
          _buildTodaysEnquiriesSection(context),
          const SizedBox(height: 100), // padding for bottom bar
        ],
      ),
    );
  }

  Widget _buildDeliveryModeActiveBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF16A34A), Color(0xFF15803D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF16A34A).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.local_shipping_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DELIVERY MODE ACTIVE 🚚',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Focused navigation & order fulfillment view. Setup cards hidden.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSelectionCard(BuildContext context) {
    final activeRoute = widget.state.activeRoute;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.location_on_rounded,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'SELLING LOCATION & ROUTE',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.verified_rounded, size: 12, color: AppColors.primary),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            activeRoute.name,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              ElevatedButton.icon(
                onPressed: () => showVendorRouteManagerModal(context),
                icon: const Icon(Icons.alt_route, size: 15),
                label: Text(
                  'Change 📍',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 2,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 12),

          // Route Details summary bar
          Row(
            children: [
              const Icon(Icons.route_outlined, size: 16, color: AppColors.outline),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${activeRoute.startPointName} ➔ ${activeRoute.endPointName} (${activeRoute.waypoints.length} waypoints)',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.outline,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLiveRouteSwitchCard(BuildContext context) {
    final isLive = widget.state.isLiveRouteActive;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isLive ? const Color(0xFFE8F8EE) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isLive ? AppColors.primary : AppColors.surfaceContainerHigh,
          width: isLive ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: isLive ? 0.12 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: isLive ? const Color(0xFF16A34A) : AppColors.outline,
                      shape: BoxShape.circle,
                      boxShadow: isLive
                          ? [
                              BoxShadow(
                                color: const Color(0xFF16A34A).withValues(alpha: 0.4),
                                blurRadius: 8,
                                spreadRadius: 2,
                              )
                            ]
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isLive ? 'LIVE BROADCASTING' : 'BROADCAST OFF',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.1,
                          color: isLive ? const Color(0xFF16A34A) : AppColors.outline,
                        ),
                      ),
                      Text(
                        isLive ? 'Buyers nearby can see your vehicle' : 'Turn on to start selling',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: AppColors.outline,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Switch(
                value: isLive,
                onChanged: (val) {
                  context.read<VendorHomeBloc>().add(VendorToggleLiveRoute(val));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        val ? 'Live Location Broadcasting Started! 🚚' : 'Live Broadcasting Stopped',
                        style: GoogleFonts.plusJakartaSans(color: Colors.white),
                      ),
                      backgroundColor: val ? AppColors.primary : AppColors.outline,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                activeThumbColor: AppColors.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessStatsGrid(BuildContext context) {
    final state = widget.state;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.surfaceContainerHigh),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Title with Analytics Icon & Live Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.insights_rounded, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Business Performance',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.onSurface,
                        ),
                      ),
                      Text(
                        'Overview of enquiries & order status',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: AppColors.outline,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF86EFAC)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF15803D),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'REALTIME',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF15803D),
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 14),

          // ── TOP TIER: Enquiries Summary Row (Total Enquiries & Today's Enquiries) ──
          Row(
            children: [
              // Total Enquiries Card (Emerald Gradient)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF059669), Color(0xFF10B981)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withValues(alpha: 0.28),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.forum_rounded, color: Colors.white, size: 16),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '+18%',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '${state.totalEnquiries}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Total Enquiries',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.95),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Today's Enquiries Card (Teal/Primary Gradient)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF14B8A6).withValues(alpha: 0.28),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 16),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'TODAY',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '${state.todaysEnquiriesCount}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Today\'s Enquiries',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.95),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ── BOTTOM TIER: 3-Column Order Fulfillment Breakdown Cards ──
          Row(
            children: [
              // 1. Total Completed Orders Card
              Expanded(
                child: _buildStatusMetricCard(
                  title: 'Completed',
                  value: '${state.completedOrdersCount}',
                  subtitle: 'Fulfilled',
                  icon: Icons.check_circle_rounded,
                  bgColor: const Color(0xFFF0FDF4),
                  borderColor: const Color(0xFFBBF7D0),
                  iconColor: const Color(0xFF16A34A),
                  valueColor: const Color(0xFF15803D),
                ),
              ),
              const SizedBox(width: 8),
              // 2. Total Incompleted (Pending) Orders Card
              Expanded(
                child: _buildStatusMetricCard(
                  title: 'Incompleted',
                  value: '${state.incompletedOrdersCount}',
                  subtitle: 'Pending',
                  icon: Icons.hourglass_top_rounded,
                  bgColor: const Color(0xFFFFFBEB),
                  borderColor: const Color(0xFFFDE68A),
                  iconColor: const Color(0xFFD97706),
                  valueColor: const Color(0xFFB45309),
                ),
              ),
              const SizedBox(width: 8),
              // 3. Missed Orders Card
              Expanded(
                child: _buildStatusMetricCard(
                  title: 'Missed',
                  value: '${state.missedOrdersCount}',
                  subtitle: 'Expired',
                  icon: Icons.running_with_errors_rounded,
                  bgColor: const Color(0xFFFFF1F2),
                  borderColor: const Color(0xFFFECDD3),
                  iconColor: const Color(0xFFE11D48),
                  valueColor: const Color(0xFFBE123C),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color bgColor,
    required Color borderColor,
    required Color iconColor,
    required Color valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: iconColor, size: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 8.5,
                    fontWeight: FontWeight.bold,
                    color: iconColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: valueColor,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: valueColor.withValues(alpha: 0.85),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildLiveVehicleMapSection(BuildContext context) {
    final activeRoute = widget.state.activeRoute;
    final polylinePoints = activeRoute.polylinePoints;
    final initialMapCenter = activeRoute.waypoints.isNotEmpty
        ? activeRoute.waypoints.first.point
        : const LatLng(10.5890, 76.0450); // Thrissur / Chittattukara center

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.surfaceContainerHigh),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Live Selling Route Line',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.onSurface,
                      ),
                    ),
                    Text(
                      activeRoute.name,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => showVendorRouteManagerModal(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.gps_fixed, size: 14, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        '${activeRoute.waypoints.length} Waypoints',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Stack(
            children: [
              Container(
                height: 440,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.surfaceContainer),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: initialMapCenter,
                      initialZoom: 13.2,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.onway.vendor',
                      ),
                      if (polylinePoints.length >= 2)
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: polylinePoints,
                              color: AppColors.primary,
                              strokeWidth: 5.0,
                            ),
                          ],
                        ),
                      MarkerLayer(
                        markers: [
                          // 1. Selling Route Waypoint Markers (Start, End, Intermediate stops)
                          ...activeRoute.waypoints.map((wp) {
                            final isStart = wp.isStart;
                            final isEnd = wp.isEnd;
                            return Marker(
                              point: wp.point,
                              width: 36,
                              height: 36,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: isStart
                                      ? Colors.green
                                      : isEnd
                                          ? Colors.red
                                          : AppColors.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                                ),
                                child: Icon(
                                  isStart
                                      ? Icons.play_arrow
                                      : isEnd
                                          ? Icons.flag
                                          : Icons.location_on,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            );
                          }),

                          // 2. Live Vehicle Current Position Marker
                          Marker(
                            point: widget.state.currentVehicleLocation,
                            width: 120,
                            height: 60,
                            alignment: Alignment.topCenter,
                            child: GestureDetector(
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '🚚 Vehicle Location: ${widget.state.vehicleNumber} (Selling Active)',
                                      style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                    backgroundColor: const Color(0xFF16A34A),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              },
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF16A34A), Color(0xFF15803D)],
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: const [
                                        BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.navigation_rounded, size: 10, color: Colors.white),
                                        const SizedBox(width: 3),
                                        Text(
                                          widget.state.vehicleNumber,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF16A34A),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2.5),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF16A34A).withValues(alpha: 0.5),
                                          blurRadius: 10,
                                          spreadRadius: 3,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.local_shipping_rounded,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // 3. Active Order Placed Location Markers (Completed & >500m Covered Area orders are HIDDEN!)
                          ...widget.state.enquiries
                              .where((enq) {
                            // 1. Hide completed orders from map
                            if (enq.status == 'Completed') return false;
                            // 2. Hide covered/passed area orders (> 500m behind vehicle)
                            if (_isOrderPassedAndCovered(
                                widget.state.currentVehicleLocation, enq.location, activeRoute.waypoints)) {
                              return false;
                            }
                            return true;
                          }).map((enq) {
                            final isPending = enq.status == 'Pending';
                            final pinColor = isPending
                                ? const Color(0xFFF59E0B) // Amber/Orange for active pending pre-orders
                                : const Color(0xFFE11D48); // Rose for missed pre-orders

                            return Marker(
                              point: enq.location,
                              width: 100,
                              height: 52,
                              alignment: Alignment.topCenter,
                              child: GestureDetector(
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        '📦 Order ${enq.enquiryId} by ${enq.buyerName} (${enq.distanceMeters}m away)',
                                        style: GoogleFonts.plusJakartaSans(
                                            color: Colors.white, fontWeight: FontWeight.bold),
                                      ),
                                      backgroundColor: pinColor,
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                },
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Order Badge Label
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: pinColor, width: 1.5),
                                        boxShadow: const [
                                          BoxShadow(
                                              color: Colors.black26,
                                              blurRadius: 4,
                                              offset: Offset(0, 2)),
                                        ],
                                      ),
                                      child: Text(
                                        '📦 ${enq.buyerName.split(' ').first}',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.onSurface,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    // Order Pin Icon
                                    Container(
                                      width: 26,
                                      height: 26,
                                      decoration: BoxDecoration(
                                        color: pinColor,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 2),
                                        boxShadow: [
                                          BoxShadow(
                                            color: pinColor.withValues(alpha: 0.4),
                                            blurRadius: 6,
                                            spreadRadius: 1,
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        isPending ? Icons.shopping_bag_rounded : Icons.cancel_rounded,
                                        color: Colors.white,
                                        size: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // Floating Recenter Map Button
              Positioned(
                bottom: 12,
                right: 12,
                child: FloatingActionButton.small(
                  heroTag: 'recenter_map_btn',
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                  onPressed: _centerMapOnActiveRoute,
                  child: const Icon(Icons.my_location),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTodaysEnquiriesSection(BuildContext context) {
    final enquiries = widget.state.enquiries;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Today\'s Buyer Enquiries',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.onSurface,
                  ),
                ),
                Text(
                  'Sorted by route proximity (Nearest buyer first)',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AppColors.outline,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${enquiries.length} Enquiries',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (enquiries.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.surfaceContainerHigh),
            ),
            child: Column(
              children: [
                const Icon(Icons.inbox, size: 48, color: AppColors.outline),
                const SizedBox(height: 8),
                Text(
                  'No enquiries on this route yet',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: AppColors.outline,
                  ),
                ),
              ],
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: enquiries.length,
            itemBuilder: (context, index) {
              final enq = enquiries[index];
              final isCompleted = enq.status == 'Completed';
              final isMissed = enq.status == 'Missed';
              final isUnder250m = enq.distanceMeters <= 250 && enq.status == 'Pending';

              return Stack(
                children: [
                  Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: isMissed
                          ? const Color(0xFFFFF1F2)
                          : (isCompleted ? const Color(0xFFF0FDF4) : Colors.white),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: isMissed
                            ? const Color(0xFFFECDD3)
                            : (isCompleted
                                ? Colors.green.shade500
                                : (isUnder250m ? AppColors.primary : AppColors.surfaceContainerHigh)),
                        width: isMissed || isCompleted || isUnder250m ? 2 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isMissed
                              ? const Color(0xFFE11D48).withValues(alpha: 0.08)
                              : (isCompleted
                                  ? Colors.green.withValues(alpha: 0.08)
                                  : Colors.black.withValues(alpha: 0.03)),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header: ID, Price Tag & Status Badge
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              enq.enquiryId,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isMissed
                                    ? const Color(0xFFFFE4E6)
                                    : (isCompleted
                                        ? const Color(0xFFDCFCE7)
                                        : Colors.amber.withValues(alpha: 0.15)),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                enq.status.toUpperCase(),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: isMissed
                                      ? const Color(0xFFE11D48)
                                      : (isCompleted
                                          ? const Color(0xFF15803D)
                                          : Colors.amber.shade900),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Buyer Info & Waypoint Location
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.person, size: 16, color: AppColors.primary),
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      enq.buyerName,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.onSurface,
                                      ),
                                    ),
                                    Text(
                                      enq.buyerPhone,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        color: AppColors.outline,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.location_on, size: 12, color: AppColors.primary),
                                    const SizedBox(width: 2),
                                    Text(
                                      enq.waypointName,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  '${enq.distanceMeters}m away • ${enq.timeAgo}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    color: AppColors.outline,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        // Requested Items
                        Text(
                          'Requested Items:',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: AppColors.outline,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          enq.itemsSummary,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onSurface,
                          ),
                        ),

                        const SizedBox(height: 12),
                        const Divider(height: 1),
                        const SizedBox(height: 10),

                        // Action Buttons (Ring Buyer, Order Complete, Pending, Missed)
                        Row(
                          children: [
                            // Ring Buyer Button
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: isUnder250m
                                    ? () {
                                        context.read<VendorHomeBloc>().add(VendorRingBuyer(enq.enquiryId, enq.buyerName));
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('🔔 Buyer ${enq.buyerName} is being notified!', style: GoogleFonts.plusJakartaSans(color: Colors.white)),
                                            backgroundColor: AppColors.primary,
                                          ),
                                        );
                                      }
                                    : null,
                                icon: Icon(
                                  isMissed
                                      ? Icons.history
                                      : (isCompleted ? Icons.check_circle : Icons.notifications_active),
                                  size: 16,
                                ),
                                label: Text(
                                  isMissed
                                      ? 'Order Missed ⚠️'
                                      : (isCompleted
                                          ? 'Order Complete ✅'
                                          : (isUnder250m ? 'Ring Buyer 🔔' : '<250m to Ring')),
                                  style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isMissed
                                      ? const Color(0xFFFFE4E6)
                                      : (isCompleted
                                          ? Colors.green.shade700
                                          : (isUnder250m ? AppColors.primary : Colors.grey.shade300)),
                                  foregroundColor: isMissed
                                      ? const Color(0xFFE11D48)
                                      : (isCompleted || isUnder250m ? Colors.white : Colors.grey.shade600),
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  elevation: 0,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            // Order Complete Button
                            IconButton(
                              onPressed: () {
                                context.read<VendorHomeBloc>().add(VendorUpdateEnquiryStatus(enq.enquiryId, 'Completed'));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Order marked as COMPLETED ✅', style: GoogleFonts.plusJakartaSans()),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              },
                              icon: Icon(
                                Icons.check_circle,
                                color: isCompleted ? Colors.green.shade700 : Colors.green,
                                size: 24,
                              ),
                              tooltip: 'Mark Completed',
                            ),
                            // Order Pending Button
                            IconButton(
                              onPressed: () {
                                context.read<VendorHomeBloc>().add(VendorUpdateEnquiryStatus(enq.enquiryId, 'Pending'));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Order marked as PENDING ⏳', style: GoogleFonts.plusJakartaSans()),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                              },
                              icon: const Icon(Icons.history_toggle_off, color: Colors.orange, size: 24),
                              tooltip: 'Mark Pending',
                            ),
                            // Mark Missed Button
                            IconButton(
                              onPressed: () {
                                context.read<VendorHomeBloc>().add(VendorUpdateEnquiryStatus(enq.enquiryId, 'Missed'));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Order marked as MISSED ❌', style: GoogleFonts.plusJakartaSans()),
                                    backgroundColor: const Color(0xFFE11D48),
                                  ),
                                );
                              },
                              icon: Icon(
                                Icons.cancel_rounded,
                                color: isMissed ? const Color(0xFFE11D48) : Colors.red.shade400,
                                size: 24,
                              ),
                              tooltip: 'Mark Missed',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Transparent Big Tick Watermark Layer for Completed Orders
                  if (isCompleted)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 36, bottom: 20),
                            child: Opacity(
                              opacity: 0.15,
                              child: Icon(
                                Icons.check_circle_rounded,
                                size: 110,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Transparent Big Cross Watermark Layer for Missed Orders
                  if (isMissed)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 36, bottom: 20),
                            child: Opacity(
                              opacity: 0.15,
                              child: const Icon(
                                Icons.cancel_rounded,
                                size: 110,
                                color: Color(0xFFE11D48),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
      ],
    );
  }
}
