import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/network/api_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/home_bloc.dart';
import '../bloc/home_event.dart';
import '../bloc/home_state.dart';

/// An auto-sliding, animated horizontal carousel displaying roving vendors
/// within 500 meters of the buyer's location.
class NearYouNowCarousel extends StatefulWidget {
  final List<VendorInfo> vendors;
  final String selectedAddress;

  const NearYouNowCarousel({
    super.key,
    required this.vendors,
    required this.selectedAddress,
  });

  @override
  State<NearYouNowCarousel> createState() => _NearYouNowCarouselState();
}

class _NearYouNowCarouselState extends State<NearYouNowCarousel> {
  late PageController _pageController;
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.93);
    _startAutoSlide();
  }

  void _startAutoSlide() {
    _timer?.cancel();
    if (widget.vendors.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
        if (!_pageController.hasClients) return;
        final nextPage = (_currentPage + 1) % widget.vendors.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutCubic,
        );
      });
    }
  }

  @override
  void didUpdateWidget(covariant NearYouNowCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.vendors.length != widget.vendors.length) {
      _startAutoSlide();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.vendors.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        // Horizontal Animated Sliding Stack
        SizedBox(
          height: 195,
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.vendors.length,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              final vendor = widget.vendors[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
                child: _buildVendorCard(context, vendor),
              );
            },
          ),
        ),

        // Animated Page Dot Indicators
        if (widget.vendors.length > 1) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.vendors.length, (index) {
              final isActive = index == _currentPage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: isActive ? 20 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: isActive ? AppColors.primary : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(999),
                ),
              );
            }),
          ),
          const SizedBox(height: 4),
        ],
      ],
    );
  }

  Widget _buildVendorCard(BuildContext context, VendorInfo vendor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F5132), Color(0xFF198754)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF198754).withValues(alpha: 0.28),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top Row: Live Pulse Badge + Distance Pill
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFF75F8A1),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'NEAR YOU NOW (< 500m)',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${vendor.distance} away · ${vendor.eta}',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          // Center Info: Emoji + Vendor Name & Category
          Row(
            children: [
              Text(
                vendor.emoji,
                style: const TextStyle(fontSize: 32),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vendor.name,
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      vendor.subtitle,
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 12.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Bottom Buttons: Request Stop + View Store
          Row(
            children: [
              Expanded(
                flex: 3,
                child: ElevatedButton.icon(
                  onPressed: () => _showRequestStopDialog(context, vendor),
                  icon: const Icon(Icons.front_hand_rounded, size: 16),
                  label: Text(
                    'Request Stop Here',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.bold,
                      fontSize: 12.5,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF0F5132),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: OutlinedButton(
                  onPressed: () {
                    context.push('/retail-vendor', extra: vendor);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(
                    'View Store',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.bold,
                      fontSize: 12.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showRequestStopDialog(BuildContext context, VendorInfo vendor) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '✋ Request Stop at Your Gate',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Alert ${vendor.name} (${vendor.distance} away) to halt near ${widget.selectedAddress.isNotEmpty ? widget.selectedAddress : "Perumbilavu Junction"}?',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: AppColors.outline,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        final targetVendorId = vendor.id.isNotEmpty ? vendor.id : vendor.name;
                        final res = await BuyerApiService().createBooking(
                          vendorId: targetVendorId,
                          items: [
                            {
                              'productName': 'Stop & Halt Request (${vendor.category})',
                              'quantity': 1.0,
                              'unitPrice': 0.0,
                              'totalPrice': 0.0,
                            }
                          ],
                          totalAmount: 0.0,
                          notifyOnReach: true,
                          ringOnReach: true,
                          notes: 'Halt requested from Near You Now carousel',
                        );

                        if (context.mounted) {
                          if (res['success'] == true) {
                            final bData = res['data'] ?? {};
                            final bId = bData['id']?.toString() ??
                                bData['bookingNumber']?.toString() ??
                                'BK-${DateTime.now().millisecondsSinceEpoch}';
                            final orderInfo = ActiveOrderInfo(
                              bookingId: bId,
                              vendorId: vendor.id.isNotEmpty ? vendor.id : targetVendorId,
                              vendorName: vendor.name,
                              category: vendor.category,
                              emoji: vendor.emoji,
                              eta: vendor.eta,
                              distance: vendor.distance,
                              progress: 0.75,
                              vendorLat: vendor.latitude,
                              vendorLng: vendor.longitude,
                              buyerLat: 10.698731,
                              buyerLng: 76.091942,
                            );

                            context.read<HomeBloc>().add(HomeBookingCreated(orderInfo));
                            context.read<HomeBloc>().add(const HomeLoadRequested());
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Stop requested! ${vendor.name} has been notified to halt.'),
                                backgroundColor: const Color(0xFF198754),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(res['error'] ?? res['message'] ?? 'Failed to request stop.'),
                                backgroundColor: const Color(0xFFDC2626),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF198754),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Confirm Stop'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

