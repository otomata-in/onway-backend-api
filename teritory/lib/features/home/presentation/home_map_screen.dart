import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/models/api_flag.dart';
import '../../../core/models/flag_style.dart';
import '../../../core/models/pending_flag.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/flag_style_provider.dart';
import '../../../core/providers/location_provider.dart';
import '../../../core/services/location_service.dart';
import '../../../core/providers/preferences_provider.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/teritory_repository.dart';
import '../../../core/theme/flag_style_catalog.dart';
import '../../../core/theme/teritory_theme.dart';
import '../../../core/widgets/flag/teritory_flag.dart';
import '../../../core/widgets/teritory_logo.dart';
import '../../explore/application/explore_flags_provider.dart';
import '../../explore/presentation/expedition_omni_search_sheet.dart';
import '../../explore/presentation/spot_constellation_screen.dart';
import '../../flag/application/flag_queue_provider.dart';
import '../../flag/presentation/drop_flag_modal.dart';
import '../../flag/presentation/live_flag_detail_sheet.dart';
import '../../profile/application/profile_providers.dart';
import '../../notifications/presentation/notification_bell.dart';
import '../../services/presentation/gear_service_sheet.dart';

class HomeMapScreen extends ConsumerStatefulWidget {
  const HomeMapScreen({super.key});

  @override
  ConsumerState<HomeMapScreen> createState() => _HomeMapScreenState();
}

