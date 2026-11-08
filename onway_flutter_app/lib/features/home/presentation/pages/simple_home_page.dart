import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../vendor_details/presentation/pages/scan_vendor_page.dart';
import '../bloc/home_bloc.dart';
import '../bloc/home_event.dart';
import '../bloc/home_state.dart';
import '../widgets/active_order_card.dart';
import '../widgets/home_app_bar.dart';
import '../widgets/near_you_now_carousel.dart';
import 'category_vendors_page.dart';

/// Simple Home Page — Designed for everyday, non-tech background buyers.
/// Clean, card-based, high-contrast, with minimal technical jargon and large tap targets.
class SimpleHomePage extends StatefulWidget {
  final HomeState state;

  const SimpleHomePage({super.key, required this.state});

  @override
  State<SimpleHomePage> createState() => _SimpleHomePageState();
}

class _SimpleHomePageState extends State<SimpleHomePage> {
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.state.searchQuery);
  }

  @override
  void didUpdateWidget(covariant SimpleHomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.searchQuery != widget.state.searchQuery &&
        _searchController.text != widget.state.searchQuery) {
      _searchController.text = widget.state.searchQuery;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final nearVendors = state.nearYouNowVendors;

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF7),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          context.read<HomeBloc>().add(const HomeLoadRequested());
        },
        child: CustomScrollView(
          slivers: [
            // 1. Home App Bar (Same as Explorer / Advanced Map Screen)
            const HomeAppBar(),

            // 2. Search & Voice Input Bar
            SliverToBoxAdapter(
              child: _buildSearchBar(context),
            ),

              // 3. Booked Vendors (Vertically stacked in new rows)
              if (state.activeOrders.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final order = state.activeOrders[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: ActiveOrderCard(order: order),
                        );
                      },
                      childCount: state.activeOrders.length,
                    ),
                  ),
                ),

              // 4. Sellers Near You Now (< 500m) Animated Auto-Sliding Carousel Stack
              if (nearVendors.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 6),
                    child: NearYouNowCarousel(
                      vendors: nearVendors,
                      selectedAddress: state.selectedAddressTitle,
                    ),
                  ),
                ),

              // 5. Visual Daily Essentials Categories
              SliverToBoxAdapter(
                child: _buildVisualCategoryGrid(context, state),
              ),

              // 6. Your Regular Sellers Status
              SliverToBoxAdapter(
                child: _buildTodaySchedule(context),
              ),

              // 7. Senior / Beginner Assistance Banner
              SliverToBoxAdapter(
                child: _buildHelpBanner(context),
              ),

              // Bottom padding for floating navigation bar
              const SliverToBoxAdapter(
                child: SizedBox(height: 110),
              ),
            ],
          ),
        ),
      );
    }

  /// 2. Search & Voice Input Bar
  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.search_rounded, color: AppColors.primary, size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: (q) => context.read<HomeBloc>().add(HomeSearchQueryChanged(q)),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
                decoration: InputDecoration(
                  hintText: 'Search fish, veggies, fruits, bakery...',
                  hintStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: AppColors.outlineVariant,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                ),
              ),
            ),
            if (_searchController.text.isNotEmpty)
              GestureDetector(
                onTap: () {
                  _searchController.clear();
                  context.read<HomeBloc>().add(const HomeSearchQueryChanged(''));
                },
                child: const Icon(Icons.cancel, size: 20, color: AppColors.outline),
              )
            else
              // QR Code scanner button for quick vendor scan
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ScanVendorPage(showBackButton: true),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.qr_code_scanner_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 3. Visual Category Grid (Big Touch Targets)
  Widget _buildVisualCategoryGrid(BuildContext context, HomeState state) {
    final categories = [
      {'name': 'Fish', 'local': 'പച്ചമീൻ', 'emoji': '🐟', 'color': const Color(0xFFE0F2FE)},
      {'name': 'Vegetables', 'local': 'പച്ചക്കറി', 'emoji': '🥬', 'color': const Color(0xFFDCFCE7)},
      {'name': 'Fruits', 'local': 'പഴങ്ങൾ', 'emoji': '🍎', 'color': const Color(0xFFFFE4E6)},
      {'name': 'Bakery', 'local': 'ബേക്കറി', 'emoji': '🍞', 'color': const Color(0xFFFEF3C7)},
      {'name': 'Dairy', 'local': 'പാൽ & തൈര്', 'emoji': '🥛', 'color': const Color(0xFFEDE9FE)},
      {'name': 'All', 'local': 'എല്ലാം കാണുക', 'emoji': '🛍️', 'color': const Color(0xFFF1F5F9)},
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'What do you need today?',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.onSurface,
                ),
              ),
              Text(
                'Tap to explore sellers',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: categories.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.95,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemBuilder: (context, index) {
              final cat = categories[index];
              final catName = cat['name'] as String;

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CategoryVendorsPage(
                        category: catName,
                        categoryEmoji: cat['emoji'] as String,
                        categoryColor: cat['color'] as Color,
                      ),
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: cat['color'] as Color,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.transparent),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        cat['emoji'] as String,
                        style: const TextStyle(fontSize: 32),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        catName,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.onSurface,
                        ),
                      ),
                      Text(
                        cat['local'] as String,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: AppColors.outline,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// 5. Today's Vendor Schedule (Morning / Noon / Evening)
  Widget _buildTodaySchedule(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.verified_user_outlined, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  "Your Regular Sellers Status",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.onSurface,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Daily Tracked Route',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.outline,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _buildScheduleItem(
              time: '8:00 AM – 10:00 AM',
              title: 'Perumbilavu Malabar Dairy & Bakery',
              status: 'Completed Run',
              statusColor: Colors.grey,
              icon: Icons.check_circle_outline,
            ),
            const Divider(height: 18),
            _buildScheduleItem(
              time: '11:00 AM – 1:30 PM',
              title: 'Coastal Fresh Fish Van (Murali)',
              status: 'On The Road Now (< 500m)',
              statusColor: const Color(0xFF198754),
              icon: Icons.directions_boat_outlined,
            ),
            const Divider(height: 18),
            _buildScheduleItem(
              time: '4:30 PM – 7:00 PM',
              title: 'Perumbilavu Organic Veggies & Fruits',
              status: 'Upcoming Evening Run',
              statusColor: const Color(0xFF0284C7),
              icon: Icons.access_time_rounded,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleItem({
    required String time,
    required String title,
    required String status,
    required Color statusColor,
    required IconData icon,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: statusColor),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
              ),
              Text(
                time,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: AppColors.outline,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            status,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
          ),
        ),
      ],
    );
  }



  /// 8. Senior & Beginner Help Card
  Widget _buildHelpBanner(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.support_agent_rounded, color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Need Help Ordering?',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.onSurface,
                    ),
                  ),
                  Text(
                    'Call our customer support or order directly on WhatsApp.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: AppColors.outline,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
