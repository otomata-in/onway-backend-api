import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/standard_top_bar.dart';
import '../../../home/presentation/bloc/home_state.dart';
import '../../../home/presentation/widgets/vendor_card.dart';
import '../bloc/vendor_details_bloc.dart';
import '../bloc/vendor_details_event.dart';
import '../bloc/vendor_details_state.dart';

class LiveTrackingPage extends StatelessWidget {
  final ActiveOrderInfo orderInfo;
  final String? vendorId;

  const LiveTrackingPage({super.key, required this.orderInfo, this.vendorId});

  @override
  Widget build(BuildContext context) {
    final targetVendorId = (vendorId != null && vendorId!.isNotEmpty)
        ? vendorId!
        : orderInfo.vendorId;

    return BlocProvider(
      create: (_) => VendorDetailsBloc()..add(VendorDetailsLoadRequested(vendorId: targetVendorId)),
      child: _LiveTrackingView(orderInfo: orderInfo),
    );
  }
}

class _LiveTrackingView extends StatefulWidget {
  final ActiveOrderInfo orderInfo;

  const _LiveTrackingView({required this.orderInfo});

  @override
  State<_LiveTrackingView> createState() => _LiveTrackingViewState();
}

class _LiveTrackingViewState extends State<_LiveTrackingView> {
  bool notifyOnReach = true;
  bool ringOnReach = true;
  bool dailyTracking = true;

