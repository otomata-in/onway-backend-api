import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../bloc/home_bloc.dart';
import '../bloc/home_state.dart';
import '../../../vendor_details/presentation/pages/retail_vendor_page.dart';

enum VendorSortOption {
  distance,
  rating,
  regular,
}

class CategoryVendorsPage extends StatefulWidget {
  final String category;
  final String categoryEmoji;
  final Color categoryColor;

  const CategoryVendorsPage({
    super.key,
    required this.category,
    this.categoryEmoji = '🛍️',
    this.categoryColor = const Color(0xFFF1F5F9),
  });

  @override
  State<CategoryVendorsPage> createState() => _CategoryVendorsPageState();
}

class _CategoryVendorsPageState extends State<CategoryVendorsPage> {
  final TextEditingController _searchController = TextEditingController();
  VendorSortOption _selectedSort = VendorSortOption.distance;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<VendorInfo> _filterAndSortVendors(List<VendorInfo> allVendors) {
    // 1. Filter by category (if not 'All')
    List<VendorInfo> list = allVendors.where((v) {
      if (widget.category.toLowerCase() == 'all') return true;
      final cat = widget.category.toLowerCase();
      final vCat = v.category.toLowerCase();
      final vName = v.name.toLowerCase();
      final vSubtitle = v.subtitle.toLowerCase();
      return vCat.contains(cat) || vName.contains(cat) || vSubtitle.contains(cat);
    }).toList();

    // 2. Search query filter (by vendor name, vehicle number, or vendor ID)
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      list = list.where((v) {
        final matchesName = v.name.toLowerCase().contains(q);
        final matchesId = v.id.toLowerCase().contains(q);
        final matchesSubtitle = v.subtitle.toLowerCase().contains(q);
        final matchesCategory = v.category.toLowerCase().contains(q);
        return matchesName || matchesId || matchesSubtitle || matchesCategory;
      }).toList();
    }

    // 3. Sorting
    switch (_selectedSort) {
      case VendorSortOption.distance:
        list.sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));
        break;
      case VendorSortOption.rating:
        list.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case VendorSortOption.regular:
        list.sort((a, b) {
          // Favorite / regular sellers first, then distance
          if (a.isFavorite && !b.isFavorite) return -1;
          if (!a.isFavorite && b.isFavorite) return 1;
          return a.distanceMeters.compareTo(b.distanceMeters);
        });
        break;
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: widget.categoryColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                widget.categoryEmoji,
                style: const TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${widget.category} Sellers',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.onSurface,
                    ),
                  ),
                  Text(
                    'Nearby roving vans & street carts',
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
      body: BlocBuilder<HomeBloc, HomeState>(
        builder: (context, state) {
          final displayedVendors = _filterAndSortVendors(state.vendors);

          return Column(
            children: [
              // 1. Search Box
              _buildSearchBox(),

              // 2. Sort Bar Pills
              _buildSortBar(displayedVendors.length),

              // 3. Vendors List / Empty State
              Expanded(
                child: displayedVendors.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: displayedVendors.length,
                        itemBuilder: (context, index) {
                          final vendor = displayedVendors[index];
                          return _buildVendorCard(context, vendor);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchBox() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            const Icon(Icons.search, size: 20, color: AppColors.outline),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: (val) {
                  setState(() => _searchQuery = val);
                },
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
                decoration: InputDecoration(
                  hintText: 'Search by vendor name, vehicle or ID...',
                  hintStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
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
                  setState(() => _searchQuery = '');
                },
                child: const Icon(Icons.cancel, size: 18, color: AppColors.outline),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortBar(int count) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '$count available sellers',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.outline,
                ),
              ),
              const Spacer(),
              const Icon(Icons.sort, size: 15, color: AppColors.primary),
              const SizedBox(width: 4),
              Text(
                'Sort by:',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildSortPill(
                  title: 'Distance (Nearest)',
                  icon: Icons.near_me_outlined,
                  option: VendorSortOption.distance,
                ),
                const SizedBox(width: 8),
                _buildSortPill(
                  title: 'Rating (Top Rated)',
                  icon: Icons.star_outline_rounded,
                  option: VendorSortOption.rating,
                ),
                const SizedBox(width: 8),
                _buildSortPill(
                  title: 'Regular Seller',
                  icon: Icons.favorite_border_rounded,
                  option: VendorSortOption.regular,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortPill({
    required String title,
    required IconData icon,
    required VendorSortOption option,
  }) {
    final isSelected = _selectedSort == option;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedSort = option);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : const Color(0xFFF8FAF8),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.white : AppColors.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVendorCard(BuildContext context, VendorInfo vendor) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RetailVendorPage(vendorInfo: vendor),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
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
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar / Emoji
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      vendor.emoji,
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              vendor.name,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.onSurface,
                              ),
                            ),
                          ),
                          if (vendor.isLive)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'LIVE',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF15803D),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        vendor.subtitle,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: AppColors.outline,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star, size: 14, color: Color(0xFFF59E0B)),
                          const SizedBox(width: 3),
                          Text(
                            vendor.rating.toStringAsFixed(1),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.onSurface,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Icon(Icons.near_me, size: 13, color: AppColors.primary),
                          const SizedBox(width: 3),
                          Text(
                            '${vendor.distance} (${vendor.eta})',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                          if (vendor.isFavorite) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEE2E2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'REGULAR',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFFDC2626),
                                ),
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
            Row(
              children: [
                // Quick Call Button
                Expanded(
                  flex: 2,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Calling driver for ${vendor.name}...'),
                          backgroundColor: AppColors.primary,
                        ),
                      );
                    },
                    icon: const Icon(Icons.phone, size: 15),
                    label: Text(
                      'Call',
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 12.5),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // View Store & Book Button
                Expanded(
                  flex: 3,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RetailVendorPage(vendorInfo: vendor),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(
                      'View Store & Book',
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 12.5),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.storefront_outlined, size: 48, color: AppColors.outline),
            const SizedBox(height: 12),
            Text(
              'No Sellers Found',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No ${widget.category} sellers match "$_searchQuery". Try another search or filter.'
                  : 'No active roving sellers broadcasting in ${widget.category} category right now.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: AppColors.outline,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

