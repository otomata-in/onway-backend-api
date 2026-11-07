import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../bloc/home_state.dart';
import '../widgets/home_app_bar.dart';
import '../widgets/vendor_card.dart';

class SavedVendorsPage extends StatelessWidget {
  final List<VendorInfo> savedVendors;

  const SavedVendorsPage({super.key, required this.savedVendors});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // Same Home Page Top Bar Template
        const HomeAppBar(),
        _buildHeaderSection(context),
        if (savedVendors.isEmpty)
          _buildEmptyState()
        else
          _buildVendorsList(),
        const SliverToBoxAdapter(child: SizedBox(height: 120)),
      ],
    );
  }

  Widget _buildHeaderSection(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Saved Sellers',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your bookmarked favorite local vendors',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: AppColors.outline,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                children: [
                  const Icon(Icons.bookmark, size: 14, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text(
                    '${savedVendors.length}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
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

  Widget _buildEmptyState() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
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
                  Icons.bookmark_border_rounded,
                  size: 36,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'No Saved Sellers Yet',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tap the bookmark icon on any seller page or card to save your favorite vendors for quick access here.',
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

  Widget _buildVendorsList() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final vendor = savedVendors[index];
            return Padding(
              key: ValueKey(vendor.name),
              padding: const EdgeInsets.only(bottom: 16),
              child: VendorCard(vendor: vendor),
            );
          },
          childCount: savedVendors.length,
        ),
      ),
    );
  }
}
