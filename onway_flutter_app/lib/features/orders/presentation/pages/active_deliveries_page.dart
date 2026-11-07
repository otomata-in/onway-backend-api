import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/network/api_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/standard_top_bar.dart';
import '../widgets/delivery_tracking_card.dart';

class ActiveDeliveriesPage extends StatefulWidget {
  const ActiveDeliveriesPage({super.key});

  @override
  State<ActiveDeliveriesPage> createState() => _ActiveDeliveriesPageState();
}

class _ActiveDeliveriesPageState extends State<ActiveDeliveriesPage> {
  final _api = BuyerApiService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _dailyTrackings = [];

  @override
  void initState() {
    super.initState();
    _loadDailyTrackings();
  }

  Future<void> _loadDailyTrackings() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.getDailyTrackings();
      if (res['success'] == true && res['data'] != null) {
        final list = res['data'] as List;
        if (list.isNotEmpty) {
          setState(() {
            _dailyTrackings = list.map<Map<String, dynamic>>((item) {
              final vendor = item['vendor'] ?? {};
              return {
                'id': vendor['id'] ?? item['vendorId'] ?? '',
                'vendorName': vendor['businessName'] ?? 'Mattom Organic Veggies',
                'category': vendor['category'] ?? 'Organic Vegetables',
                'imageUrl': 'assets/images/vendor_green_valley.png',
                'eta': 'Arriving in 3 mins',
                'progress': 0.75,
                'progressIcon': Icons.local_shipping,
                'distance': '0.2 km away',
                'rating': (vendor['rating'] as num?)?.toDouble() ?? 4.8,
                'isLive': vendor['isLiveBroadcasting'] ?? true,
                'notifyOnReach': item['notifyOnReach'] ?? true,
                'ringOnReach': item['ringOnReach'] ?? true,
              };
            }).toList();
          });
        }
      }

      if (_dailyTrackings.isEmpty) {
        final nearbyRes = await _api.getNearbyVendors(lat: 10.59337, lng: 76.080334);
        if (nearbyRes['success'] == true && nearbyRes['data'] != null) {
          final nearbyList = nearbyRes['data'] as List;
          setState(() {
            _dailyTrackings = nearbyList.take(3).map<Map<String, dynamic>>((v) {
              final distKm = v['distance'] != null ? ((v['distance'] as num).toDouble() / 1000).toStringAsFixed(1) : '0.2';
              return {
                'id': v['id'] ?? '',
                'vendorName': v['businessName'] ?? 'Mattom Organic Veggies',
                'category': v['category'] ?? 'Organic Vegetables',
                'imageUrl': 'assets/images/vendor_green_valley.png',
                'eta': 'Arriving in 3 mins',
                'progress': 0.75,
                'progressIcon': Icons.local_shipping,
                'distance': '$distKm km away',
                'rating': (v['rating'] as num?)?.toDouble() ?? 4.8,
                'isLive': v['isLiveBroadcasting'] ?? true,
                'notifyOnReach': true,
                'ringOnReach': true,
              };
            }).toList();
          });
        }
      }
    } catch (_) {}
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _confirmRemoveDailyTracking(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.calendar_today_outlined,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Disable Daily Tracking?',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.onSurface,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to disable daily tracking for "${item['vendorName']}"? You will no longer receive daily route alerts when this seller reaches nearby.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: AppColors.outline,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final vendorId = item['id'];
              if (vendorId.isNotEmpty) {
                await _api.removeTracking(vendorId);
              }
              setState(() {
                _dailyTrackings.removeWhere((v) => v['id'] == vendorId);
              });
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Daily tracking for ${item['vendorName']} removed',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    backgroundColor: AppColors.primary,
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 2),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: Text(
              'Confirm Remove',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: CustomScrollView(
        slivers: [
          const StandardTopBar(
            title: 'Daily Trackings',
            subtitle: 'Manage your active seller route tracking alerts',
            icon: Icons.calendar_today_outlined,
          ),
          if (_isLoading)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 60),
                child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
              ),
            )
          else if (_dailyTrackings.isEmpty)
            _buildEmptyState()
          else
            SliverPadding(
              padding: const EdgeInsets.all(16.0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = _dailyTrackings[index];
                    return Padding(
                      key: ValueKey(item['id']),
                      padding: const EdgeInsets.only(bottom: 24),
                      child: DeliveryTrackingCard(
                        vendorName: item['vendorName'],
                        category: item['category'],
                        imageUrl: item['imageUrl'],
                        eta: item['eta'],
                        progress: item['progress'],
                        progressIcon: item['progressIcon'],
                        distance: item['distance'],
                        rating: item['rating'],
                        isLive: item['isLive'],
                        initialDailyTracking: true,
                        onUnselectDailyTracking: () =>
                            _confirmRemoveDailyTracking(item),
                      ),
                    );
                  },
                  childCount: _dailyTrackings.length,
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
        child: Center(
          child: Column(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.calendar_today_outlined,
                  size: 36,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'No Active Daily Trackings',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enable daily tracking on any seller card to receive automated arrival notifications.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: AppColors.outline,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
