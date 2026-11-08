import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/network/api_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/standard_top_bar.dart';
import '../../../home/presentation/bloc/home_bloc.dart';
import '../../../home/presentation/bloc/home_event.dart';
import '../../../home/presentation/bloc/home_state.dart';
import 'booking_success_page.dart';

import '../../domain/models/product.dart';

class BookingPage extends StatefulWidget {
  final VendorInfo vendorInfo;
  final List<Product> bookedProducts;
  final Map<String, int> cartQuantity;

  const BookingPage({
    super.key,
    required this.vendorInfo,
    this.bookedProducts = const [],
    this.cartQuantity = const {},
  });

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  bool notifyOnReach = true;
  bool ringOnReach = true;
  bool dailyTracking = true;

  List<Product>? _items;
  Map<String, int>? _quantities;

  List<Product> get items => _items ??= List.from(widget.bookedProducts);
  Map<String, int> get quantities => _quantities ??= Map.from(widget.cartQuantity);

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.bookedProducts);
    _quantities = Map.from(widget.cartQuantity);
  }

  double get _subtotal {
    return items.fold(
      0.0,
      (sum, item) {
        final qty = quantities[item.id] ?? 1;
        return sum + (item.price * qty);
      },
    );
  }

  void _incrementQty(Product item) {
    setState(() {
      final current = quantities[item.id] ?? 1;
      quantities[item.id] = current + 1;
    });
  }

  void _checkEmptyAndShowPopup() {
    if (items.isEmpty && mounted) {
      _showEmptyCartPopup(context);
    }
  }

  void _decrementQty(Product item) {
    setState(() {
      final current = quantities[item.id] ?? 1;
      if (current > 1) {
        quantities[item.id] = current - 1;
      } else {
        quantities.remove(item.id);
        items.removeWhere((p) => p.id == item.id);
      }
    });
    _checkEmptyAndShowPopup();
  }

  void _removeItem(Product item) {
    setState(() {
      quantities.remove(item.id);
      items.removeWhere((p) => p.id == item.id);
    });
    _checkEmptyAndShowPopup();
  }

  void _showEmptyCartPopup(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFEE2E2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.shopping_cart_outlined,
                    color: Color(0xFFEF4444),
                    size: 28,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'No Items in Booking',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'You have removed all items from your booking request. Please return to the seller menu to select items before proceeding.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: AppColors.onSurfaceVariant,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: Text(
                      'Back to Seller Menu',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              const StandardTopBar(
                title: 'Confirm Booking',
                subtitle: 'Review items & notification preferences',
                icon: Icons.shopping_bag_outlined,
                showBackButton: true,
              ),
              _buildSellerHeader(),
              _buildBookedItemsSection(),
              _buildPreferencesSection(),
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
          _buildBottomConfirmBar(),
        ],
      ),
    );
  }

  Widget _buildSellerHeader() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.surfaceContainerLow),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: AppColors.primaryContainer,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  widget.vendorInfo.imagePath,
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
                    widget.vendorInfo.name,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'ETA: ${widget.vendorInfo.eta} • ${widget.vendorInfo.distance}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: AppColors.outline,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'ACTIVE SELLER',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookedItemsSection() {
    final totalItemsCount = items.fold<int>(
      0,
      (sum, item) => sum + (quantities[item.id] ?? 1),
    );

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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Booking Items',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.onSurface,
                  ),
                ),
                Text(
                  items.isEmpty ? '0 Items Selected' : '$totalItemsCount Items Selected',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(color: AppColors.surfaceContainerHigh, height: 1),
            const SizedBox(height: 12),
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.remove_shopping_cart_outlined, size: 36, color: AppColors.outlineVariant),
                      const SizedBox(height: 8),
                      Text(
                        'No Items Added Yet',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tap + on items from the seller menu to add them to your booking',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: AppColors.outline,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = items[index];
                  final qty = quantities[item.id] ?? 1;
                  return Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: AppColors.surfaceContainerHigh,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.asset(
                            item.imagePath,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => const Icon(Icons.shopping_basket, size: 20, color: AppColors.outline),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.onSurface,
                              ),
                            ),
                            Text(
                              'Unit: ${item.unit}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: AppColors.outline,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.all(4),
                            icon: const Icon(Icons.remove_circle_outline, color: AppColors.primary, size: 20),
                            onPressed: () => _decrementQty(item),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              '$qty',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.onSurface,
                              ),
                            ),
                          ),
                          IconButton(
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.all(4),
                            icon: const Icon(Icons.add_circle, color: AppColors.primary, size: 20),
                            onPressed: () => _incrementQty(item),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.all(4),
                            icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                            onPressed: () => _removeItem(item),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
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
              'Default features enabled for your booking alert',
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

  Widget _buildBottomConfirmBar() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [
            BoxShadow(
              color: AppColors.onSurface.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, -4),
            )
          ],
        ),
        child: ElevatedButton(
          onPressed: () => _showConfirmationModal(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 0,
          ),
          child: Text(
            items.isEmpty ? 'Request Stop & Book Visit' : 'Confirm Booking',
            style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  void _showConfirmationModal(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.info_outline,
                    color: Color(0xFFD97706),
                    size: 28,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Stock Availability Notice',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'This booking is intended to inform the seller of your requested items. Please note that item stocks may run out before the seller reaches your location. We share this notice to keep you fully informed.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: AppColors.onSurfaceVariant,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w600,
                            color: AppColors.outline,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(dialogContext);

                          final nav = Navigator.of(context);
                          final messenger = ScaffoldMessenger.of(context);
                          final homeBloc = context.read<HomeBloc>();

                          // Build booking items payload
                          List<Map<String, dynamic>> bookingItems = items.map((item) {
                            final qty = (quantities[item.id] ?? 1).toDouble();
                            return {
                              'productId': item.id,
                              'productName': item.name,
                              'quantity': qty,
                              'unitPrice': item.price,
                              'totalPrice': item.price * qty,
                            };
                          }).toList();

                          if (bookingItems.isEmpty) {
                            bookingItems = [
                              {
                                'productName': 'Visit & Service Request (${widget.vendorInfo.category})',
                                'quantity': 1.0,
                                'unitPrice': 0.0,
                                'totalPrice': 0.0,
                              }
                            ];
                          }

                          final targetVendorId = widget.vendorInfo.id.isNotEmpty
                              ? widget.vendorInfo.id
                              : widget.vendorInfo.name;

                          final response = await BuyerApiService().createBooking(
                            vendorId: targetVendorId,
                            items: bookingItems,
                            totalAmount: _subtotal,
                            notifyOnReach: notifyOnReach,
                            ringOnReach: ringOnReach,
                            dailyTracking: dailyTracking,
                          );

                          if (!mounted) return;

                          if (response['success'] == true) {
                            final bData = response['data'] ?? {};
                            final bId = bData['id']?.toString() ??
                                bData['bookingNumber']?.toString() ??
                                'BK-${DateTime.now().millisecondsSinceEpoch}';
                            final orderInfo = ActiveOrderInfo(
                              bookingId: bId,
                              vendorId: widget.vendorInfo.id.isNotEmpty
                                  ? widget.vendorInfo.id
                                  : targetVendorId,
                              vendorName: widget.vendorInfo.name,
                              category: widget.vendorInfo.category,
                              emoji: widget.vendorInfo.emoji,
                              eta: widget.vendorInfo.eta,
                              distance: widget.vendorInfo.distance,
                              progress: 0.75,
                              vendorLat: widget.vendorInfo.latitude,
                              vendorLng: widget.vendorInfo.longitude,
                              buyerLat: 10.698731,
                              buyerLng: 76.091942,
                            );

                            homeBloc.add(HomeBookingCreated(orderInfo));

                            nav.pushReplacement(
                              MaterialPageRoute(
                                builder: (_) => BookingSuccessPage(
                                  vendorInfo: widget.vendorInfo,
                                ),
                              ),
                            );
                          } else {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  response['error'] ?? response['message'] ?? 'Failed to place booking. Please try again.',
                                ),
                                backgroundColor: const Color(0xFFDC2626),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: Text(
                          'Confirm',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
