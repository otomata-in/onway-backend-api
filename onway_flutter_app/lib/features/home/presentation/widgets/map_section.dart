import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/home_state.dart';

class MapSection extends StatefulWidget {
  final List<VendorInfo> vendors;
  final LatLng userLocation;
  final bool isLocationSelected;
  final VoidCallback? onSelectLocationTap;
  final double height;

  const MapSection({
    super.key,
    this.vendors = const [],
    this.userLocation = const LatLng(9.9790, 76.2760),
    this.isLocationSelected = false,
    this.onSelectLocationTap,
    this.height = 416, // 30% increase from original 320 (320 * 1.30 = 416)
  });

  @override
  State<MapSection> createState() => _MapSectionState();
}

class _MapSectionState extends State<MapSection> {
  final MapController _mapController = MapController();

  @override
  void didUpdateWidget(covariant MapSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLocationSelected &&
        (widget.userLocation != oldWidget.userLocation || widget.isLocationSelected != oldWidget.isLocationSelected)) {
      if (widget.userLocation.latitude != 0 &&
          widget.userLocation.longitude != 0 &&
          !widget.userLocation.latitude.isNaN &&
          !widget.userLocation.longitude.isNaN) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          try {
            _mapController.move(widget.userLocation, 15.8);
          } catch (_) {}
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLocationSelected) {
      return _buildRealInteractiveMap();
    }
    return _buildOriginalStaticMap();
  }

  // ═══════════════════════════════════════════════════════════════
  // Original Exact Static Map (Default Launch view)
  // ═══════════════════════════════════════════════════════════════
  Widget _buildOriginalStaticMap() {
    final mapHeight = widget.height;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: AppColors.surfaceContainerHigh.withValues(alpha: 0.5),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 30,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: SizedBox(
            height: mapHeight,
            child: Stack(
              children: [
                // Map background image
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/map_bg.png',
                    fit: BoxFit.cover,
                  ),
                ),
                // Gradient overlay for readability
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.white.withValues(alpha: 0.4),
                          Colors.transparent,
                          Colors.white.withValues(alpha: 0.2),
                        ],
                      ),
                    ),
                  ),
                ),

                // Floating UI: LIVE Badge
                Positioned(
                  top: 8,
                  left: 16,
                  child: _buildLiveBadge(),
                ),

                // Floating UI: Filters Chip
                Positioned(
                  top: 4,
                  right: 6,
                  child: _buildFiltersChip(),
                ),

                // ── Vendor Markers (positioned to match Stitch %) ──

                // Ocean Catch — top:15%, left:18%
                Positioned(
                  top: mapHeight * 0.15,
                  left: 390 * 0.18 - 30,
                  child: GestureDetector(
                    onTap: () {
                      final vendor = widget.vendors.isNotEmpty
                          ? widget.vendors.first
                          : const VendorInfo(
                              id: '', name: 'Mattom Organic Veggies', subtitle: 'Organic Vegetables', emoji: '🥦',
                              imagePath: 'assets/images/vendor_green_valley.png', rating: 4.9, eta: '2 mins',
                              distance: '50m', isLive: true, category: 'Organic Vegetables', isFavorite: true,
                              latitude: 10.5935, longitude: 76.0808,
                            );
                      _showVendorPopup(context, vendor);
                    },
                    child: _buildVendorMarker(
                      '🥦', 'Mattom Organic Veggies', '50m away',
                      bgColor: const Color(0xFFDBEAFE),
                      useImage: true,
                    ),
                  ),
                ),

                // Guruvayur Fruits — top:20%, left:75%
                Positioned(
                  top: mapHeight * 0.20,
                  left: 390 * 0.75 - 30,
                  child: GestureDetector(
                    onTap: () {
                      final vendor = widget.vendors.length > 1
                          ? widget.vendors[1]
                          : const VendorInfo(
                              id: '', name: 'Guruvayur Fresh Fruits Express', subtitle: 'Fresh Fruits', emoji: '🍎',
                              imagePath: 'assets/images/vendor_green_valley.png', rating: 4.8, eta: '4 mins',
                              distance: '250m', isLive: true, category: 'Fresh Fruits', isFavorite: false,
                              latitude: 10.5950, longitude: 76.0830,
                            );
                      _showVendorPopup(context, vendor);
                    },
                    child: _buildVendorMarker(
                      '🍎', 'Guruvayur Fruits', '250m away',
                      bgColor: const Color(0xFFFEF9C3),
                    ),
                  ),
                ),

                // Spice Route — top:25%, left:55%
                Positioned(
                  top: mapHeight * 0.25,
                  left: 390 * 0.55 - 30,
                  child: _buildVendorMarker(
                    '🌶️', 'Spice Route', '2km away',
                    bgColor: const Color(0xFFFEF2F2),
                  ),
                ),

                // Nutts Corner — top:5%, left:40%
                Positioned(
                  top: mapHeight * 0.05,
                  left: 390 * 0.40 - 30,
                  child: _buildVendorMarker(
                    '🍕', 'Nutts Corner', '10 mins away',
                    bgColor: const Color(0xFFFEE2E2),
                  ),
                ),

                // Fruit Basket — top:46%, right:4%
                Positioned(
                  top: mapHeight * 0.46,
                  right: 390 * 0.04,
                  child: _buildVendorMarker(
                    '🍎', 'Fruit Basket', '4 mins away',
                    bgColor: const Color(0xFFFEF9C3),
                  ),
                ),

                // Dairy Fresh — top:78.5%, right:10%
                Positioned(
                  top: mapHeight * 0.785,
                  right: 390 * 0.10,
                  child: _buildVendorMarker(
                    '🥛', 'Dairy Fresh', '600m away',
                    bgColor: const Color(0xFFEFF6FF),
                  ),
                ),

                // The Deli Van — top:68%, left:34%
                Positioned(
                  top: mapHeight * 0.68,
                  left: 390 * 0.34 - 30,
                  child: _buildVendorMarker(
                    '🧀', 'The Deli Van', '6 mins away',
                    bgColor: const Color(0xFFF3E8FF),
                  ),
                ),

                // Ice Cream Parlor — bottom:28%, left:2.5%
                Positioned(
                  bottom: mapHeight * 0.28,
                  left: 390 * 0.025,
                  child: _buildVendorMarker(
                    '🍦', 'Ice Cream Parlor', '1.2km away',
                    bgColor: const Color(0xFFEFF6FF),
                  ),
                ),

                // Home Marker (center)
                const Center(child: _AnimatedHomeMarker()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Vendor Popup Toast / Bottom Sheet ──
  void _showVendorPopup(BuildContext context, VendorInfo vendor) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 24,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(vendor.emoji, style: const TextStyle(fontSize: 26)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vendor.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${vendor.subtitle} • ${vendor.distance}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.tertiaryFixed,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, size: 13, color: AppColors.onTertiaryFixedVariant),
                        const SizedBox(width: 3),
                        Text(
                          '${vendor.rating}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.onTertiaryFixedVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    context.push('/retail-vendor', extra: vendor);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'View Seller Details',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, size: 18),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // Real Interactive Map (Activated after user selects address)
  // ═══════════════════════════════════════════════════════════════
  Widget _buildRealInteractiveMap() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: AppColors.surfaceContainerHigh.withValues(alpha: 0.5),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 30,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: SizedBox(
            height: widget.height,
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: widget.userLocation,
                    initialZoom: 15.8,
                    minZoom: 10.0,
                    maxZoom: 18.5,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.onway_market',
                    ),
                    MarkerLayer(
                      markers: [
                        // Selected User Address Marker ("MY HOME / FLAT")
                        Marker(
                          point: widget.userLocation,
                          width: 100,
                          height: 125,
                          alignment: Alignment.center,
                          child: const _AnimatedHomeMarker(),
                        ),
                        // Real Nearby Live Vendor Markers
                        ...widget.vendors.map((vendor) {
                          final pos = LatLng(vendor.latitude, vendor.longitude);
                          return Marker(
                            point: pos,
                            width: 140,
                            height: 90,
                            alignment: Alignment.topCenter,
                            child: GestureDetector(
                              onTap: () => _showVendorPopup(context, vendor),
                              child: _buildVendorMarker(
                                vendor.emoji,
                                vendor.name,
                                vendor.distance,
                                useImage: true,
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ],
                ),

                // Floating LIVE Badge
                Positioned(
                  top: 12,
                  left: 16,
                  child: _buildLiveBadge(),
                ),

                // Floating Zoom & Re-Center Controls (Right Side)
                Positioned(
                  right: 12,
                  bottom: 16,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Re-center button
                      _buildMapControlButton(
                        icon: Icons.my_location,
                        tooltip: 'Center on Home',
                        onTap: () {
                          _mapController.move(widget.userLocation, 15.8);
                        },
                      ),
                      const SizedBox(height: 6),

                      // Zoom In (+)
                      _buildMapControlButton(
                        icon: Icons.add,
                        tooltip: 'Zoom In',
                        onTap: () {
                          final currentZoom = _mapController.camera.zoom;
                          _mapController.move(_mapController.camera.center, (currentZoom + 0.8).clamp(10.0, 18.5));
                        },
                      ),
                      const SizedBox(height: 6),

                      // Zoom Out (-)
                      _buildMapControlButton(
                        icon: Icons.remove,
                        tooltip: 'Zoom Out',
                        onTap: () {
                          final currentZoom = _mapController.camera.zoom;
                          _mapController.move(_mapController.camera.center, (currentZoom - 0.8).clamp(10.0, 18.5));
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Floating Map Control Button (Zoom / Re-center) ──
  Widget _buildMapControlButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
      ),
    );
  }

  // ── LIVE Badge ──
  Widget _buildLiveBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 6,
            height: 6,
            child: Stack(
              children: [
                _PingDot(),
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'SCANNING AREA...',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 8,
              fontWeight: FontWeight.w800,
              color: AppColors.onSurface,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  // ── Filters Chip ──
  Widget _buildFiltersChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.filter_list, size: 18, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            'Filters',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  // ── Vendor Marker (glass-panel style matching Stitch) ──
  Widget _buildVendorMarker(
    String emoji,
    String name,
    String distance, {
    Color bgColor = const Color(0xFFDBEAFE),
    bool useImage = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(emoji, style: const TextStyle(fontSize: 10)),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                    ),
                    Text(
                      distance,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Transform.scale(
          scale: 0.75,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.surfaceContainer),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 6,
                ),
              ],
            ),
            child: useImage
                ? ClipOval(
                    child: Image.asset(
                      'assets/images/vendor_van_blue.png',
                      width: 32,
                      height: 32,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.local_shipping,
                        size: 20,
                        color: AppColors.primary,
                      ),
                    ),
                  )
                : const Icon(
                    Icons.local_shipping,
                    size: 20,
                    color: AppColors.primary,
                  ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Animated Home Marker — replicates the CSS pulse-ring animation
// ═══════════════════════════════════════════════════════════════

class _AnimatedHomeMarker extends StatefulWidget {
  const _AnimatedHomeMarker();

  @override
  State<_AnimatedHomeMarker> createState() => _AnimatedHomeMarkerState();
}

class _AnimatedHomeMarkerState extends State<_AnimatedHomeMarker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    _scaleAnimation = Tween<double>(begin: 0.8, end: 2.5).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );
    _opacityAnimation = Tween<double>(begin: 0.5, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          margin: const EdgeInsets.only(bottom: 4),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            'My Home',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),

        SizedBox(
          width: 56,
          height: 56,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Opacity(
                      opacity: _opacityAnimation.value,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary.withValues(alpha: 0.2),
                        ),
                      ),
                    ),
                  );
                },
              ),

              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.home,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
            ],
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
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Animated ping dot for the LIVE badge
// ═══════════════════════════════════════════════════════════════

class _PingDot extends StatefulWidget {
  @override
  State<_PingDot> createState() => _PingDotState();
}

class _PingDotState extends State<_PingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + (_controller.value * 2.0),
          child: Opacity(
            opacity: (1.0 - _controller.value) * 0.75,
            child: Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: AppColors.primaryContainer,
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      },
    );
  }
}
