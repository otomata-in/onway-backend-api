import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/network/api_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../home/presentation/bloc/home_bloc.dart';
import '../../../home/presentation/bloc/home_event.dart';
import '../../../home/presentation/bloc/home_state.dart';
import '../../../home/presentation/widgets/home_app_bar.dart';
import '../../../vendor_details/presentation/pages/live_tracking_page.dart';
import '../../../vendor_details/presentation/pages/retail_vendor_page.dart';

class BookingsPage extends StatefulWidget {
  const BookingsPage({super.key});

  @override
  State<BookingsPage> createState() => _BookingsPageState();
}

class _BookingsPageState extends State<BookingsPage> {
  final _api = BuyerApiService();
  int _selectedCategoryIndex = 0; // 0: Active Bookings, 1: Booking History
  bool _isLoading = true;

  List<Map<String, dynamic>> _activeBookings = [];
  List<Map<String, dynamic>> _historyBookings = [];

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    try {
      final activeRes = await _api.getActiveBookings();
      final historyRes = await _api.getBookingHistory();

      List<Map<String, dynamic>> active = [];
      if (activeRes['success'] == true && activeRes['data'] != null) {
        final list = activeRes['data'] as List;
        active = list.map<Map<String, dynamic>>((b) {
          final items = (b['items'] as List?) ?? [];
          final itemsText = items.map((i) => "${i['productName']} (${i['quantity']})").join(', ');
          return {
            'bookingId': b['id']?.toString() ?? b['bookingNumber']?.toString() ?? '',
            'id': b['bookingNumber'] ?? '#ONW-00000',
            'vendorName': b['vendor']?['businessName'] ?? 'Vendor',
            'category': b['vendor']?['category'] ?? 'General',
            'imagePath': b['vendor']?['vehicleImagePath'] ?? 'assets/images/vendor_green_valley.png',
            'eta': '${b['eta'] ?? 8} mins',
            'distance': '0.5 km',
            'status': b['status'] ?? 'EN ROUTE',
            'statusColor': const Color(0xFF16A34A),
            'total': (b['totalAmount'] as num?)?.toDouble() ?? 0.0,
            'itemsCount': items.length,
            'itemsText': itemsText.isNotEmpty ? itemsText : 'Items booked',
            'date': 'Today',
            'rating': (b['vendor']?['rating'] as num?)?.toDouble() ?? 4.8,
            'notifyOnReach': b['notifyOnReach'] ?? true,
            'ringOnReach': b['ringOnReach'] ?? true,
          };
        }).toList();
      }

      List<Map<String, dynamic>> history = [];
      if (historyRes['success'] == true && historyRes['data'] != null) {
        final list = historyRes['data'] as List;
        history = list.map<Map<String, dynamic>>((b) {
          final items = (b['items'] as List?) ?? [];
          final itemsText = items.map((i) => "${i['productName']} (${i['quantity']})").join(', ');
          final isCancelled = b['status'] == 'CANCELLED';
          return {
            'bookingId': b['id']?.toString() ?? b['bookingNumber']?.toString() ?? '',
            'id': b['bookingNumber'] ?? '#ONW-00000',
            'vendorName': b['vendor']?['businessName'] ?? 'Vendor',
            'category': b['vendor']?['category'] ?? 'General',
            'imagePath': b['vendor']?['vehicleImagePath'] ?? 'assets/images/stitch_saved_vendor_1.png',
            'status': b['status'] ?? 'COMPLETED',
            'statusColor': isCancelled ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
            'total': (b['totalAmount'] as num?)?.toDouble() ?? 0.0,
            'itemsCount': items.length,
            'itemsText': itemsText.isNotEmpty ? itemsText : 'Items booked',
            'date': 'Past Order',
            'rating': (b['vendor']?['rating'] as num?)?.toDouble() ?? 4.7,
            'eta': isCancelled ? 'Cancelled' : 'Delivered',
            'distance': '0.0 km',
          };
        }).toList();
      }

      if (mounted) {
        setState(() {
          _activeBookings = active.isNotEmpty ? active : _fallbackActiveBookings;
          _historyBookings = history.isNotEmpty ? history : _fallbackHistoryBookings;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _activeBookings = _fallbackActiveBookings;
          _historyBookings = _fallbackHistoryBookings;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : CustomScrollView(
              slivers: [
                const HomeAppBar(),
                _buildHeaderSection(),
                _buildCategorySegmentedPicker(),
                _buildBookingsList(),
                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            ),
    );
  }

  Widget _buildHeaderSection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'My Bookings',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Track your active seller bookings & view past order history',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: AppColors.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySegmentedPicker() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHigh.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildCategoryTab(
                index: 0,
                title: 'Current Active',
                count: _activeBookings.length,
              ),
            ),
            Expanded(
              child: _buildCategoryTab(
                index: 1,
                title: 'Booking History',
                count: _historyBookings.length,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryTab({
    required int index,
    required String title,
    required int count,
  }) {
    final isSelected = _selectedCategoryIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategoryIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? AppColors.primary : AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.onSurfaceVariant.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$count',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : AppColors.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingsList() {
    final list = _selectedCategoryIndex == 0 ? _activeBookings : _historyBookings;

    if (list.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Center(
            child: Column(
              children: [
                Icon(
                  _selectedCategoryIndex == 0 ? Icons.shopping_bag_outlined : Icons.history,
                  size: 48,
                  color: AppColors.outlineVariant,
                ),
                const SizedBox(height: 12),
                Text(
                  _selectedCategoryIndex == 0 ? 'No Active Bookings' : 'No Booking History',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _selectedCategoryIndex == 0
                      ? 'Book items from live sellers nearby to track them here.'
                      : 'Your completed booking requests will appear here.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AppColors.outline,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final item = list[index];
            return _buildBookingCard(item, _selectedCategoryIndex == 0);
          },
          childCount: list.length,
        ),
      ),
    );
  }

  Future<void> _confirmCancelBooking(Map<String, dynamic> item) async {
    final bId = item['bookingId']?.toString() ?? item['id']?.toString() ?? '';
    final vendorName = item['vendorName'] ?? 'Vendor';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            const Icon(Icons.cancel_outlined, color: Color(0xFFDC2626), size: 24),
            const SizedBox(width: 8),
            Text(
              'Cancel Booking?',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 17),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to cancel your booking with $vendorName?',
          style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Keep Booking',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: AppColors.outline),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      if (bId.isNotEmpty && !bId.startsWith('demo_')) {
        await _api.cancelBooking(bId);
      }
      if (mounted) {
        context.read<HomeBloc>().add(HomeBookingCancelRequested(bId));
        _loadBookings();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Booking with $vendorName cancelled.'),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  Widget _buildBookingCard(Map<String, dynamic> item, bool isActive) {
    final Color statusColor = item['statusColor'] as Color;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive
              ? AppColors.primary.withValues(alpha: 0.3)
              : AppColors.surfaceContainerLow,
          width: isActive ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isActive
                ? AppColors.primary.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.03),
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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item['id'],
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    item['date'],
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: AppColors.outline,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  children: [
                    if (isActive) ...[
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                    ],
                    Text(
                      item['status'],
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: AppColors.surfaceContainerHigh, height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: AppColors.surfaceContainerHigh,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    item['imagePath'],
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => const Icon(Icons.store, color: AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['vendorName'],
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          '${item['category']} • ⭐ ${item['rating']}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: AppColors.outline,
                          ),
                        ),
                        if (isActive) ...[
                          const SizedBox(width: 8),
                          Text(
                            '• ETA ${item['eta']}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAF8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.surfaceContainerHigh),
            ),
            child: Row(
              children: [
                const Icon(Icons.shopping_bag_outlined, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item['itemsText'],
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              if (isActive) ...[
                Expanded(
                  flex: 2,
                  child: OutlinedButton.icon(
                    onPressed: () => _confirmCancelBooking(item),
                    icon: const Icon(Icons.close_rounded, size: 14, color: Color(0xFFDC2626)),
                    label: Text(
                      'Cancel',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFDC2626),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFFCA5A5)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LiveTrackingPage(
                            orderInfo: ActiveOrderInfo(
                              bookingId: item['bookingId']?.toString() ?? '',
                              vendorName: item['vendorName'],
                              eta: item['eta'],
                              distance: item['distance'],
                              progress: 0.75,
                            ),
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.map_outlined, size: 15),
                    label: Text(
                      'Track Live Route',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RetailVendorPage(
                          vendorInfo: VendorInfo(
                            name: item['vendorName'],
                            subtitle: 'Organic Produce & Farm Fresh',
                            emoji: '🥦',
                            imagePath: item['imagePath'],
                            rating: item['rating'],
                            eta: item['eta'],
                            distance: item['distance'],
                            isLive: true,
                            category: item['category'],
                          ),
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.storefront_outlined, color: AppColors.primary),
                  tooltip: 'Vendor Info',
                ),
              ] else ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RetailVendorPage(
                            vendorInfo: VendorInfo(
                              name: item['vendorName'],
                              subtitle: 'Organic Produce & Farm Fresh',
                              emoji: '🥦',
                              imagePath: item['imagePath'],
                              rating: item['rating'],
                              eta: '10 mins',
                              distance: '1.0 km',
                              isLive: true,
                              category: item['category'],
                            ),
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.refresh, size: 16),
                    label: Text(
                      'Book Again',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // Fallbacks
  static final List<Map<String, dynamic>> _fallbackActiveBookings = [
    {
      'id': '#ONW-84920',
      'vendorName': 'Green Valley Organic Farm',
      'category': 'Produce',
      'imagePath': 'assets/images/vendor_green_valley.png',
      'eta': '8 mins',
      'distance': '0.5 km',
      'status': 'EN ROUTE',
      'statusColor': const Color(0xFF16A34A),
      'total': 14.46,
      'itemsCount': 3,
      'itemsText': 'Tomatoes (1kg), Carrots (500g), Spinach (2 bunches)',
      'date': 'Today, 10:45 AM',
      'rating': 4.8,
      'notifyOnReach': true,
      'ringOnReach': true,
    },
  ];

  static final List<Map<String, dynamic>> _fallbackHistoryBookings = [
    {
      'id': '#ONW-73912',
      'vendorName': 'Sunny Hills Dairy & Bakery',
      'category': 'Dairy & Bakery',
      'imagePath': 'assets/images/stitch_saved_vendor_1.png',
      'status': 'COMPLETED',
      'statusColor': const Color(0xFF16A34A),
      'total': 19.20,
      'itemsCount': 4,
      'itemsText': 'Organic Milk (2L), Sourdough Bread, Fresh Butter',
      'date': 'Yesterday, 4:30 PM',
      'rating': 4.7,
      'eta': 'Delivered',
      'distance': '0.0 km',
    },
  ];
}
