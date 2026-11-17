import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/models/api_flag.dart';
import '../../../core/models/api_user.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/teritory_repository.dart';
import '../../../core/theme/teritory_theme.dart';
import '../../flag/presentation/live_flag_detail_sheet.dart';
import '../application/profile_providers.dart';

/// Live public profile: `GET /users/:userId` plus `GET /flags?userId=` for the
/// footprint, with real friend actions against the relationship endpoints.
class FriendProfileScreen extends ConsumerStatefulWidget {
  final String userId;

  const FriendProfileScreen({super.key, required this.userId});

  @override
  ConsumerState<FriendProfileScreen> createState() =>
      _FriendProfileScreenState();
}

class _FriendProfileScreenState extends ConsumerState<FriendProfileScreen> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
      ref.invalidate(friendsLiveProvider);
      ref.invalidate(friendRequestsLiveProvider);
      ref.invalidate(userProfileProvider(widget.userId));
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider(widget.userId));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          profileAsync.valueOrNull?.displayName ?? 'Profile',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: profileAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: TeritoryColors.primary),
        ),
        error: (error, _) => _MessageState(
          message: error is ApiException
              ? error.message
              : 'Could not load this traveler.',
          actionLabel: 'Retry',
          onAction: () => ref.invalidate(userProfileProvider(widget.userId)),
        ),
        data: (profile) {
          final flagsAsync = ref.watch(userFlagsProvider(profile.id));
          return RefreshIndicator(
            color: TeritoryColors.primary,
            onRefresh: () async {
              ref.invalidate(userProfileProvider(widget.userId));
              ref.invalidate(userFlagsProvider(profile.id));
              try {
                await ref.read(userProfileProvider(widget.userId).future);
              } on ApiException {
                // The error state renders the message.
              }
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 32),
              children: [
                _Header(profile: profile),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _FriendActionRow(
                    profile: profile,
                    busy: _busy,
                    onAdd: () => _run(() async {
                      await TeritoryRepository.instance
                          .sendFriendRequest(profile.id);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Friend request sent')),
                      );
                    }),
                    onAccept: (relationshipId) => _run(() async {
                      await TeritoryRepository.instance
                          .respondToFriendRequest(relationshipId, accept: true);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Friend request accepted')),
                      );
                    }),
                    onRemove: (relationshipId) => _run(() async {
                      await TeritoryRepository.instance
                          .removeFriend(relationshipId);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Friend removed')),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 18),
                _StatsRow(profile: profile),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.map_rounded,
                          size: 18, color: TeritoryColors.textPrimary),
                      const SizedBox(width: 6),
                      Text(
                        'Flag Map',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: TeritoryColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: flagsAsync.when(
                    loading: () => const SizedBox(
                      height: 220,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (error, _) => SizedBox(
                      height: 220,
                      child: Center(
                        child: Text(
                          error is ApiException
                              ? error.message
                              : 'Could not load this traveler\'s flags.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: TeritoryColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    data: (flags) => _FootprintMap(flags: flags),
                  ),
                ),
                if (profile.passportStamps.isNotEmpty) ...[
                  const SizedBox(height: 22),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Passport Stamps (${profile.passportStamps.length})',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: TeritoryColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 78,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      itemCount: profile.passportStamps.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        final stamp = profile.passportStamps[index];
                        return Container(
                          width: 150,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: TeritoryColors.majorGold
                                  .withValues(alpha: 0.5),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                stamp.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: TeritoryColors.textPrimary,
                                ),
                              ),
                              Text(
                                '${stamp.category} • ${stamp.date}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 9,
                                  color: TeritoryColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 22),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Flags',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: TeritoryColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                flagsAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                  data: (flags) {
                    if (flags.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'No flags dropped yet.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: TeritoryColors.textMuted,
                          ),
                        ),
                      );
                    }
                    return Column(
                      children: [
                        for (final flag in flags)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                            child: _FlagRow(
                              flag: flag,
                              onTap: () =>
                                  LiveFlagDetailSheet.show(context, flag: flag),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.profile});

  final ApiUser profile;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        children: [
          CircleAvatar(
            radius: 48,
            backgroundColor: TeritoryColors.surfaceContainer,
            backgroundImage: profile.avatarUrl.isNotEmpty
                ? NetworkImage(profile.avatarUrl)
                : null,
            child: profile.avatarUrl.isEmpty
                ? const Icon(Icons.person_rounded,
                    size: 44, color: TeritoryColors.textMuted)
                : null,
          ),
          const SizedBox(height: 12),
          Text(
            profile.displayName,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: TeritoryColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '@${profile.handle}',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: TeritoryColors.textSecondary,
            ),
          ),
          if (profile.locationLabel.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              profile.locationLabel,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: TeritoryColors.textMuted,
              ),
            ),
          ],
          if (profile.bio.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              profile.bio,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: TeritoryColors.textPrimary,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Resolves the relationship state from the live friend/request lists and
/// renders exactly one honest action.
class _FriendActionRow extends ConsumerWidget {
  const _FriendActionRow({
    required this.profile,
    required this.busy,
    required this.onAdd,
    required this.onAccept,
    required this.onRemove,
  });

  final ApiUser profile;
  final bool busy;
  final VoidCallback onAdd;
  final ValueChanged<String> onAccept;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friends = ref.watch(friendsLiveProvider).valueOrNull;
    final requests = ref.watch(friendRequestsLiveProvider).valueOrNull;

    Widget child(String label, VoidCallback? onPressed,
        {bool outlined = false, IconData icon = Icons.person_add_rounded}) {
      final button = outlined
          ? OutlinedButton.icon(
              onPressed: busy ? null : onPressed,
              icon: Icon(icon, size: 18),
              label: Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: TeritoryColors.textPrimary,
                side: const BorderSide(color: TeritoryColors.border),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            )
          : ElevatedButton.icon(
              onPressed: busy ? null : onPressed,
              icon: Icon(icon, size: 18),
              label: Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: TeritoryColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            );

      return SizedBox(width: double.infinity, child: button);
    }

    if (friends == null || requests == null) {
      return busy
          ? const Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          : child('Loading relationship…', null, outlined: true);
    }

    for (final friend in friends) {
      if (friend.user.id == profile.id) {
        return child(
          'Remove friend',
          () => onRemove(friend.relationshipId),
          outlined: true,
          icon: Icons.person_remove_rounded,
        );
      }
    }

    for (final request in requests.incoming) {
      if (request.user.id == profile.id) {
        return child(
          'Accept friend request',
          () => onAccept(request.relationshipId),
          icon: Icons.how_to_reg_rounded,
        );
      }
    }

    for (final request in requests.outgoing) {
      if (request.user.id == profile.id) {
        return child('Request pending', null, outlined: true,
            icon: Icons.hourglass_top_rounded);
      }
    }

    return child('Add Friend', onAdd);
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.profile});

  final ApiUser profile;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _stat('${profile.totalFlags}', 'Flags'),
          _stat('${profile.majorFlags}', 'Major'),
          _stat('${profile.countriesVisited}', 'Countries'),
          _stat('${profile.continentsVisited}', 'Continents'),
          _stat('${profile.completedTripsCount}', 'Trips'),
        ],
      ),
    );
  }

  Widget _stat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: TeritoryColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: TeritoryColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _FootprintMap extends StatelessWidget {
  const _FootprintMap({required this.flags});

  final List<ApiFlag> flags;

  @override
  Widget build(BuildContext context) {
    final center = flags.isNotEmpty
        ? flags.first.coordinates
        : const LatLng(10.0889, 77.0595);

    return Container(
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: TeritoryColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            FlutterMap(
              options: MapOptions(initialCenter: center, initialZoom: 6.0),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.onway.teritory',
                  tileBuilder: (context, tileWidget, tile) => ColorFiltered(
                    colorFilter: const ColorFilter.matrix(<double>[
                      -0.20, -0.15, -0.30, 0.0, 140,
                      -0.45, 0.20, -0.35, 0.0, 165,
                      -0.55, 0.05, -0.05, 0.0, 185,
                      0.0, 0.0, 0.0, 1.0, 0,
                    ]),
                    child: tileWidget,
                  ),
                ),
                MarkerLayer(
                  markers: flags.map((flag) {
                    return Marker(
                      point: flag.coordinates,
                      width: 28,
                      height: 28,
                      child: GestureDetector(
                        onTap: () =>
                            LiveFlagDetailSheet.show(context, flag: flag),
                        child: Container(
                          decoration: BoxDecoration(
                            color: flag.isMajorFlag
                                ? TeritoryColors.majorGold
                                : TeritoryColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Icon(
                            flag.isMajorFlag
                                ? Icons.military_tech_rounded
                                : Icons.flag_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
            if (flags.isEmpty)
              const Center(
                child: Text(
                  'No flags on the map yet',
                  style: TextStyle(color: TeritoryColors.textSecondary),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FlagRow extends StatelessWidget {
  const _FlagRow({required this.flag, required this.onTap});

  final ApiFlag flag;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final location = [flag.city, flag.country]
        .where((part) => part.trim().isNotEmpty)
        .join(', ');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: TeritoryColors.border),
        ),
        child: Row(
          children: [
            Icon(
              flag.isMajorFlag
                  ? Icons.military_tech_rounded
                  : Icons.flag_rounded,
              color: flag.isMajorFlag
                  ? TeritoryColors.majorGold
                  : TeritoryColors.primary,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    flag.placeName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: TeritoryColors.textPrimary,
                    ),
                  ),
                  Text(
                    location.isEmpty ? flag.continent : location,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: TeritoryColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              flag.category,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                color: TeritoryColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person_off_outlined,
                size: 52, color: TeritoryColors.textMuted),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: TeritoryColors.textSecondary,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 14),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
