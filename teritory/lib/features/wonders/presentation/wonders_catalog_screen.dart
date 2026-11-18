import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/models/api_flag.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/teritory_theme.dart';
import '../../flag/presentation/live_flag_detail_sheet.dart';
import '../application/wonders_provider.dart';

/// Major wonders registry, rendered from `GET /v1/flags/wonders`.
///
/// The server aggregates the flags travelers staked as major wonders, so every
/// row here is a claimed place with real claimants — there is no bundled
/// catalogue and no invented progress.
class WondersCatalogScreen extends ConsumerStatefulWidget {
  const WondersCatalogScreen({super.key});

  @override
  ConsumerState<WondersCatalogScreen> createState() =>
      _WondersCatalogScreenState();
}

class _WondersCatalogScreenState extends ConsumerState<WondersCatalogScreen> {
  String _selectedContinent = 'All';

  Future<void> _reload() async {
    ref.invalidate(wondersProvider);
    try {
      await ref.read(wondersProvider.future);
    } catch (_) {
      // The error state is rendered by the watcher below; a pull-to-refresh
      // must not throw out of the RefreshIndicator.
    }
  }

  Future<void> _openWonder(ApiWonder wonder) async {
    if (wonder.latestFlagId.isEmpty) return;
    await LiveFlagDetailSheet.show(context, flag: wonder.toFlag());
    if (!mounted) return;
    ref.invalidate(wondersProvider);
  }

  @override
  Widget build(BuildContext context) {
    final wondersAsync = ref.watch(wondersProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(
              Icons.military_tech_rounded,
              color: TeritoryColors.majorGoldDark,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              'Major Wonders',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: wondersAsync.when(
          loading: () => ListView(
            children: const [
              SizedBox(height: 160),
              Center(
                child: CircularProgressIndicator(color: TeritoryColors.primary),
              ),
            ],
          ),
          error: (error, _) => ListView(
            children: [
              const SizedBox(height: 120),
              _ErrorState(
                message: error is ApiException
                    ? error.message
                    : 'Could not load the wonders registry. Check your connection.',
                onRetry: () => ref.invalidate(wondersProvider),
              ),
            ],
          ),
          data: _buildCatalog,
        ),
      ),
    );
  }

  Widget _buildCatalog(List<ApiWonder> wonders) {
    if (wonders.isEmpty) {
      return ListView(children: const [SizedBox(height: 120), _EmptyState()]);
    }

    final continents = wonderContinents(wonders);
    if (_selectedContinent != 'All' &&
        !continents.contains(_selectedContinent)) {
      // The selected continent disappeared after a refresh; fall back to All.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _selectedContinent = 'All');
      });
    }

    final visible = _selectedContinent == 'All'
        ? wonders
        : wonders.where((w) => w.continent == _selectedContinent).toList();
    final claimedCount = wonders.where((w) => w.claimedByMe).length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        _ProgressHeader(
          claimed: claimedCount,
          total: wonders.length,
          travellers: wonders
              .expand((w) => w.claimers.map((c) => c.id))
              .toSet()
              .length,
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: ['All', ...continents].map((continent) {
              final selected = _selectedContinent == continent;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(continent),
                  selected: selected,
                  selectedColor: TeritoryColors.surfaceDark,
                  labelStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                    color: selected ? Colors.white : TeritoryColors.textPrimary,
                  ),
                  side: BorderSide(
                    color: selected
                        ? TeritoryColors.surfaceDark
                        : TeritoryColors.border,
                  ),
                  onSelected: (value) {
                    if (value) setState(() => _selectedContinent = continent);
                  },
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 14),
        ...visible.map(
          (wonder) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _WonderCard(
              wonder: wonder,
              onTap: () => _openWonder(wonder),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  final int claimed;
  final int total;
  final int travellers;

  const _ProgressHeader({
    required this.claimed,
    required this.total,
    required this.travellers,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: TeritoryColors.majorGold),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: TeritoryColors.majorGold.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.emoji_events_rounded,
              color: TeritoryColors.majorGoldDark,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$claimed of $total Wonders Claimed',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: TeritoryColors.majorGoldDark,
                  ),
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: total == 0 ? 0 : claimed / total,
                    minHeight: 6,
                    backgroundColor: Colors.white60,
                    valueColor: const AlwaysStoppedAnimation(
                      TeritoryColors.majorGoldDark,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Rallied from $travellers traveller'
                  '${travellers == 1 ? '' : 's'} who staked a major-wonder '
                  'flag. Mark a flag as a Major Wonder to join it.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: TeritoryColors.majorGoldDark.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WonderCard extends StatelessWidget {
  final ApiWonder wonder;
  final VoidCallback onTap;

  const _WonderCard({required this.wonder, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final claimed = wonder.claimedByMe;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: claimed ? TeritoryColors.majorGold : TeritoryColors.border,
              width: claimed ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                child: wonder.photoUrl.isEmpty
                    ? Container(
                        height: 140,
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: const Icon(
                          Icons.landscape_rounded,
                          size: 46,
                          color: TeritoryColors.majorGoldDark,
                        ),
                      )
                    : Image.network(
                        wonder.photoUrl,
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          height: 140,
                          width: double.infinity,
                          color: TeritoryColors.surfaceContainer,
                          child: const Icon(
                            Icons.landscape_rounded,
                            size: 46,
                            color: TeritoryColors.textMuted,
                          ),
                        ),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            wonder.placeName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: TeritoryColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: claimed
                                ? TeritoryColors.majorGoldLight
                                : TeritoryColors.surfaceContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            claimed ? 'CLAIMED' : 'UNEXPLORED',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.4,
                              color: claimed
                                  ? TeritoryColors.majorGoldDark
                                  : TeritoryColors.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        wonder.locationLabel,
                        if (wonder.continent.isNotEmpty) wonder.continent,
                      ].where((part) => part.isNotEmpty).join(' • '),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: TeritoryColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        ...wonder.claimers
                            .take(3)
                            .map(
                              (claimer) => Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: CircleAvatar(
                                  radius: 13,
                                  backgroundColor: TeritoryColors.border,
                                  backgroundImage: claimer.avatarUrl.isNotEmpty
                                      ? NetworkImage(claimer.avatarUrl)
                                      : null,
                                  child: claimer.avatarUrl.isEmpty
                                      ? const Icon(
                                          Icons.person_rounded,
                                          size: 14,
                                          color: Colors.white,
                                        )
                                      : null,
                                ),
                              ),
                            ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${wonder.claimCount} claim'
                            '${wonder.claimCount == 1 ? '' : 's'}'
                            ' • ${wonder.claimers.length} traveller'
                            '${wonder.claimers.length == 1 ? '' : 's'}',
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: TeritoryColors.textMuted,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          size: 18,
                          color: TeritoryColors.textMuted,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          const Icon(
            Icons.travel_explore_rounded,
            size: 46,
            color: TeritoryColors.textMuted,
          ),
          const SizedBox(height: 12),
          Text(
            'No wonders claimed yet',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: TeritoryColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'This registry is built from major-wonder flags travelers have '
            'staked. Drop a flag and switch on "Major Wonder" to start it.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              height: 1.4,
              color: TeritoryColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            size: 46,
            color: TeritoryColors.expiredRed,
          ),
          const SizedBox(height: 12),
          Text(
            'Registry unavailable',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: TeritoryColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              height: 1.4,
              color: TeritoryColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