class _HomeMapScreenState extends ConsumerState<HomeMapScreen>
    with SingleTickerProviderStateMixin {
  late final MapController _mapController;

  /// The last resolved fix, for use inside callbacks. [build] watches the same
  /// provider, so the payload and the pulsing pin always share one centre.
  MapLocation? get _location => ref.read(mapLocationProvider).valueOrNull;

  String _selectedFilter = 'All';
  // Mirrors the persisted theme (true = Midnight Oceanic, false = Daylight
  // White); assigned from [mapThemeProvider] at the top of build.
  bool _isDarkTheme = true;
  double _currentZoom = 12.0;
  late AnimationController _pulseController;

  double get _flagZoomScale {
    if (_currentZoom >= 13.0) return 1.0;
    // Exponential shrink as the user zooms out so nearby pins separate cleanly
    // instead of overlapping at city/state/country zoom levels.
    return math.pow(0.78, (13.0 - _currentZoom).clamp(0.0, 8.0))
        .toDouble()
        .clamp(0.18, 1.0);
  }

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _recenterToUser() {
    ref.read(customExploreTargetProvider.notifier).state = null;
    final location = _location;
    if (location != null && location.isDeviceLocation) {
      _mapController.move(location.coordinates, 13.0);
      return;
    }
    // No fix: say so and offer a fresh attempt instead of pretending the map
    // centre is where the traveller is.
    final reason = location?.notice ?? 'Waiting for a location fix';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$reason.', style: GoogleFonts.plusJakartaSans()),
        action: SnackBarAction(
          label: 'Retry',
          onPressed: () => ref.invalidate(mapLocationProvider),
        ),
      ),
    );
  }

  Future<void> _openDropFlag() async {
    final location = _location;
    // A cached position is fine for reading flags, but a flag records where the
    // traveller stands, so writing needs a fresh fix.
    var coordinates =
        (location?.isDeviceLocation == true && location?.isStale != true)
        ? location!.coordinates
        : null;

    if (coordinates == null && (location == null || location.isStale)) {
      // No fresh fix yet — still acquiring, or only a cached position. This is
      // not a failure, so do not open the map-centre dialog.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Waiting for a fresh location fix — try again in a moment.',
            style: GoogleFonts.plusJakartaSans(),
          ),
        ),
      );
      return;
    }

    if (coordinates == null) {
      // Writing a flag without a real fix would pin invented coordinates on the
      // map, so require an explicit choice (with the reason shown) first.
      final reason = location?.notice ?? 'Waiting for a location fix';
      final choice = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(
            'Location unavailable',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
          ),
          content: Text(
            '$reason. A flag records exactly where you stand, so it needs a '
            'device location.',
            style: GoogleFonts.plusJakartaSans(fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'fallback'),
              child: const Text('Use map centre'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'retry'),
              child: const Text('Retry location'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      if (choice == 'retry') {
        ref.invalidate(mapLocationProvider);
        return;
      }
      if (choice != 'fallback') return;
      coordinates = MapLocation.fallback.coordinates;
    }

    await DropFlagModal.show(
      context,
      coordinates: coordinates,
      suggestedPlaceName: location?.isDeviceLocation == true
          ? 'Current Location'
          : 'Kazhakkoottam, Thiruvananthapuram',
    );
    if (!mounted) return;
    // Refresh unconditionally: a flag may have been created even if the sheet was
    // dismissed before it could report success.
    await ref.read(exploreFlagsProvider.notifier).refresh();
  }

  /// Opens the expedition omni-search sheet and navigates to the selected destination
  Future<void> _openOmniSearch() async {
    final selectedTarget = await ExpeditionOmniSearchSheet.show(context);
    if (!mounted || selectedTarget == null) return;
    try {
      _mapController.move(selectedTarget.coordinates, 13.5);
    } catch (_) {}
    if (selectedTarget.focusedFlag != null) {
      await Future<void>.delayed(const Duration(milliseconds: 200));
      if (!mounted) return;
      LiveFlagDetailSheet.show(context, flag: selectedTarget.focusedFlag!);
    }
  }

  /// Banner displaying the active searched place or flag destination
  Widget _buildCustomTargetNotice(ExploreTarget target) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: _isDarkTheme ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isDarkTheme
              ? const Color(0xFF3B82F6).withValues(alpha: 0.4)
              : const Color(0xFFBFDBFE),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.near_me_rounded,
            size: 15,
            color: TeritoryColors.primary,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Viewing: ${target.label}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _isDarkTheme ? Colors.white : TeritoryColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () {
              ref.read(customExploreTargetProvider.notifier).state = null;
              _recenterToUser();
            },
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Reset to GPS',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: TeritoryColors.primary,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.close_rounded,
                    size: 13,
                    color: TeritoryColors.primary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// "N flags saved": the queue is visible on the map, with the one action
  /// that can clear it. Nothing here claims the flags are staked.
  Widget _buildPendingFlagsBanner(int count) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.only(left: 10, right: 2, top: 2, bottom: 2),
          decoration: BoxDecoration(
            color: _isDarkTheme ? const Color(0xF21E293B) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: TeritoryColors.majorGold.withValues(alpha: 0.6),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_upload_outlined,
                size: 13,
                color: TeritoryColors.majorGold,
              ),
              const SizedBox(width: 4),
              Text(
                count == 1
                    ? '1 flag saved — waiting to sync'
                    : '$count flags saved — waiting to sync',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: _isDarkTheme
                      ? Colors.white
                      : TeritoryColors.textPrimary,
                ),
              ),
              TextButton(
                onPressed: _syncPendingFlags,
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 30),
                ),
                child: const Text('Sync now', style: TextStyle(fontSize: 11)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Drains the queue and reports what actually happened: the number staked, or
  /// the honest reason they are still waiting.
  Future<void> _syncPendingFlags() async {
    final messenger = ScaffoldMessenger.of(context);
    final report = await ref.read(flagQueueProvider.notifier).sync();
    if (!mounted) return;

    if (report.synced > 0) {
      await ref.read(exploreFlagsProvider.notifier).refresh();
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: TeritoryColors.primary,
          content: Text(
            report.synced == 1
                ? 'Saved flag staked.'
                : '${report.synced} saved flags staked.',
            style: GoogleFonts.plusJakartaSans(color: Colors.white),
          ),
        ),
      );
      return;
    }

    // Skipped means a sync is already running (or these flags belong to another
    // account): the run that is in flight reports for itself.
    if (report.skipped) return;

    String? reason;
    for (final flag in ref.read(flagQueueProvider)) {
      if (flag.lastError != null) {
        reason = flag.lastError;
        break;
      }
    }
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          reason ?? 'Still offline — the saved flags are waiting on this device.',
          style: GoogleFonts.plusJakartaSans(),
        ),
        action: SnackBarAction(label: 'Retry', onPressed: _syncPendingFlags),
      ),
    );
  }

  Future<void> _showPendingFlagSheet(PendingFlag pending) async {
    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              color: TeritoryColors.majorGold,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Not staked yet',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              pending.placeName,
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              pending.lastError ??
                  'Saved on this device. It will be staked as soon as Teritory '
                      'can be reached.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: TeritoryColors.textPrimary.withValues(alpha: 0.75),
              ),
            ),
            if (pending.attempts > 0) ...[
              const SizedBox(height: 6),
              Text(
                '${pending.attempts} attempt'
                '${pending.attempts == 1 ? '' : 's'} so far',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: TeritoryColors.textPrimary.withValues(alpha: 0.6),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'discard'),
            child: const Text(
              'Discard',
              style: TextStyle(color: TeritoryColors.expiredRed),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, 'retry'),
            child: const Text('Retry now'),
          ),
        ],
      ),
    );

    if (!mounted || choice == null) return;
    if (choice == 'discard') {
      await ref.read(flagQueueProvider.notifier).discard(pending.localId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '“${pending.placeName}” removed from this device.',
            style: GoogleFonts.plusJakartaSans(),
          ),
        ),
      );
      return;
    }
    await _syncPendingFlags();
  }

  /// Pin for a flag that exists only on this device. Deliberately unlike a
  /// staked pin — amber outline and an upload icon — so it never reads as
  /// territory the traveler already owns.
  Widget _buildPendingFlagPin(PendingFlag pending) {
    final pinBg = _isDarkTheme ? const Color(0xF21E293B) : Colors.white;
    return _buildPlantedFlagPin(
      style: pending.style,
      anchorColor: TeritoryColors.majorGold,
      badge: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: pinBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: TeritoryColors.majorGold,
            width: 1.4,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_upload_outlined,
              size: 13,
              color: TeritoryColors.majorGold,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                pending.placeName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  color: _isDarkTheme
                      ? Colors.white
                      : TeritoryColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Honest location state under the filters: names the reason the fallback
  /// centre is in use, or says a cached position is being shown while a fresh
  /// fix is on its way. It never says "map centre" when a real position is in use.
  Widget _buildLocationNotice(MapLocation location) {
    final label = location.isStale
        ? (location.notice ?? 'Using a cached position')
        : '${location.notice ?? 'No fix'} — showing map centre';

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.only(
            left: 10,
            right: 2,
            top: 2,
            bottom: 2,
          ),
          decoration: BoxDecoration(
            color: _isDarkTheme ? const Color(0xF21E293B) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: TeritoryColors.majorGold.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                location.isStale
                    ? Icons.location_searching_rounded
                    : Icons.location_off_rounded,
                size: 13,
                color: TeritoryColors.majorGold,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: _isDarkTheme
                      ? Colors.white
                      : TeritoryColors.textPrimary,
                ),
              ),
              TextButton(
                onPressed: () => ref.invalidate(mapLocationProvider),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 30),
                ),
                child: const Text('Retry', style: TextStyle(fontSize: 11)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _isDarkTheme = ref.watch(mapThemeProvider);
    final customTarget = ref.watch(customExploreTargetProvider);
    final mapLocation = ref.watch(mapLocationProvider).valueOrNull;
    final center = customTarget?.coordinates ??
        (mapLocation?.coordinates ?? MapLocation.fallback.coordinates);

    // Listen to custom explore target set via search to animate camera
    ref.listen<ExploreTarget?>(customExploreTargetProvider, (previous, next) {
      if (next != null) {
        try {
          _mapController.move(next.coordinates, 13.5);
        } catch (_) {}
      }
    });

    // The first real fix recentres the map once, so opening the app in a new
    // city does not leave the traveller looking at Kochi.
    ref.listen(mapLocationProvider, (previous, next) {
      // Do not override a user's active search target with automatic GPS fix
      if (ref.read(customExploreTargetProvider) != null) return;
      final location = next.valueOrNull;
      if (location == null) return;
      final prev = previous?.valueOrNull;
      // Recentre for the first position we get (cached or live), and once more
      // when the fresh fix replaces a cached one — not on every rebuild.
      if (prev != null && prev.isDeviceLocation && !prev.isStale) return;
      try {
        _mapController.move(location.coordinates, 13.0);
      } catch (_) {
        // The map may not be attached yet; its initial centre is already here.
      }
    });

    final exploreAsync = ref.watch(exploreFlagsProvider);
    // Sub-Spots have their own 5 km endpoint, so the request is only made while
    // that filter is selected.
    final subSpotsAsync = _selectedFilter == 'Sub-Spots'
        ? ref.watch(subSpotsProvider)
        : const AsyncValue<List<ApiFlag>>.data(<ApiFlag>[]);
    final subSpots = subSpotsAsync.valueOrNull ?? const <ApiFlag>[];
    final currentUserId = ref.watch(currentUserProvider).id;
    // Flags staked locally that the server has not accepted yet. They render as
    // real pins in a pending style — never as earned territory.
    final queued = ref.watch(flagQueueProvider);
    final pendingFlags = currentUserId.isEmpty
        ? const <PendingFlag>[]
        : queued.where((f) => f.userId == currentUserId).toList();
    final visiblePending = switch (_selectedFilter) {
      'Friends' || 'Sub-Spots' => const <PendingFlag>[],
      'Major Wonders' => pendingFlags.where((f) => f.isMajorFlag).toList(),
      _ => pendingFlags,
    };
    final isTripMode =
        ref.watch(myProfileProvider).valueOrNull?.isTripMode ?? false;
    // Keeping the previous payload during a re-query is what stops the pins
    // flickering. The radius filter is what stops them showing another city: a
    // payload loaded for an older centre keeps only the flags that still lie
    // inside the query radius of where the traveller is now.
    final raw =
        exploreAsync.valueOrNull ??
        const ExploreFlagsData(flags: [], friendIds: <String>{});
    final live = ExploreFlagsData(
      flags: [
        for (final flag in raw.flags)
          if (distanceMeters(center, flag.coordinates) <=
                  ExploreFlagsNotifier.radiusKm * 1000 ||
              flag.id == customTarget?.focusedFlag?.id)
            flag,
      ],
      friendIds: raw.friendIds,
    );

    // Filters run against live flags only; ownership and friendship are server
    // facts, not bundled sample data.
    final visible = switch (_selectedFilter) {
      'My Flags' => live.mine(currentUserId),
      'Friends' => live.friends(currentUserId),
      'Major Wonders' => live.major(),
      'Sub-Spots' => subSpots,
      _ => live.flags,
    };
    // Distinct travelers, not flags: one friend with three pins is one person.
    final friendsActiveCount = live
        .friends(currentUserId)
        .map((f) => f.userId)
        .toSet()
        .length;

    List<Marker> markers = [];

    // 1. User Current Location Pulsing Pin
    markers.add(
      Marker(
        point: center,
        width: 70,
        height: 70,
        alignment: Alignment.center,
        child: _buildCurrentLocationMarker(),
      ),
    );

    // 2. Live flag pins — group co-located flags (`<= 35m`) to avoid overlap.
    // Sort lowest-priority first so higher-priority pins (mine / major) paint on top.
    final groups = _groupOverlappingFlags(visible, currentUserId);
    final bool fanOutUpClose = _currentZoom >= 14.0;

    for (final group in groups) {
      final lead = group.first;
      void openConstellation() => SpotConstellationScreen.open(
            context,
            flags: group,
            friendIds: live.friendIds,
          );

      if (group.length == 1) {
        final isMine = lead.isOwnedBy(currentUserId);
        markers.add(
          Marker(
            point: lead.coordinates,
            width: lead.isMajorFlag ? 148 : 136,
            height: lead.isMajorFlag ? 86 : 76,
            alignment: Alignment.topCenter,
            child: _DeepHoldMarker(
              onTap: () => LiveFlagDetailSheet.show(context, flag: lead),
              onDeepHold: openConstellation,
              child: isMine
                  ? _buildUserFlagPin(lead)
                  : _buildFriendFlagPin(lead),
            ),
          ),
        );
      } else if (fanOutUpClose && group.length <= 4) {
        // Fan out up to 4 co-located flags cleanly when zoomed in close.
        for (var i = group.length - 1; i >= 0; i--) {
          final flag = group[i];
          final isMine = flag.isOwnedBy(currentUserId);
          final offset = _fanOffset(i, group.length);
          markers.add(
            Marker(
              point: flag.coordinates,
              width: flag.isMajorFlag ? 148 : 136,
              height: flag.isMajorFlag ? 86 : 76,
              alignment: Alignment.topCenter,
              child: Transform.translate(
                offset: offset,
                child: _DeepHoldMarker(
                  onTap: () => LiveFlagDetailSheet.show(context, flag: flag),
                  onDeepHold: openConstellation,
                  child: isMine
                      ? _buildUserFlagPin(flag)
                      : _buildFriendFlagPin(flag),
                ),
              ),
            ),
          );
        }
      } else {
        // Stacked Multi-Explorer Cluster Pin when zoomed out or 5+ explorers.
        final hasMajor = group.any((f) => f.isMajorFlag);
        markers.add(
          Marker(
            point: lead.coordinates,
            width: hasMajor ? 184 : 164,
            height: hasMajor ? 108 : 84,
            alignment: Alignment.topCenter,
            child: _DeepHoldMarker(
              onTap: () => _showSpotExplorersSheet(group, live.friendIds),
              onDeepHold: openConstellation,
              child: _buildClusterFlagPin(group, currentUserId),
            ),
          ),
        );
      }
    }

    // 3. Saved-but-not-yet-staked flags from the offline queue
    for (final pending in visiblePending) {
      markers.add(
        Marker(
          point: pending.coordinates,
          width: 150,
          height: 86,
          alignment: Alignment.topCenter,
          child: GestureDetector(
            onTap: () => _showPendingFlagSheet(pending),
            child: _buildPendingFlagPin(pending),
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          // ── Interactive Map Canvas (100% Free OSM with Classic Dark Mode) ──
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: center,
              initialZoom: 12.0,
              minZoom: 2.0,
              maxZoom: 18.0,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
              onPositionChanged: (camera, hasGesture) {
                final z = camera.zoom;
                if ((z - _currentZoom).abs() >= 0.04) {
                  setState(() => _currentZoom = z);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.onway.teritory',
                tileBuilder: _isDarkTheme
                    ? (context, tileWidget, tile) => ColorFiltered(
                        colorFilter: const ColorFilter.matrix(<double>[
                          -0.20,
                          -0.15,
                          -0.30,
                          0.0,
                          140,
                          -0.45,
                          0.20,
                          -0.35,
                          0.0,
                          165,
                          -0.55,
                          0.05,
                          -0.05,
                          0.0,
                          185,
                          0.0,
                          0.0,
                          0.0,
                          1.0,
                          0,
                        ]),
                        child: tileWidget,
                      )
                    : null,
              ),
              // One wind clock for every pin on the map, never one per pin.
              // `rotate: true` keeps flags and labels upright when the map turns.
              FlagMotionHost(child: MarkerLayer(markers: markers, rotate: true)),
            ],
          ),

          // ── Top Gradient Scrim for Readability ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 140,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(
                        alpha: _isDarkTheme ? 0.65 : 0.45,
                      ),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Top Header & Filter Chips ──
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  // Header Bar
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: _isDarkTheme
                          ? const Color(0xF21E293B)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: _isDarkTheme
                          ? Border.all(
                              color: const Color(0xFF334155),
                              width: 1.0,
                            )
                          : null,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.18),
                          blurRadius: 18,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        TeritoryLogo(
                          size: 34,
                          showText: true,
                          subtitle: 'FOOTPRINTS',
                          isDark: _isDarkTheme,
                        ),
                        const Spacer(),
                        // Omni-Search button: Search places, flags, clans, explorers
                        IconButton(
                          onPressed: _openOmniSearch,
                          tooltip: 'Search places, flags, clans, explorers',
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints.tightFor(
                            width: 32,
                            height: 32,
                          ),
                          icon: Icon(
                            Icons.search_rounded,
                            size: 22,
                            color: _isDarkTheme
                                ? Colors.white
                                : TeritoryColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        // Major wonders registry (`GET /flags/wonders`)
                        IconButton(
                          onPressed: () => context.push('/wonders'),
                          tooltip: 'Major wonders registry',
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints.tightFor(
                            width: 32,
                            height: 32,
                          ),
                          icon: Icon(
                            Icons.military_tech_rounded,
                            size: 20,
                            color: _isDarkTheme
                                ? TeritoryColors.majorGold
                                : TeritoryColors.majorGoldDark,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const NotificationBell(),
                        const SizedBox(width: 4),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _isDarkTheme
                                    ? const Color(0xFF0F172A)
                                    : TeritoryColors.primaryLight,
                                borderRadius: BorderRadius.circular(12),
                                border: _isDarkTheme
                                    ? Border.all(
                                        color: const Color(0xFF334155),
                                        width: 0.8,
                                      )
                                    : null,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.people_alt_rounded,
                                    size: 14,
                                    color: TeritoryColors.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$friendsActiveCount Friends',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: TeritoryColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isTripMode) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _isDarkTheme
                              ? const Color(0xFF1E293B)
                              : TeritoryColors.tripRoute.withValues(
                                  alpha: 0.15,
                                ),
                          borderRadius: BorderRadius.circular(12),
                          border: _isDarkTheme
                              ? Border.all(
                                  color: const Color(0xFF334155),
                                  width: 0.8,
                                )
                              : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.route_rounded,
                              size: 13,
                              color: TeritoryColors.tripRoute,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'On a trip',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: _isDarkTheme
                                    ? Colors.white
                                    : TeritoryColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),

                  // Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('All', Icons.travel_explore_rounded),
                        _buildFilterChip(
                          'Friends',
                          Icons.people_outline_rounded,
                        ),
                        _buildFilterChip('My Flags', Icons.flag_outlined),
                        _buildFilterChip(
                          'Major Wonders',
                          Icons.star_border_rounded,
                        ),
                        _buildFilterChip('Sub-Spots', Icons.diamond_outlined),
                      ],
                    ),
                  ),

                  // When looking at a searched destination: banner with Reset to GPS
                  if (customTarget != null) ...[
                    const SizedBox(height: 8),
                    _buildCustomTargetNotice(customTarget),
                  ],

                  // Flags saved while offline: visible until the server has them.
                  if (pendingFlags.isNotEmpty)
                    _buildPendingFlagsBanner(pendingFlags.length),

                  // Why the map is not on the traveller: never silent.
                  if (mapLocation != null &&
                      (!mapLocation.isDeviceLocation || mapLocation.isStale))
                    _buildLocationNotice(mapLocation),
                ],
              ),
            ),
          ),

          // ── Right Side Navigation Buttons ──
          Positioned(
            right: 16,
            bottom: MediaQuery.of(context).padding.bottom + 236,
            child: Column(
              children: [
                // Gear rental + nearby food (live /services endpoints)
                FloatingActionButton.small(
                  heroTag: 'services_btn',
                  tooltip: 'Gear & food nearby',
                  backgroundColor: _isDarkTheme
                      ? const Color(0xFF1E293B)
                      : Colors.white,
                  foregroundColor: TeritoryColors.gearAmber,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: _isDarkTheme
                        ? const BorderSide(color: Color(0xFF334155), width: 1.0)
                        : BorderSide.none,
                  ),
                  onPressed: () => GearServiceSheet.show(
                    context,
                    latitude: center.latitude,
                    longitude: center.longitude,
                  ),
                  child: const Icon(Icons.backpack_rounded),
                ),
                const SizedBox(height: 8),
                // Map Theme Selector (Midnight Oceanic / Daylight White Map)
                FloatingActionButton.small(
                  heroTag: 'theme_toggle_btn',
                  tooltip: _isDarkTheme
                      ? 'Switch to Daylight White Map'
                      : 'Switch to Midnight Oceanic Map',
                  backgroundColor: _isDarkTheme
                      ? const Color(0xFF1E293B)
                      : Colors.white,
                  foregroundColor: _isDarkTheme
                      ? const Color(0xFF38BDF8)
                      : const Color(0xFFF59E0B),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: _isDarkTheme
                        ? const BorderSide(color: Color(0xFF334155), width: 1.0)
                        : BorderSide.none,
                  ),
                  onPressed: () async {
                    final nextDark = !_isDarkTheme;
                    await ref
                        .read(mapThemeProvider.notifier)
                        .setDark(nextDark);
                    try {
                      await TeritoryRepository.instance.updateMyProfile(
                        mapStyle:
                            nextDark ? 'midnight_oceanic' : 'daylight_white',
                      );
                      ref.invalidate(myProfileProvider);
                    } catch (_) {}
                  },
                  child: Icon(
                    _isDarkTheme
                        ? Icons.water_drop_rounded
                        : Icons.light_mode_rounded,
                  ),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'recenter_btn',
                  backgroundColor: _isDarkTheme
                      ? const Color(0xFF1E293B)
                      : Colors.white,
                  foregroundColor: _isDarkTheme
                      ? Colors.white
                      : TeritoryColors.textPrimary,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: _isDarkTheme
                        ? const BorderSide(color: Color(0xFF334155), width: 1.0)
                        : BorderSide.none,
                  ),
                  onPressed: _recenterToUser,
                  child: const Icon(Icons.my_location_rounded),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'zoom_in_btn',
                  backgroundColor: _isDarkTheme
                      ? const Color(0xFF1E293B)
                      : Colors.white,
                  foregroundColor: _isDarkTheme
                      ? Colors.white
                      : TeritoryColors.textPrimary,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: _isDarkTheme
                        ? const BorderSide(color: Color(0xFF334155), width: 1.0)
                        : BorderSide.none,
                  ),
                  onPressed: () {
                    final current = _mapController.camera.zoom;
                    _mapController.move(
                      _mapController.camera.center,
                      current + 1,
                    );
                  },
                  child: const Icon(Icons.add),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'zoom_out_btn',
                  backgroundColor: _isDarkTheme
                      ? const Color(0xFF1E293B)
                      : Colors.white,
                  foregroundColor: _isDarkTheme
                      ? Colors.white
                      : TeritoryColors.textPrimary,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: _isDarkTheme
                        ? const BorderSide(color: Color(0xFF334155), width: 1.0)
                        : BorderSide.none,
                  ),
                  onPressed: () {
                    final current = _mapController.camera.zoom;
                    _mapController.move(
                      _mapController.camera.center,
                      current - 1,
                    );
                  },
                  child: const Icon(Icons.remove),
                ),
              ],
            ),
          ),

          // ── Bottom Location Flags Carousel ──
          if (_selectedFilter != 'Sub-Spots')
            Positioned(
              left: 0,
              right: 0,
              bottom: MediaQuery.of(context).padding.bottom + 138,
              child: _buildLocationFlagsCarousel(
                flags: visible,
                center: center,
                currentUserId: currentUserId,
              ),
            ),

          // ── Sub-Spots shelf (hidden gems within 5 km) ──
          if (_selectedFilter == 'Sub-Spots')
            Positioned(
              left: 0,
              right: 0,
              bottom: MediaQuery.of(context).padding.bottom + 138,
              child: _buildSubSpotsShelf(subSpotsAsync),
            ),

          // ── Primary Action Button: "Flag Current Teritory" ──
          Positioned(
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).padding.bottom + 76,
            child: SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _openDropFlag,
                style: ElevatedButton.styleFrom(
                  backgroundColor: TeritoryColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 8,
                  shadowColor: TeritoryColors.primary.withValues(alpha: 0.45),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.flag_rounded,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Flag My Teritory Here',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Live data state overlay ──
          if (exploreAsync.isLoading)
            const _MapStatusBanner(
              icon: Icons.cloud_sync_rounded,
              message: 'Loading live flags…',
              color: TeritoryColors.sapphireBlue,
            ),
          if (exploreAsync.hasError)
            _MapStatusBanner(
              icon: Icons.cloud_off_rounded,
              message: 'Teritory is unreachable. Check the API and retry.',
              color: TeritoryColors.expiredRed,
              onRetry: () => ref.read(exploreFlagsProvider.notifier).refresh(),
            ),
          if (live.flags.isEmpty &&
              !exploreAsync.isLoading &&
              !exploreAsync.hasError)
            const _MapStatusBanner(
              icon: Icons.flag_outlined,
              message: 'No flags here yet — be the first to drop one.',
              color: TeritoryColors.primary,
            ),
        ],
      ),
    );
  }

  /// Horizontal carousel of flags with respect to the active map location & filter.
  Widget _buildLocationFlagsCarousel({
    required List<ApiFlag> flags,
    required LatLng center,
    required String? currentUserId,
  }) {
    if (flags.isEmpty) {
      return Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: _isDarkTheme ? const Color(0xF21E293B) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _isDarkTheme
                  ? const Color(0xFF334155)
                  : const Color(0xFFE2E8F0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.travel_explore_rounded,
                size: 15,
                color: _isDarkTheme
                    ? const Color(0xFF94A3B8)
                    : TeritoryColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                'No ${_selectedFilter == 'All' ? '' : '$_selectedFilter '}flags found in this territory',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: _isDarkTheme
                      ? const Color(0xFFCBD5E1)
                      : TeritoryColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 64,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: flags.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (ctx, index) {
          final flag = flags[index];
          final isMine = flag.isOwnedBy(currentUserId);
          final distKm = (distanceMeters(center, flag.coordinates) / 1000)
              .toStringAsFixed(1);

          Color borderColor;
          if (flag.isMajorFlag) {
            borderColor = TeritoryColors.majorGold;
          } else if (isMine) {
            borderColor = TeritoryColors.primary;
          } else if (_isDarkTheme) {
            borderColor = const Color(0xFF334155);
          } else {
            borderColor = const Color(0xFFE2E8F0);
          }

          return GestureDetector(
            onTap: () {
              _mapController.move(flag.coordinates, 15.0);
              LiveFlagDetailSheet.show(context, flag: flag);
            },
            child: Container(
              padding: const EdgeInsets.fromLTRB(8, 6, 14, 6),
              decoration: BoxDecoration(
                color: _isDarkTheme ? const Color(0xF21E293B) : Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: borderColor,
                  width: flag.isMajorFlag ? 1.6 : 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: flag.isMajorFlag
                          ? TeritoryColors.majorGold.withValues(alpha: 0.18)
                          : (isMine
                              ? TeritoryColors.primary.withValues(alpha: 0.15)
                              : TeritoryColors.surfaceContainer),
                      image: flag.photoUrl.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(flag.photoUrl),
                              fit: BoxFit.cover,
                            )
                          : (flag.authorAvatar.isNotEmpty
                              ? DecorationImage(
                                  image: NetworkImage(flag.authorAvatar),
                                  fit: BoxFit.cover,
                                )
                              : null),
                    ),
                    child: (flag.photoUrl.isEmpty && flag.authorAvatar.isEmpty)
                        ? Icon(
                            flag.isMajorFlag
                                ? Icons.military_tech_rounded
                                : (isMine
                                    ? Icons.flag_rounded
                                    : Icons.person_pin_circle_rounded),
                            size: 18,
                            color: flag.isMajorFlag
                                ? TeritoryColors.majorGold
                                : TeritoryColors.primary,
                          )
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 150),
                            child: Text(
                              flag.placeName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _isDarkTheme
                                    ? Colors.white
                                    : TeritoryColors.textPrimary,
                              ),
                            ),
                          ),
                          if (flag.isMajorFlag) ...[
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.star_rounded,
                              size: 14,
                              color: TeritoryColors.majorGold,
                            ),
                          ],
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$distKm km away',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: TeritoryColors.primary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '• ${isMine ? 'You' : (flag.authorName.isNotEmpty ? flag.authorName.split(' ').first : flag.category)}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10.5,
                              color: _isDarkTheme
                                  ? const Color(0xFF94A3B8)
                                  : TeritoryColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Horizontal shelf for the Sub-Spots filter: live hidden gems within 5 km,
  /// ordered by the server (HIDDEN_GEM reactions, then distance).
  Widget _buildSubSpotsShelf(AsyncValue<List<ApiFlag>> spotsAsync) {
    final textColor = _isDarkTheme ? Colors.white : TeritoryColors.textPrimary;
    final surface = _isDarkTheme ? const Color(0xF21E293B) : Colors.white;

    Widget pill({required Widget child}) => Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(29),
        border: Border.all(
          color: _isDarkTheme ? const Color(0xFF334155) : Colors.white,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(child: child),
    );

    return spotsAsync.when(
      loading: () => pill(
        child: const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (error, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: pill(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                size: 16,
                color: TeritoryColors.expiredRed,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  error is ApiException
                      ? error.message
                      : 'Could not load Sub-Spots.',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    color: textColor,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => ref.invalidate(subSpotsProvider),
                child: const Text('Retry', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ),
      ),
      data: (spots) {
        if (spots.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: pill(
              child: Text(
                'No hidden gems within 5 km of the map centre yet.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  color: _isDarkTheme
                      ? const Color(0xFF94A3B8)
                      : TeritoryColors.textSecondary,
                ),
              ),
            ),
          );
        }

        return SizedBox(
          height: 64,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: spots.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final spot = spots[index];
              return GestureDetector(
                onTap: () {
                  _mapController.move(spot.coordinates, 15.5);
                  LiveFlagDetailSheet.show(context, flag: spot);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: spot.hiddenGemCount > 0
                          ? TeritoryColors.subTerritoryTeal
                          : (_isDarkTheme
                                ? const Color(0xFF334155)
                                : Colors.white),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.diamond_outlined,
                        size: 18,
                        color: TeritoryColors.subTerritoryTeal,
                      ),
                      const SizedBox(width: 8),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            spot.placeName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          Text(
                            '${spot.hiddenGemCount} gem'
                            '${spot.hiddenGemCount == 1 ? '' : 's'} • '
                            '${spot.distanceKm.toStringAsFixed(1)} km',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: _isDarkTheme
                                  ? const Color(0xFF94A3B8)
                                  : TeritoryColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(String label, IconData icon) {
    final isSelected = _selectedFilter == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedFilter = label;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? TeritoryColors.primary
                : (_isDarkTheme ? const Color(0xF21E293B) : Colors.white),
            borderRadius: BorderRadius.circular(20),
            border: _isDarkTheme && !isSelected
                ? Border.all(color: const Color(0xFF334155), width: 1.0)
                : null,
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? TeritoryColors.primary.withValues(alpha: 0.35)
                    : Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 15,
                color: isSelected
                    ? Colors.white
                    : (_isDarkTheme
                          ? const Color(0xFFCBD5E1)
                          : TeritoryColors.textPrimary),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected
                      ? Colors.white
                      : (_isDarkTheme
                            ? const Color(0xFFCBD5E1)
                            : TeritoryColors.textPrimary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Current Location Pulsing Pin (Classic Coral Travel Beacon)
  Widget _buildCurrentLocationMarker() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final scale = 1.0 + (_pulseController.value * 0.4);
        final opacity = 1.0 - _pulseController.value;
        return Stack(
          alignment: Alignment.center,
          children: [
            Transform.scale(
              scale: scale,
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: TeritoryColors.primary.withValues(
                    alpha: opacity * 0.45,
                  ),
                ),
              ),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: TeritoryColors.primary,
                border: Border.all(color: Colors.white, width: 3.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  /// Shared layout for map flags: a separate classy floating badge (DP + name)
  /// above a balanced waving flag with a medium-long pole staked into a
  /// miniature terrain mound (or glowing lava volcano for Major Flags).
  Widget _buildPlantedFlagPin({
    required Widget badge,
    required FlagStyle style,
    required Color anchorColor,
    bool isMajor = false,
  }) {
    final double flagWidth = isMajor ? 34 : 28;
    final double flagHeight = isMajor ? 42 : 35;
    final double baseWidth = isMajor ? 26 : 20;
    // Offset the flag right so its pole (at 0.075 * width) aligns with the
    // horizontal center of the marker and lands right in the terrain summit.
    final double poleCenterOffset = flagWidth * (1 - 0.15);

    return Transform.scale(
      scale: _flagZoomScale,
      alignment: Alignment.bottomCenter,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          badge,
          const SizedBox(height: 2),
          SizedBox(
            height: flagHeight + (isMajor ? 9 : 6),
            child: Stack(
              alignment: Alignment.bottomCenter,
              clipBehavior: Clip.none,
              children: [
                // Sculpted rocky hillock / glowing lava volcano basement.
                FlagTerrainBase(
                  accentColor: anchorColor,
                  isMajor: isMajor,
                  width: baseWidth,
                ),
                Padding(
                  padding: EdgeInsets.only(
                    left: poleCenterOffset,
                    bottom: isMajor ? 7.5 : 5,
                  ),
                  child: FlagPinFlag(
                    style: style,
                    width: flagWidth,
                    height: flagHeight,
                    showPole: true,
                    isMajor: isMajor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static const Distance _geoDistance = Distance();

  /// Groups flags within ~35 meters of each other and sorts each group by
  /// priority (own flags -> major wonders -> kudos/recency), then sorts groups
  /// so lower-priority pins render first and higher-priority pins paint on top.
  List<List<ApiFlag>> _groupOverlappingFlags(
    List<ApiFlag> flags,
    String currentUserId,
  ) {
    int priorityScore(ApiFlag f) {
      var score = 0;
      if (f.isOwnedBy(currentUserId)) score += 10000;
      if (f.isMajorFlag) score += 1000;
      score += f.kudos.clamp(0, 500);
      return score;
    }

    final sorted = List<ApiFlag>.from(flags)
      ..sort((a, b) => priorityScore(b).compareTo(priorityScore(a)));

    final groups = <List<ApiFlag>>[];
    for (final flag in sorted) {
      List<ApiFlag>? target;
      for (final group in groups) {
        final meters = _geoDistance.as(
          LengthUnit.Meter,
          group.first.coordinates,
          flag.coordinates,
        );
        if (meters <= 35) {
          target = group;
          break;
        }
      }
      if (target != null) {
        target.add(flag);
      } else {
        groups.add([flag]);
      }
    }

    // Reverse group order so highest-priority groups render last (on top).
    return groups.reversed.toList();
  }

  Offset _fanOffset(int index, int count) {
    switch (count) {
      case 2:
        return index == 0 ? const Offset(-18, 0) : const Offset(18, 0);
      case 3:
        const offsets = [
          Offset(-22, 6),
          Offset(0, -10),
          Offset(22, 6),
        ];
        return offsets[index];
      case 4:
      default:
        const offsets = [
          Offset(-24, 6),
          Offset(-8, -10),
          Offset(8, -10),
          Offset(24, 6),
        ];
        return offsets[index % offsets.length];
    }
  }

  /// Stacked multi-explorer pin shown when 2+ travelers share a spot while
  /// zoomed out (or 5+ at any zoom). Shows overlapping DPs + count above the
  /// lead flag on its terrain/volcano base.
  Widget _buildClusterFlagPin(List<ApiFlag> group, String currentUserId) {
    final lead = group.first;
    final hasMajor = group.any((f) => f.isMajorFlag);
    final leadStyle = lead.effectiveStyle(
      currentUserId,
      ref.watch(flagStyleProvider),
    );
    final themeColor = hasMajor
        ? TeritoryColors.majorGold
        : FlagStyleCatalog.primaryColor(leadStyle);
    final compact = _currentZoom < 10.5;
    final avatars = group.take(3).toList();

    return _buildPlantedFlagPin(
      style: leadStyle,
      anchorColor: themeColor,
      isMajor: hasMajor,
      badge: Container(
        constraints: BoxConstraints(maxWidth: hasMajor ? 172 : 150),
        padding: hasMajor
            ? const EdgeInsets.fromLTRB(8, 5, 8, 4)
            : const EdgeInsets.fromLTRB(4, 3, 8, 3),
        decoration: BoxDecoration(
          gradient: hasMajor
              ? const LinearGradient(
                  colors: [Color(0xFF1C1917), Color(0xFF451A03)],
                )
              : LinearGradient(
                  colors: _isDarkTheme
                      ? const [Color(0xF50F172A), Color(0xF51E293B)]
                      : const [Colors.white, Color(0xFFF8FAFC)],
                ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasMajor ? const Color(0xFFFBBF24) : themeColor,
            width: hasMajor ? 1.5 : 1.3,
          ),
          boxShadow: [
            BoxShadow(
              color: hasMajor
                  ? TeritoryColors.majorGold.withValues(alpha: 0.48)
                  : Colors.black.withValues(alpha: 0.2),
              blurRadius: hasMajor ? 10 : 7,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: hasMajor
            ? Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (!compact) ...[
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.auto_awesome_rounded,
                          size: 11,
                          color: Color(0xFFFEF08A),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            lead.placeName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              color: const Color(0xFFFEF3C7),
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                  ],
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16.0 + (avatars.length - 1) * 9.0,
                        height: 17,
                        child: Stack(
                          children: [
                            for (var i = 0; i < avatars.length; i++)
                              Positioned(
                                left: i * 9.0,
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xFFFBBF24),
                                      width: 1.1,
                                    ),
                                  ),
                                  child: CircleAvatar(
                                    radius: 7,
                                    backgroundColor:
                                        themeColor.withValues(alpha: 0.25),
                                    backgroundImage:
                                        avatars[i].authorAvatar.isNotEmpty
                                            ? NetworkImage(
                                                avatars[i].authorAvatar,
                                              )
                                            : null,
                                    child: avatars[i].authorAvatar.isEmpty
                                        ? const Icon(
                                            Icons.person_rounded,
                                            size: 9,
                                            color: Colors.white,
                                          )
                                        : null,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: TeritoryColors.majorGold.withValues(alpha: 0.24),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          compact ? '${group.length}' : '${group.length} Flags',
                          style: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFFFEF08A),
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 18.0 + (avatars.length - 1) * 10.0,
                    height: 19,
                    child: Stack(
                      children: [
                        for (var i = 0; i < avatars.length; i++)
                          Positioned(
                            left: i * 10.0,
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 1.2,
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 8,
                                backgroundColor:
                                    themeColor.withValues(alpha: 0.25),
                                backgroundImage:
                                    avatars[i].authorAvatar.isNotEmpty
                                        ? NetworkImage(avatars[i].authorAvatar)
                                        : null,
                                child: avatars[i].authorAvatar.isEmpty
                                    ? const Icon(
                                        Icons.person_rounded,
                                        size: 10,
                                        color: Colors.white,
                                      )
                                    : null,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    compact ? '${group.length}' : '${group.length} Flags',
                    style: GoogleFonts.plusJakartaSans(
                      color: _isDarkTheme
                          ? Colors.white
                          : TeritoryColors.textPrimary,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  /// Opens a clean bottom sheet listing every traveler who flagged a shared
  /// spot, so the user can inspect any individual flag or open the nested
  /// Constellation Map View.
  Future<void> _showSpotExplorersSheet(
    List<ApiFlag> group,
    Set<String> friendIds,
  ) async {
    final lead = group.first;
    final hasMajor = group.any((f) => f.isMajorFlag);

    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(sheetCtx).size.height * 0.68,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: hasMajor
                            ? TeritoryColors.majorGoldLight
                            : TeritoryColors.primaryLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        hasMajor
                            ? Icons.auto_awesome_rounded
                            : Icons.flag_rounded,
                        color: hasMajor
                            ? TeritoryColors.majorGoldDark
                            : TeritoryColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lead.placeName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: TeritoryColors.textPrimary,
                            ),
                          ),
                          Text(
                            '${group.length} explorers staked flags here',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: TeritoryColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: () {
                        Navigator.of(sheetCtx).pop();
                        SpotConstellationScreen.open(
                          context,
                          flags: group,
                          friendIds: friendIds,
                        );
                      },
                      icon: const Icon(Icons.hub_rounded, size: 15),
                      label: const Text('Constellation'),
                      style: FilledButton.styleFrom(
                        backgroundColor: hasMajor
                            ? TeritoryColors.majorGoldDark
                            : TeritoryColors.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        textStyle: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
                  itemCount: group.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (_, idx) {
                    final flag = group[idx];
                    return InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        Navigator.of(sheetCtx).pop();
                        LiveFlagDetailSheet.show(context, flag: flag);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: TeritoryColors.background,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: TeritoryColors.border),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: TeritoryColors.border,
                              backgroundImage: flag.authorAvatar.isNotEmpty
                                  ? NetworkImage(flag.authorAvatar)
                                  : null,
                              child: flag.authorAvatar.isEmpty
                                  ? const Icon(
                                      Icons.person_rounded,
                                      size: 18,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    flag.authorName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: TeritoryColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    flag.isMajorFlag
                                        ? 'Major Wonder · ${flag.kudos} kudos'
                                        : '${flag.category} · ${flag.kudos} kudos',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11.5,
                                      color: flag.isMajorFlag
                                          ? TeritoryColors.majorGoldDark
                                          : TeritoryColors.textSecondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            TeritoryFlag(
                              style: flag.flagStyle,
                              width: 32,
                              isMajor: flag.isMajorFlag,
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: TeritoryColors.textMuted,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Pin for User's own flagged locations
  Widget _buildUserFlagPin(ApiFlag flag) {
    final myId = ref.watch(currentUserProvider).id;
    final myStyle = ref.watch(flagStyleProvider);
    final effectiveStyle = flag.effectiveStyle(myId, myStyle);
    final themeColor = FlagStyleCatalog.primaryColor(effectiveStyle);
    final accentColor = flag.isMajorFlag
        ? TeritoryColors.majorGold
        : themeColor;
    final hideText = _currentZoom < 10.5;

    return _buildPlantedFlagPin(
      style: effectiveStyle,
      anchorColor: accentColor,
      isMajor: flag.isMajorFlag,
      badge: Container(
        padding: hideText
            ? const EdgeInsets.all(2.5)
            : const EdgeInsets.fromLTRB(3, 3, 9, 3),
        decoration: BoxDecoration(
          gradient: flag.isMajorFlag
              ? const LinearGradient(
                  colors: [Color(0xFF1C1917), Color(0xFF451A03)],
                )
              : LinearGradient(
                  colors: _isDarkTheme
                      ? const [Color(0xF50F172A), Color(0xF51E293B)]
                      : const [Colors.white, Color(0xFFF8FAFC)],
                ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: flag.isMajorFlag
                ? const Color(0xFFFBBF24)
                : accentColor.withValues(alpha: 0.7),
            width: flag.isMajorFlag ? 1.5 : 1.3,
          ),
          boxShadow: [
            BoxShadow(
              color: flag.isMajorFlag
                  ? TeritoryColors.majorGold.withValues(alpha: 0.48)
                  : Colors.black.withValues(alpha: 0.18),
              blurRadius: flag.isMajorFlag ? 10 : 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(1.3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: accentColor, width: 1.4),
              ),
              child: CircleAvatar(
                radius: 8.5,
                backgroundColor: accentColor.withValues(alpha: 0.2),
                backgroundImage: flag.authorAvatar.isNotEmpty
                    ? NetworkImage(flag.authorAvatar)
                    : null,
                child: flag.authorAvatar.isEmpty
                    ? Icon(
                        Icons.person_rounded,
                        size: 11,
                        color: flag.isMajorFlag ? Colors.white : accentColor,
                      )
                    : null,
              ),
            ),
            if (!hideText) ...[
              const SizedBox(width: 5),
              if (flag.isMajorFlag) ...[
                const Icon(
                  Icons.auto_awesome_rounded,
                  size: 11,
                  color: Color(0xFFFEF08A),
                ),
                const SizedBox(width: 3),
              ],
              Flexible(
                child: Text(
                  flag.placeName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    color: flag.isMajorFlag
                        ? const Color(0xFFFEF3C7)
                        : (_isDarkTheme
                            ? Colors.white
                            : TeritoryColors.textPrimary),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Pin for Friend's Flagged locations
  Widget _buildFriendFlagPin(ApiFlag flag) {
    final pinBg = _isDarkTheme ? const Color(0xF51E293B) : Colors.white;
    final themeColor = FlagStyleCatalog.primaryColor(flag.flagStyle);
    final pinBorder = flag.isMajorFlag ? TeritoryColors.majorGold : themeColor;
    final hideText = _currentZoom < 10.5;

    return _buildPlantedFlagPin(
      style: flag.flagStyle,
      anchorColor: pinBorder,
      isMajor: flag.isMajorFlag,
      badge: Container(
        padding: hideText
            ? const EdgeInsets.all(2.5)
            : const EdgeInsets.fromLTRB(3, 3, 9, 3),
        decoration: BoxDecoration(
          gradient: flag.isMajorFlag
              ? const LinearGradient(
                  colors: [Color(0xFFFFFBEB), Color(0xFFFEF3C7)],
                )
              : null,
          color: flag.isMajorFlag ? null : pinBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: pinBorder.withValues(alpha: flag.isMajorFlag ? 1.0 : 0.78),
            width: flag.isMajorFlag ? 1.7 : 1.3,
          ),
          boxShadow: [
            BoxShadow(
              color: flag.isMajorFlag
                  ? TeritoryColors.majorGold.withValues(alpha: 0.42)
                  : Colors.black.withValues(alpha: 0.18),
              blurRadius: flag.isMajorFlag ? 10 : 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(1.3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: pinBorder, width: 1.4),
              ),
              child: CircleAvatar(
                radius: 8.5,
                backgroundColor: TeritoryColors.surfaceContainer,
                backgroundImage: flag.authorAvatar.isNotEmpty
                    ? NetworkImage(flag.authorAvatar)
                    : null,
                child: flag.authorAvatar.isEmpty
                    ? const Icon(
                        Icons.person_rounded,
                        size: 11,
                        color: Colors.white,
                      )
                    : null,
              ),
            ),
            if (!hideText) ...[
              const SizedBox(width: 5),
              if (flag.isMajorFlag) ...[
                const Icon(
                  Icons.auto_awesome_rounded,
                  size: 11,
                  color: TeritoryColors.majorGoldDark,
                ),
                const SizedBox(width: 3),
              ],
              Flexible(
                child: Text(
                  flag.authorName.split(' ').first,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: flag.isMajorFlag
                        ? const Color(0xFF92400E)
                        : (_isDarkTheme
                            ? Colors.white
                            : TeritoryColors.textPrimary),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Detects a quick tap vs a 2-second deep-hold press on a map marker, showing
/// a subtle charging ring while holding and firing [onDeepHold] at 2 seconds.
class _DeepHoldMarker extends StatefulWidget {
  final VoidCallback onTap;
  final VoidCallback onDeepHold;
  final Widget child;

  const _DeepHoldMarker({
    required this.onTap,
    required this.onDeepHold,
    required this.child,
  });

  @override
  State<_DeepHoldMarker> createState() => _DeepHoldMarkerState();
}

class _DeepHoldMarkerState extends State<_DeepHoldMarker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _holdController;
  Timer? _indicatorDelay;
  Offset? _downPosition;
  int? _activePointer;
  bool _showRing = false;
  bool _triggered = false;

  @override
  void initState() {
    super.initState();
    _holdController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed && !_triggered) {
          _triggered = true;
          _cancelHold(resetTriggered: false);
          HapticFeedback.mediumImpact();
          widget.onDeepHold();
        }
      });
  }

  void _startHold(PointerDownEvent event) {
    _activePointer = event.pointer;
    _downPosition = event.position;
    _triggered = false;
    _holdController.forward(from: 0);
    _indicatorDelay?.cancel();
    _indicatorDelay = Timer(const Duration(milliseconds: 120), () {
      if (mounted && _holdController.isAnimating) {
        setState(() => _showRing = true);
      }
    });
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (event.pointer != _activePointer || _downPosition == null) return;
    // Allow natural finger micro-drift (<= 18px) without cancelling the hold.
    if ((event.position - _downPosition!).distance > 18.0) {
      _cancelHold();
    }
  }

  void _cancelHold({bool resetTriggered = true}) {
    _indicatorDelay?.cancel();
    _activePointer = null;
    _downPosition = null;
    _holdController.stop();
    _holdController.value = 0;
    if (resetTriggered) _triggered = false;
    if (_showRing && mounted) setState(() => _showRing = false);
  }

  @override
  void dispose() {
    _indicatorDelay?.cancel();
    _holdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: _startHold,
      onPointerMove: _onPointerMove,
      onPointerUp: (e) {
        if (e.pointer == _activePointer) _cancelHold();
      },
      onPointerCancel: (e) {
        if (e.pointer == _activePointer) _cancelHold();
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (!_triggered) widget.onTap();
        },
        onLongPress: () {
          if (!_triggered && _holdController.isAnimating) {
            // Keep charging via Listener; don't let map steal long-press.
          }
        },
        child: Stack(
          alignment: Alignment.bottomCenter,
          clipBehavior: Clip.none,
          children: [
            widget.child,
            if (_showRing)
              Positioned(
                bottom: -2,
                child: AnimatedBuilder(
                  animation: _holdController,
                  builder: (_, _) => SizedBox(
                    width: 30,
                    height: 30,
                    child: CircularProgressIndicator(
                      value: _holdController.value,
                      strokeWidth: 3.2,
                      color: TeritoryColors.majorGold,
                      backgroundColor: Colors.white.withValues(alpha: 0.55),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Small floating banner used for loading / error / empty states over the map.
class _MapStatusBanner extends StatelessWidget {
  final IconData icon;
  final String message;
  final Color color;
  final VoidCallback? onRetry;

  const _MapStatusBanner({
    required this.icon,
    required this.message,
    required this.color,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    // Right inset clears the map's FAB column (right: 16, bottom: 160) so the
    // banner and its Retry button never sit under those buttons.
    return Positioned(
      left: 16,
      right: 72,
      bottom: 160,
      child: Material(
        color: Colors.white,
        elevation: 3,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: TeritoryColors.textPrimary,
                  ),
                ),
              ),
              if (onRetry != null)
                TextButton(
                  onPressed: onRetry,
                  child: Text(
                    'Retry',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
