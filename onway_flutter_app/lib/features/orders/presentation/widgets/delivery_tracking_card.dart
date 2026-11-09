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
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: Small Image + Name + Category + LIVE Tag + Save Chip
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: Image.asset(
                      widget.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: AppColors.primaryContainer,
                        child: const Icon(Icons.store, color: AppColors.primary, size: 22),
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
                                fontSize: 14.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Row(
                            mainAxisSize: MainAxisSize.min,
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
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDCFCE7),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Text(
                                    'LIVE',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF15803D),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.category,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          color: AppColors.outline,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Stats Row: Rating, Distance, ETA
            Row(
              children: [
                _buildStatItem(Icons.star_rounded, const Color(0xFFF59E0B), '${widget.rating}'),
                const SizedBox(width: 12),
                _buildStatItem(Icons.near_me_rounded, AppColors.primary, widget.distance),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F8EE),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.schedule_rounded, size: 11, color: Color(0xFF1EB956)),
                      const SizedBox(width: 3),
                      Text(
                        widget.eta,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1EB956),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Progress Bar
            _buildProgressBar(),
            const SizedBox(height: 10),
            // 4 Single-Row Compact Action Buttons
            _buildToggleGrid(context),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 3),
        Text(
          text,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final clampedProgress = widget.progress.clamp(0.0, 1.0);
        return SizedBox(
          height: 18,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.centerLeft,
            children: [
              Container(
                height: 4,
                width: width,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Container(
                height: 4,
                width: width * clampedProgress,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
              Positioned(
                left: ((width * clampedProgress) - 10).clamp(0.0, width - 20),
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Icon(widget.progressIcon, size: 11, color: AppColors.primary),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildToggleGrid(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSingleRowButton(
                icon: notifyOnReach ? Icons.notifications_active_rounded : Icons.notifications_none_rounded,
                label: 'Notify',
                isActive: notifyOnReach,
                onTap: () => setState(() => notifyOnReach = !notifyOnReach),
              ),
            ),
            const SizedBox(width: 5),
            Expanded(
              child: _buildSingleRowButton(
                icon: Icons.calendar_today_rounded,
                label: 'Daily',
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
            const SizedBox(width: 5),
            Expanded(
              child: _buildSingleRowButton(
                icon: ringOnReach ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                label: 'Ring',
                isActive: ringOnReach,
                onTap: () => setState(() => ringOnReach = !ringOnReach),
              ),
            ),
            const SizedBox(width: 5),
            Expanded(
              child: _buildSingleRowButton(
                icon: showMap ? Icons.map_rounded : Icons.map_outlined,
                label: showMap ? 'Hide' : 'Map',
                isActive: showMap,
                isAction: true,
                onTap: () => setState(() => showMap = !showMap),
              ),
            ),
          ],
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.fastOutSlowIn,
          child: showMap
              ? Column(
                  children: [
                    const SizedBox(height: 10),
                    _buildInlineLiveVendorRoute(),
                  ],
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildSingleRowButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    bool isAction = false,
  }) {
    Color bg;
    Color border;
    Color fg;

    if (isAction) {
      if (isActive) {
        bg = AppColors.primary;
        border = AppColors.primary;
        fg = Colors.white;
      } else {
        bg = const Color(0xFFE8F8EE);
        border = const Color(0xFF1EB956).withValues(alpha: 0.4);
        fg = const Color(0xFF1EB956);
      }
    } else {
      if (isActive) {
        bg = AppColors.primary.withValues(alpha: 0.08);
        border = AppColors.primary.withValues(alpha: 0.4);
        fg = AppColors.primary;
      } else {
        bg = const Color(0xFFF8FAF8);
        border = const Color(0xFFE2E8F0);
        fg = AppColors.outline;
      }
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: border, width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 13, color: fg),
              const SizedBox(width: 3),
              Flexible(
                child: Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                    color: fg,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
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
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAF8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
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
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.onSurface,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        'LIVE TRACKING',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              height: 140,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFdae2fd),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFbccbb9)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: FlutterMap(
                  options: const MapOptions(
                    initialCenter: LatLng(10.5934, 76.0803),
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
                            LatLng(10.5910, 76.0775),
                            LatLng(10.5925, 76.0790),
                            LatLng(10.5934, 76.0803),
                            LatLng(10.5950, 76.0820),
                          ],
                          color: AppColors.primary,
                          strokeWidth: 3.5,
                        ),
                      ],
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: const LatLng(10.5910, 76.0775),
                          width: 14,
                          height: 14,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.outline, width: 2),
                              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                            ),
                            child: Center(
                              child: Container(
                                width: 5,
                                height: 5,
                                decoration: const BoxDecoration(color: AppColors.outline, shape: BoxShape.circle),
                              ),
                            ),
                          ),
                        ),
                        Marker(
                          point: const LatLng(10.5950, 76.0820),
                          width: 36,
                          height: 36,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                                ),
                              ),
                              const SizedBox(height: 1),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'YOU',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 8.5,
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
                          point: const LatLng(10.5934, 76.0803),
                          width: 28,
                          height: 28,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 1.5),
                              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                            ),
                            child: const Icon(Icons.local_shipping, color: Colors.white, size: 14),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(color: AppColors.outline, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.vendorName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Arriving Soon (${widget.eta})',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
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
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: isFavorite ? AppColors.primary : AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 2),
                Icon(
                  isFavorite ? Icons.bookmark : Icons.bookmark_border,
                  color: isFavorite ? AppColors.primary : AppColors.onSurfaceVariant,
                  size: 11,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
