import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/theme/app_colors.dart';
import '../bloc/home_bloc.dart';
import '../bloc/home_event.dart';
import '../bloc/home_state.dart';
import '../widgets/active_order_card.dart';
import '../widgets/category_chips.dart';
import '../widgets/home_app_bar.dart';
import '../widgets/map_section.dart';
import '../widgets/vendor_card.dart';
import 'location_selection_page.dart';

/// Advanced Page - Displays the full interactive OpenStreetMap (OSM) map,
/// category filters, real-time vehicle routes, and nearby roving vendors list.
class AdvancedMapPage extends StatefulWidget {
  final HomeState state;

  const AdvancedMapPage({super.key, required this.state});

  @override
  State<AdvancedMapPage> createState() => _AdvancedMapPageState();
}

class _AdvancedMapPageState extends State<AdvancedMapPage> {
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.state.searchQuery);
  }

  @override
  void didUpdateWidget(covariant AdvancedMapPage oldWidget) {
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
    final filteredVendors = state.filteredVendors;

    return CustomScrollView(
      slivers: [
        const HomeAppBar(),
        if (state.activeOrders.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
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
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: AppColors.surfaceContainerHigh),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (q) => context.read<HomeBloc>().add(HomeSearchQueryChanged(q)),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search vendor by name, item or category...',
                        hintStyle: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color: AppColors.outlineVariant,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  if (_searchController.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear, color: AppColors.outline, size: 20),
                      onPressed: () {
                        _searchController.clear();
                        context.read<HomeBloc>().add(const HomeSearchQueryChanged(''));
                      },
                    ),
                  Container(width: 1, height: 28, color: AppColors.surfaceContainerHigh),
                  IconButton(
                    icon: Icon(
                      Icons.tune,
                      color: (state.selectedCategory != 'All' || state.searchQuery.isNotEmpty)
                          ? AppColors.primary
                          : AppColors.outline,
                    ),
                    onPressed: () {
                      context.read<HomeBloc>().add(const HomeCategoryChanged('All'));
                      _searchController.clear();
                      context.read<HomeBloc>().add(const HomeSearchQueryChanged(''));
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Categories',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
                if (state.selectedCategory != 'All')
                  GestureDetector(
                    onTap: () => context.read<HomeBloc>().add(const HomeCategoryChanged('All')),
                    child: Text(
                      'Clear Filter',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: CategoryChips(
            categories: state.categories,
            selected: state.selectedCategory,
            onSelected: (cat) => context.read<HomeBloc>().add(HomeCategoryChanged(cat)),
          ),
        ),
        SliverToBoxAdapter(
          child: MapSection(
            vendors: state.vendors,
            isLocationSelected: state.isLocationSelected,
            userLocation: LatLng(state.userLatitude, state.userLongitude),
            onSelectLocationTap: () async {
              final result = await Navigator.push<Map<String, dynamic>>(
                context,
                MaterialPageRoute(builder: (_) => const LocationSelectionPage()),
              );
              if (result != null && context.mounted) {
                final title = result['title'] ?? 'Selected Address';
                final subtitle = result['subtitle'] ?? result['addressLine'] ?? '';
                final lat = (result['lat'] as num?)?.toDouble() ?? 9.9790;
                final lng = (result['lng'] as num?)?.toDouble() ?? 76.2760;

                context.read<HomeBloc>().add(HomeLocationSelected(
                  latitude: lat,
                  longitude: lng,
                  title: title,
                  addressLine: subtitle,
                ));
              }
            },
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: state.selectedCategory == 'All' ? '' : '${state.selectedCategory} ',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                          TextSpan(
                            text: 'Vendors Nearby',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: AppColors.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${filteredVendors.length} found',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (filteredVendors.isEmpty)
          _buildEmptySearchResults()
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final vendor = filteredVendors[index];
                  return Padding(
                    key: ValueKey(vendor.name),
                    padding: const EdgeInsets.only(bottom: 16),
                    child: VendorCard(vendor: vendor, isPrimary: index == 0),
                  );
                },
                childCount: filteredVendors.length,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptySearchResults() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
        child: Center(
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: AppColors.surfaceContainerHigh,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.search_off_rounded,
                  size: 32,
                  color: AppColors.outline,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'No Vendors Found',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'No sellers match your search "${widget.state.searchQuery}". Try searching for another vendor name or category.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: AppColors.outline,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  _searchController.clear();
                  context.read<HomeBloc>().add(const HomeSearchQueryChanged(''));
                  context.read<HomeBloc>().add(const HomeCategoryChanged('All'));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Text(
                  'Reset Search & Filters',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