  List<LatLng> _generateRoadwayPolyline(List<LatLng> waypoints) {
    if (waypoints.isEmpty) return [];
    if (waypoints.length == 1) return waypoints;

    final List<LatLng> result = [];
    for (int i = 0; i < waypoints.length - 1; i++) {
      final start = waypoints[i];
      final end = waypoints[i + 1];
      result.add(start);

      // Interpolate smooth curved roadway points between waypoints
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
                  _buildAppBar(context),
                  _buildTrackingHeader(),
                  _buildLiveVendorRoute(state),
                  _buildVendorDetailsCard(),
                  _buildPreferencesSection(),
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
              _buildBottomActionBar(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return const StandardTopBar(
      title: 'Live Vendor Route',
      subtitle: 'Real-time GPS navigation & tracking',
      icon: Icons.local_shipping,
      showBackButton: true,
    );
  }

  Widget _buildTrackingHeader() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.surfaceContainerHigh),
          boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.06), blurRadius: 24, offset: const Offset(0, 6))],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.orderInfo.eta, style: GoogleFonts.plusJakartaSans(fontSize: 19, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 12, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text('${widget.orderInfo.distance} away', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.onSurfaceVariant)),
                      ],
                    ),
                  ],
                ),
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: Color(0xFFdae2fd),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(Icons.local_shipping, color: AppColors.primary, size: 19),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: SizedBox(
                height: 6,
                child: Stack(
                  children: [
                    Container(color: const Color(0xFFdae2fd)),
                    FractionallySizedBox(
                      widthFactor: widget.orderInfo.progress,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF92f5a4), Color(0xFF22c55e)]),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(widget.orderInfo.vendorName, style: GoogleFonts.plusJakartaSans(fontSize: 9, fontWeight: FontWeight.w500, color: AppColors.onSurfaceVariant)),
                Text('Your Location', style: GoogleFonts.plusJakartaSans(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.primary)),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildVendorDetailsCard() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: VendorCard(
          vendor: VendorInfo(
            id: widget.orderInfo.vendorId,
            name: widget.orderInfo.vendorName,
            subtitle: widget.orderInfo.category,
            emoji: widget.orderInfo.emoji,
            imagePath: 'assets/images/vendor_green_valley.png',
            rating: 4.9,
            eta: widget.orderInfo.eta,
            distance: widget.orderInfo.distance,
            isLive: true,
            category: widget.orderInfo.category,
            latitude: widget.orderInfo.vendorLat,
            longitude: widget.orderInfo.vendorLng,
          ),
        ),
      ),
    );
  }

  Widget _buildLiveVendorRoute(VendorDetailsState state) {
    final routePoints = _generateRoadwayPolyline(state.routePoints);
    final vendorPos = LatLng(
      (state.vendorLat != 9.9792 && state.vendorLat != 0.0) ? state.vendorLat : widget.orderInfo.vendorLat,
      (state.vendorLng != 76.2765 && state.vendorLng != 0.0) ? state.vendorLng : widget.orderInfo.vendorLng,
    );
    final buyerPos = LatLng(widget.orderInfo.buyerLat, widget.orderInfo.buyerLng);
    final mapCenter = LatLng(
      (vendorPos.latitude + buyerPos.latitude) / 2,
      (vendorPos.longitude + buyerPos.longitude) / 2,
    );

    final activePolyline = routePoints.isNotEmpty
        ? routePoints
        : _generateRoadwayPolyline([
            vendorPos,
            LatLng((vendorPos.latitude + buyerPos.latitude) / 2 + 0.002, (vendorPos.longitude + buyerPos.longitude) / 2 - 0.002),
            buyerPos,
          ]);

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.surfaceContainerLow),
          boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.08), blurRadius: 32, offset: const Offset(0, 8))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Live Vendor Route', style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    children: [
                      Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Text('LIVE GPS', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.primary)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              height: 300,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFdae2fd),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFbccbb9)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: mapCenter,
                    initialZoom: 14.8,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.onway_market',
                    ),
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: activePolyline,
                          color: AppColors.primary,
                          strokeWidth: 4.5,
                        ),
                      ],
                    ),
                    MarkerLayer(
                      markers: [
                        // Waypoint Markers (Start, Intermediate, End)
                        ...state.rawWaypoints.map((wp) {
                          final pos = LatLng(wp['latitude'], wp['longitude']);
                          final isStart = wp['isStart'] == true;
                          final isEnd = wp['isEnd'] == true;
                          final name = wp['name'] ?? 'Stop';

                          return Marker(
                            point: pos,
                            width: 110,
                            height: 50,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isStart
                                        ? const Color(0xFF15803D)
                                        : (isEnd ? const Color(0xFFB91C1C) : Colors.white),
                                    borderRadius: BorderRadius.circular(6),
                                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                                  ),
                                  child: Text(
                                    isStart ? '▶ START: $name' : (isEnd ? '🏁 END: $name' : '📍 $name'),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      color: (isStart || isEnd) ? Colors.white : AppColors.onSurface,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: isStart ? const Color(0xFF15803D) : (isEnd ? const Color(0xFFB91C1C) : AppColors.primary),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),

                        // YOU Marker (Buyer Location)
                        Marker(
                          point: buyerPos,
                          width: 44,
                          height: 44,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 18,
                                height: 18,
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2.5),
                                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                                ),
                              ),
                              const SizedBox(height: 2),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: AppColors.primary, width: 1),
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

                        // Live Vendor Truck Marker
                        Marker(
                          point: vendorPos,
                          width: 40,
                          height: 40,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: Colors.black38, blurRadius: 8)],
                            ),
                            child: const Icon(Icons.local_shipping, color: Colors.white, size: 22),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.outline, shape: BoxShape.circle)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          widget.orderInfo.vendorName,
                          style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.onSurfaceVariant),
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
                    Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    Text(
                      'Arriving Soon (${widget.orderInfo.eta})',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildPreferencesSection() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.surfaceContainerLow),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notification Preferences',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Live arrival alerts and proximity triggers',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppColors.outline,
              ),
            ),
            const SizedBox(height: 16),
            _buildPreferenceTile(
              title: 'Notify on Reach',
              subtitle: 'Receive instant push alerts when seller is 500m away',
              icon: Icons.notifications_none,
              value: notifyOnReach,
              onChanged: (val) => setState(() => notifyOnReach = val),
            ),
            const SizedBox(height: 12),
            _buildPreferenceTile(
              title: 'Ring on Reach',
              subtitle: 'Loud ringer alert as seller enters your street',
              icon: Icons.notifications_active_outlined,
              value: ringOnReach,
              onChanged: (val) => setState(() => ringOnReach = val),
            ),
            const SizedBox(height: 12),
            _buildPreferenceTile(
              title: 'Daily Tracking',
              subtitle: 'Track vendor schedule & daily recurring stops',
              icon: Icons.calendar_today_outlined,
              value: dailyTracking,
              onChanged: (val) => setState(() => dailyTracking = val),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreferenceTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: value ? AppColors.primary.withValues(alpha: 0.05) : const Color(0xFFF8FAF8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value ? AppColors.primary.withValues(alpha: 0.3) : AppColors.surfaceContainerHigh,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: value ? AppColors.primary : AppColors.surfaceContainerLow,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 18,
              color: value ? Colors.white : AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: AppColors.outline,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.85),
          border: const Border(top: BorderSide(color: Color(0xFFdae2fd))),
          boxShadow: const [BoxShadow(color: Color(0x0D006e2f), blurRadius: 16, offset: Offset(0, -4))],
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF22c55e), Color(0xFF15803d)]),
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
          ),
          child: ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Notification preferences updated!',
                    style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  backgroundColor: AppColors.primary,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              shadowColor: Colors.transparent,
            ),
            child: Text('Save Preferences', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600)),
          ),
        ),
      ),
    );
  }
}
