import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/models/service_models.dart';
import '../../../core/providers/data_providers.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/teritory_theme.dart';

/// Live trail-services sheet opened from Explore.
///
/// Gear comes from `GET /services/gear` and food from
/// `GET /services/nearby-food` (the API keeps a 10 km radius), both queried
/// around the map centre. There is no booking endpoint, so the copy says so
/// instead of pretending a request was sent.
class GearServiceSheet extends ConsumerStatefulWidget {
  const GearServiceSheet({
    super.key,
    required this.latitude,
    required this.longitude,
  });

  final double latitude;
  final double longitude;

  static void show(
    BuildContext context, {
    required double latitude,
    required double longitude,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => GearServiceSheet(
        latitude: latitude,
        longitude: longitude,
      ),
    );
  }

  @override
  ConsumerState<GearServiceSheet> createState() => _GearServiceSheetState();
}

class _GearServiceSheetState extends ConsumerState<GearServiceSheet> {
  int _tab = 0;

  bool get _isFood => _tab == 1;

  ServiceLocation get _location =>
      (lat: widget.latitude, lng: widget.longitude);

  @override
  Widget build(BuildContext context) {
    final location = _location;
    final providers = _isFood
        ? ref.watch(nearbyFoodProvidersProvider(location))
        : ref.watch(gearServicesProvider(location));
    final accent = _isFood ? TeritoryColors.foodOrange : TeritoryColors.gearAmber;

    return Container(
      height: MediaQuery.of(context).size.height * 0.78,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _isFood
                        ? Icons.restaurant_rounded
                        : Icons.backpack_rounded,
                    color: accent,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Trail Services',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: TeritoryColors.textPrimary,
                        ),
                      ),
                      Text(
                        _isFood
                            ? 'Food spots within 10 km of the map centre'
                            : 'Gear providers around the map centre',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: TeritoryColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _buildTab('Gear', 0, Icons.backpack_rounded),
                const SizedBox(width: 8),
                _buildTab('Eat Nearby', 1, Icons.restaurant_rounded),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: providers.when(
              loading: () => const Center(
                child: CircularProgressIndicator(
                    color: TeritoryColors.primary),
              ),
              error: (error, _) => _ServiceError(
                message: error is ApiException
                    ? error.message
                    : 'Could not reach the services API.',
                onRetry: () => ref.invalidate(_isFood
                    ? nearbyFoodProvidersProvider(location)
                    : gearServicesProvider(location)),
              ),
              data: (list) {
                if (list.isEmpty) {
                  return _ServiceEmpty(isFood: _isFood);
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) => _ServiceProviderTile(
                    provider: list[index],
                    isFood: _isFood,
                    onTap: () => ServiceProviderSheet.show(
                      context,
                      provider: list[index],
                      isFood: _isFood,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String label, int index, IconData icon) {
    final selected = _tab == index;
    final accent = _isFood ? TeritoryColors.foodOrange : TeritoryColors.gearAmber;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? accent.withValues(alpha: 0.14) : TeritoryColors.surfaceContainer,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? accent : TeritoryColors.border,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 16,
                  color: selected ? accent : TeritoryColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: selected ? accent : TeritoryColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServiceProviderTile extends StatelessWidget {
  const _ServiceProviderTile({
    required this.provider,
    required this.isFood,
    required this.onTap,
  });

  final ServiceProvider provider;
  final bool isFood;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = isFood ? TeritoryColors.foodOrange : TeritoryColors.gearAmber;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: TeritoryColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isFood ? Icons.restaurant_rounded : Icons.backpack_rounded,
                  color: accent,
                  size: 21,
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
                            provider.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: TeritoryColors.textPrimary,
                            ),
                          ),
                        ),
                        if (provider.isVerified)
                          const Padding(
                            padding: EdgeInsets.only(left: 6),
                            child: Icon(Icons.verified_rounded,
                                size: 15, color: TeritoryColors.sapphireBlue),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      provider.category.isEmpty
                          ? 'Trail service'
                          : provider.category,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        color: TeritoryColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (provider.distanceKm != null) ...[
                          const Icon(Icons.near_me_rounded,
                              size: 12, color: TeritoryColors.textMuted),
                          const SizedBox(width: 3),
                          Text(
                            '${provider.distanceKm!.toStringAsFixed(1)} km',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: TeritoryColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        const Icon(Icons.star_rounded,
                            size: 13, color: TeritoryColors.majorGold),
                        const SizedBox(width: 3),
                        Text(
                          provider.rating.toStringAsFixed(1),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: TeritoryColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '${provider.listings.length} '
                          '${provider.listings.length == 1 ? 'item' : 'items'}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: TeritoryColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  size: 20, color: TeritoryColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

/// Provider detail: listings and contact details, plus an explicit note that
/// the app cannot take a booking (there is no booking API).
class ServiceProviderSheet extends StatelessWidget {
  const ServiceProviderSheet({
    super.key,
    required this.provider,
    required this.isFood,
  });

  final ServiceProvider provider;
  final bool isFood;

  static void show(
    BuildContext context, {
    required ServiceProvider provider,
    required bool isFood,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ServiceProviderSheet(provider: provider, isFood: isFood),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = isFood ? TeritoryColors.foodOrange : TeritoryColors.gearAmber;
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.82,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(bottom: 14),
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    isFood ? Icons.restaurant_rounded : Icons.backpack_rounded,
                    color: accent,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        provider.name,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: TeritoryColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        [
                          if (provider.category.isNotEmpty) provider.category,
                          if (provider.distanceKm != null)
                            '${provider.distanceKm!.toStringAsFixed(1)} km away',
                          '★ ${provider.rating.toStringAsFixed(1)}',
                        ].join(' · '),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          color: TeritoryColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (provider.description.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                provider.description,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  height: 1.5,
                  color: TeritoryColors.textPrimary,
                ),
              ),
            ],
            if (provider.listings.isNotEmpty) ...[
              const SizedBox(height: 18),
              Text(
                isFood ? 'On the menu' : 'Available gear',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                  color: TeritoryColors.textMuted,
                ),
              ),
              const SizedBox(height: 8),
              ...provider.listings.map((listing) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: TeritoryColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                listing.title,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: TeritoryColors.textPrimary,
                                ),
                              ),
                              if (listing.description.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  listing.description,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11.5,
                                    height: 1.35,
                                    color: TeritoryColors.textSecondary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (listing.priceRange.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text(
                            listing.priceRange,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: accent,
                            ),
                          ),
                        ],
                      ],
                    ),
                  )),
            ],
            if (provider.contactPhone != null ||
                provider.websiteUrl != null) ...[
              const SizedBox(height: 14),
              Text(
                'Contact',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                  color: TeritoryColors.textMuted,
                ),
              ),
              const SizedBox(height: 6),
              if (provider.contactPhone != null)
                _ContactRow(
                  icon: Icons.call_rounded,
                  label: provider.contactPhone!,
                  uri: Uri.parse('tel:${provider.contactPhone}'),
                ),
              if (provider.websiteUrl != null)
                _ContactRow(
                  icon: Icons.link_rounded,
                  label: provider.websiteUrl!,
                  uri: Uri.parse(provider.websiteUrl!),
                ),
            ],
            const SizedBox(height: 10),
            _NavigateButton(
              latitude: provider.latitude,
              longitude: provider.longitude,
              label: provider.name,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: TeritoryColors.majorGoldLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded,
                      size: 16, color: TeritoryColors.majorGoldDark),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Booking is not available in Teritory yet — the API has '
                      'no booking endpoint, so nothing is reserved or charged '
                      'in the app. Contact the provider directly to book.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        height: 1.4,
                        color: TeritoryColors.majorGoldDark,
                      ),
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

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.icon,
    required this.label,
    required this.uri,
  });

  final IconData icon;
  final String label;
  final Uri uri;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => launchUrl(uri, mode: LaunchMode.externalApplication),
        child: Row(
          children: [
            Icon(icon, size: 15, color: TeritoryColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  color: TeritoryColors.primary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Copy',
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.copy_rounded,
                  size: 15, color: TeritoryColors.textMuted),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: label));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Copied $label')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _NavigateButton extends StatelessWidget {
  const _NavigateButton({
    required this.latitude,
    required this.longitude,
    required this.label,
  });

  final double latitude;
  final double longitude;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: TeritoryColors.primary,
          side: const BorderSide(color: TeritoryColors.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        icon: const Icon(Icons.directions_rounded, size: 18),
        label: Text(
          'Navigate to Location',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        onPressed: () {
          final uri = Uri.parse(
            'https://www.google.com/maps/dir/?api=1'
            '&destination=$latitude,$longitude'
            '&destination_place_id='
            '&travelmode=driving',
          );
          launchUrl(uri, mode: LaunchMode.externalApplication);
        },
      ),
    );
  }
}

class _ServiceEmpty extends StatelessWidget {
  const _ServiceEmpty({required this.isFood});

  final bool isFood;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isFood ? Icons.restaurant_rounded : Icons.backpack_outlined,
              size: 40,
              color: TeritoryColors.textMuted,
            ),
            const SizedBox(height: 10),
            Text(
              isFood
                  ? 'No food spots within 10 km of the map centre.'
                  : 'No gear providers are registered yet.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                height: 1.4,
                color: TeritoryColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceError extends StatelessWidget {
  const _ServiceError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded,
                size: 38, color: TeritoryColors.textMuted),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                height: 1.4,
                color: TeritoryColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: TeritoryColors.primary,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
