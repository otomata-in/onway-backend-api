import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../home/presentation/bloc/home_bloc.dart';
import '../../../home/presentation/bloc/home_event.dart';
import '../../../home/presentation/bloc/home_state.dart';
import '../../../vendor_details/presentation/pages/live_tracking_page.dart';
import '../../../vendor_details/presentation/pages/retail_vendor_page.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class DeliveryTrackingCard extends StatefulWidget {
  final String vendorName;
  final String category;
  final String imageUrl;
  final String eta;
  final double progress; // 0.0 to 1.0
  final IconData progressIcon;
  final String distance;
  final double rating;
  final bool isLive;
  final bool initialDailyTracking;
  final VoidCallback? onUnselectDailyTracking;

  const DeliveryTrackingCard({
    super.key,
    required this.vendorName,
    required this.category,
    required this.imageUrl,
    required this.eta,
    required this.progress,
    required this.progressIcon,
    required this.distance,
    this.rating = 4.8,
    this.isLive = true,
    this.initialDailyTracking = true,
    this.onUnselectDailyTracking,
  });

  @override
  State<DeliveryTrackingCard> createState() => _DeliveryTrackingCardState();
}

class _DeliveryTrackingCardState extends State<DeliveryTrackingCard> {
  bool notifyOnReach = true;
  late bool dailyTracking;
  bool ringOnReach = true;
  bool showMap = false;

  @override
  void initState() {
    super.initState();
    dailyTracking = widget.initialDailyTracking;
  }

  @override
  Widget build(BuildContext context) {
    final vendorInfo = VendorInfo(
      name: widget.vendorName,
      subtitle: widget.category,
      emoji: '🥦',
      imagePath: widget.imageUrl,
      rating: widget.rating,
      eta: widget.eta,
      distance: widget.distance,
      isLive: widget.isLive,
      category: widget.category,
    );

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RetailVendorPage(vendorInfo: vendorInfo),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.surfaceContainerLow),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: Small Image + Name + Category + LIVE Tag
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.surfaceContainer),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: Image.asset(
                    widget.imageUrl,
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
                            widget.vendorName,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.onSurface,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            _SaveSellerChip(
                              vendorName: widget.vendorName,
                              category: widget.category,
                              imageUrl: widget.imageUrl,
                              rating: widget.rating,
                              eta: widget.eta,
                              distance: widget.distance,
                            ),
                            if (widget.isLive) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.error.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'LIVE',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.error,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.category,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: AppColors.outline,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Stats Row: Rating, ETA, Distance
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem(Icons.star, Colors.orange, '${widget.rating}'),
              _buildStatItem(Icons.schedule, AppColors.primary, widget.eta),
              _buildStatItem(Icons.location_on, AppColors.onSurfaceVariant, widget.distance),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.surfaceContainerHigh, height: 1),
          const SizedBox(height: 16),
          // Progress Bar
          _buildProgressBar(),
          const SizedBox(height: 16),
          // 2x2 Toggle Grid
          _buildToggleGrid(context),
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
        Text(
          text,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar() {
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
                      width: width * widget.progress,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Positioned(
                      left: (width * widget.progress) - 16,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.primary, width: 2),
                        ),
                        child: Icon(widget.progressIcon, size: 16, color: AppColors.primary),
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
                widget.eta,
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

  Widget _buildToggleGrid(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildToggleButton(
                icon: Icons.notifications_none,
                label: 'Notify on reach',
                isActive: notifyOnReach,
                onTap: () => setState(() => notifyOnReach = !notifyOnReach),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildToggleButton(
                icon: Icons.calendar_today_outlined,
                label: 'Daily Tracking',
                isActive: dailyTracking,
                onTap: () {
                  if (dailyTracking && widget.onUnselectDailyTracking != null) {
                    widget.onUnselectDailyTracking!();
                  } else {
                    setState(() => dailyTracking = !dailyTracking);
                  }
                },
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
                onTap: () => setState(() => ringOnReach = !ringOnReach),
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
              ? Column(
                  children: [
                    const SizedBox(height: 16),
                    _buildInlineLiveVendorRoute(),
                  ],
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildInlineLiveVendorRoute() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LiveTrackingPage(
              orderInfo: ActiveOrderInfo(
                vendorName: widget.vendorName,
                eta: widget.eta,
                distance: widget.distance,
                progress: widget.progress,
              ),
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
                options: const MapOptions(
                  initialCenter: LatLng(34.0541, -118.2458),
                  initialZoom: 15.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.onway_market',
                  ),
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: const [
                          LatLng(34.0522, -118.2437),
                          LatLng(34.0530, -118.2450),
                          LatLng(34.0545, -118.2465),
                          LatLng(34.0560, -118.2480),
                        ],
                        color: AppColors.primary,
                        strokeWidth: 4.0,
                      ),
                    ],
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: const LatLng(34.0522, -118.2437),
                        width: 16,
                        height: 16,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.outline, width: 2),
                            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                          ),
                          child: Center(
                            child: Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(color: AppColors.outline, shape: BoxShape.circle),
                            ),
                          ),
                        ),
                      ),
                      Marker(
                        point: const LatLng(34.0560, -118.2480),
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
                        point: const LatLng(34.0545, -118.2465),
                        width: 32,
                        height: 32,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8)],
                          ),
                          child: const Icon(Icons.local_shipping, color: Colors.white, size: 16),
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
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(color: AppColors.outline, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    widget.vendorName,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Arriving Soon (${widget.eta})',
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
          color: isActive ? primaryColor.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? primaryColor : const Color(0xFFE2E3DD),
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
                  color: isActive ? AppColors.primary : AppColors.onSurface,
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

class _SaveSellerChip extends StatelessWidget {
  final String vendorName;
  final String category;
  final String imageUrl;
  final double rating;
  final String eta;
  final String distance;

  const _SaveSellerChip({
    required this.vendorName,
    required this.category,
    required this.imageUrl,
    required this.rating,
    required this.eta,
    required this.distance,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        final vendor = VendorInfo(
          name: vendorName,
          subtitle: category,
          emoji: '🥦',
          imagePath: imageUrl,
          rating: rating,
          eta: eta,
          distance: distance,
          isLive: true,
          category: category,
        );

        final currentVendor = state.vendors.firstWhere(
          (v) => v.name == vendorName,
          orElse: () => vendor,
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
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isFavorite ? AppColors.primary : AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 3),
                Icon(
                  isFavorite ? Icons.bookmark : Icons.bookmark_border,
                  color: isFavorite ? AppColors.primary : AppColors.onSurfaceVariant,
                  size: 13,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
