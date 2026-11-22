import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/models/api_flag.dart';
import '../../../core/models/api_user.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/teritory_repository.dart';
import '../../../core/theme/teritory_theme.dart';
import '../../flag/presentation/live_flag_detail_sheet.dart';
import '../application/profile_providers.dart';
import 'edit_profile_sheet.dart';
import 'worldwide_flag_map_screen.dart';

/// Live detailed traveler profile screen:
/// - Profile details & explorer credentials
/// - Live friend request actions (send, cancel, accept, remove)
/// - Mutual connections (shared friends)
/// - Mutual explored areas (shared countries & territories)
/// - Clans & expedition fleets
/// - Interactive OpenStreetMap with staked flags
/// - Passport stamps & verified seals
/// - Complete flagged places list
class FriendProfileScreen extends ConsumerStatefulWidget {
  final String userId;

  const FriendProfileScreen({super.key, required this.userId});

  /// Navigates to a traveler's profile from any page in the app.
  static void open(BuildContext context, {required String userId}) {
    context.push('/user/$userId');
  }

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
    final currentUser = ref.watch(currentUserProvider);
    final isMe = currentUser.id == widget.userId;

    return Scaffold(
      backgroundColor: TeritoryColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: TeritoryColors.textPrimary,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          profileAsync.valueOrNull?.displayName ?? 'Traveler Profile',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: TeritoryColors.textPrimary,
          ),
        ),
        centerTitle: true,
        actions: [
          if (isMe)
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              tooltip: 'Edit Profile',
              onPressed: () {
                final user = profileAsync.valueOrNull;
                if (user != null) {
                  EditProfileSheet.show(context, user).then((_) {
                    ref.invalidate(userProfileProvider(widget.userId));
                    ref.invalidate(myProfileProvider);
                  });
                }
              },
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: TeritoryColors.border),
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
          final myFlagsAsync = isMe
              ? null
              : ref.watch(userFlagsProvider(currentUser.id));

          // Compute mutual explored areas fallback if backend doesn't have it
          final mutualAreas = _resolveMutualAreas(
            profile.mutualExploredAreas,
            myFlags: myFlagsAsync?.valueOrNull ?? const [],
            targetFlags: flagsAsync.valueOrNull ?? const [],
            isMe: isMe,
          );

          return RefreshIndicator(
            color: TeritoryColors.primary,
            onRefresh: () async {
              ref.invalidate(userProfileProvider(widget.userId));
              ref.invalidate(userFlagsProvider(profile.id));
              ref.invalidate(friendsLiveProvider);
              ref.invalidate(friendRequestsLiveProvider);
              try {
                await ref.read(userProfileProvider(widget.userId).future);
              } on ApiException {
                // Error state handles it
              }
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 40),
              children: [
                // 1. Header Banner & Identity
                _ProfileHeader(profile: profile, isMe: isMe),
                const SizedBox(height: 14),

                // 2. Friend Relationship / Action Bar (if not viewing self)
                if (!isMe) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _FriendActionBar(
                      profile: profile,
                      busy: _busy,
                      onAdd: () => _run(() async {
                        await TeritoryRepository.instance
                            .sendFriendRequest(profile.id);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Friend request sent!'),
                            backgroundColor: TeritoryColors.emeraldGreen,
                          ),
                        );
                      }),
                      onCancel: (relationshipId) => _run(() async {
                        await TeritoryRepository.instance
                            .cancelFriendRequest(relationshipId);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Friend request cancelled'),
                          ),
                        );
                      }),
                      onAccept: (relationshipId) => _run(() async {
                        await TeritoryRepository.instance
                            .respondToFriendRequest(relationshipId,
                                accept: true);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Friend request accepted!'),
                            backgroundColor: TeritoryColors.emeraldGreen,
                          ),
                        );
                      }),
                      onRemove: (relationshipId) => _confirmRemoveFriend(
                        context,
                        profile.displayName,
                        () => _run(() async {
                          await TeritoryRepository.instance
                              .removeFriend(relationshipId);
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Friend removed')),
                          );
                        }),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // 3. Expedition Telemetry Stats
                _ExpeditionStatsGrid(profile: profile),
                const SizedBox(height: 18),

                // 4. Mutual Connections (Mutual Friends)
                if (!isMe && profile.mutualFriends.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _MutualFriendsSection(
                      mutualFriends: profile.mutualFriends,
                    ),
                  ),
                  const SizedBox(height: 18),
                ],

                // 5. Mutual Explored Areas (Shared Territories)
                if (!isMe && mutualAreas.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _MutualExploredAreasSection(
                      targetName: profile.displayName,
                      areas: mutualAreas,
                    ),
                  ),
                  const SizedBox(height: 18),
                ],

                // 6. Clans & Fleets
                if (profile.clans.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _ClansSection(clans: profile.clans),
                  ),
                  const SizedBox(height: 18),
                ],

                // 7. Interactive Flag Footprint Map
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.map_rounded,
                        size: 18,
                        color: TeritoryColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Flag Footprint Map',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: TeritoryColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      flagsAsync.when(
                        loading: () => const SizedBox.shrink(),
                        error: (_, _) => const SizedBox.shrink(),
                        data: (flags) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: TeritoryColors.surfaceContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${flags.length} Staked',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: TeritoryColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: flagsAsync.when(
                    loading: () => const SizedBox(
                      height: 220,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: TeritoryColors.primary,
                        ),
                      ),
                    ),
                    error: (error, _) => SizedBox(
                      height: 140,
                      child: Center(
                        child: Text(
                          error is ApiException
                              ? error.message
                              : 'Could not load flag coordinates.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: TeritoryColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    data: (flags) => _FootprintMap(flags: flags),
                  ),
                ),
                const SizedBox(height: 20),

                // 8. Passport Stamps & Expedition Seals
                if (profile.passportStamps.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.verified_rounded,
                          size: 18,
                          color: TeritoryColors.majorGold,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Passport Stamps (${profile.passportStamps.length})',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: TeritoryColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 84,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      itemCount: profile.passportStamps.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        final stamp = profile.passportStamps[index];
                        return _PassportStampCard(stamp: stamp);
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // 9. Staked Flags List
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.flag_rounded,
                        size: 18,
                        color: TeritoryColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Expedition Flags',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: TeritoryColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                flagsAsync.when(
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(
                        color: TeritoryColors.primary,
                      ),
                    ),
                  ),
                  error: (_, _) => const SizedBox.shrink(),
                  data: (flags) {
                    if (flags.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Text(
                          'No flags staked yet.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
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
                              onTap: () => LiveFlagDetailSheet.show(
                                context,
                                flag: flag,
                              ),
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

  void _confirmRemoveFriend(
      BuildContext context, String friendName, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Remove Friend?',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
        content: Text(
          'Are you sure you want to remove $friendName from your friends?',
          style: GoogleFonts.plusJakartaSans(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: TeritoryColors.expiredRed,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              onConfirm();
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  ApiMutualExploredAreas _resolveMutualAreas(
    ApiMutualExploredAreas? backendAreas, {
    required List<ApiFlag> myFlags,
    required List<ApiFlag> targetFlags,
    required bool isMe,
  }) {
    if (isMe) return const ApiMutualExploredAreas();
    if (backendAreas != null && backendAreas.isNotEmpty) return backendAreas;

    if (myFlags.isEmpty || targetFlags.isEmpty) {
      return const ApiMutualExploredAreas();
    }

    final myCountries =
        myFlags.map((f) => f.country.trim()).where((s) => s.isNotEmpty).toSet();
    final targetCountries = targetFlags
        .map((f) => f.country.trim())
        .where((s) => s.isNotEmpty)
        .toSet();
    final commonCountries =
        myCountries.intersection(targetCountries).toList()..sort();

    final myStates =
        myFlags.map((f) => f.city.trim()).where((s) => s.isNotEmpty).toSet();
    final targetStates =
        targetFlags.map((f) => f.city.trim()).where((s) => s.isNotEmpty).toSet();
    final commonStates =
        myStates.intersection(targetStates).toList()..sort();

    final myContinents = myFlags
        .map((f) => f.continent.trim())
        .where((s) => s.isNotEmpty)
        .toSet();
    final targetContinents = targetFlags
        .map((f) => f.continent.trim())
        .where((s) => s.isNotEmpty)
        .toSet();
    final commonContinents =
        myContinents.intersection(targetContinents).toList()..sort();

    return ApiMutualExploredAreas(
      commonCountries: commonCountries,
      commonStates: commonStates,
      commonContinents: commonContinents,
    );
  }
}

// ─── Profile Header Banner ───────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.profile, required this.isMe});

  final ApiUser profile;
  final bool isMe;

  String _deriveTitle(ApiUser u) {
    if (u.majorFlags >= 5) return '🏛️ Wonder Surveyor';
    if (u.continentsVisited >= 3) return '🌍 Continental Nomad';
    if (u.totalFlags >= 25) return '🚩 Master Cartographer';
    if (u.completedTripsCount >= 5) return '🧭 Highland Pioneer';
    return '🏕️ Pathfinder';
  }

  @override
  Widget build(BuildContext context) {
    final title = _deriveTitle(profile);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: TeritoryColors.border)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      child: Column(
        children: [
          // Avatar
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: profile.majorFlags > 0
                        ? TeritoryColors.majorGold
                        : TeritoryColors.primary,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 46,
                  backgroundColor: TeritoryColors.surfaceContainer,
                  backgroundImage: profile.avatarUrl.isNotEmpty
                      ? NetworkImage(profile.avatarUrl)
                      : null,
                  child: profile.avatarUrl.isEmpty
                      ? Text(
                          profile.displayName.isEmpty
                              ? '?'
                              : profile.displayName[0].toUpperCase(),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            color: TeritoryColors.textSecondary,
                          ),
                        )
                      : null,
                ),
              ),
              if (profile.majorFlags > 0)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: TeritoryColors.majorGold,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.military_tech_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Name and Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  profile.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: TeritoryColors.textPrimary,
                  ),
                ),
              ),
              if (isMe) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: TeritoryColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'YOU',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: TeritoryColors.primary,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 3),

          // Handle
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: '@${profile.handle}'));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Copied @${profile.handle} to clipboard'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '@${profile.handle}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: TeritoryColors.primary,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.copy_rounded,
                  size: 12,
                  color: TeritoryColors.textMuted,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Explorer Title Chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: TeritoryColors.surfaceContainer,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: TeritoryColors.border),
            ),
            child: Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: TeritoryColors.textPrimary,
              ),
            ),
          ),

          if (profile.locationLabel.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.place_rounded,
                  size: 14,
                  color: TeritoryColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  profile.locationLabel,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: TeritoryColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],

          if (profile.bio.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                profile.bio,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  height: 1.4,
                  color: TeritoryColors.textPrimary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Friend Action Bar ───────────────────────────────────────────────────────

class _FriendActionBar extends ConsumerWidget {
  const _FriendActionBar({
    required this.profile,
    required this.busy,
    required this.onAdd,
    required this.onCancel,
    required this.onAccept,
    required this.onRemove,
  });

  final ApiUser profile;
  final bool busy;
  final VoidCallback onAdd;
  final ValueChanged<String> onCancel;
  final ValueChanged<String> onAccept;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Check live providers for freshest local client state
    final friends = ref.watch(friendsLiveProvider).valueOrNull;
    final requests = ref.watch(friendRequestsLiveProvider).valueOrNull;

    if (busy) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: TeritoryColors.primary,
            ),
          ),
        ),
      );
    }

    // A. Check if already friends
    String? friendRelationshipId;
    if (friends != null) {
      for (final f in friends) {
        if (f.user.id == profile.id) {
          friendRelationshipId = f.relationshipId;
          break;
        }
      }
    } else if (profile.relationship?.isFriends == true) {
      friendRelationshipId = profile.relationship?.relationshipId;
    }

    if (friendRelationshipId != null) {
      return Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: TeritoryColors.emeraldGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: TeritoryColors.emeraldGreen.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 18,
                    color: TeritoryColors.emeraldGreen,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Friends on Teritory',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: TeritoryColors.emeraldGreen,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          OutlinedButton(
            onPressed: () => onRemove(friendRelationshipId!),
            style: OutlinedButton.styleFrom(
              foregroundColor: TeritoryColors.expiredRed,
              side: const BorderSide(color: TeritoryColors.border),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Icon(Icons.person_remove_rounded, size: 18),
          ),
        ],
      );
    }

    // B. Check if incoming request received from this user
    String? incomingRequestId;
    if (requests != null) {
      for (final r in requests.incoming) {
        if (r.user.id == profile.id) {
          incomingRequestId = r.relationshipId;
          break;
        }
      }
    } else if (profile.relationship?.isRequestReceived == true) {
      incomingRequestId = profile.relationship?.relationshipId;
    }

    if (incomingRequestId != null) {
      return Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: TeritoryColors.rallyGold.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.handshake_rounded,
                  size: 16,
                  color: TeritoryColors.majorGoldDark,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${profile.displayName} sent you a friend request!',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: TeritoryColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => onAccept(incomingRequestId!),
                  icon: const Icon(Icons.how_to_reg_rounded, size: 18),
                  label: const Text('Accept Friend Request'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TeritoryColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    }

    // C. Check if request sent by me to this user (Pending)
    String? outgoingRequestId;
    if (requests != null) {
      for (final r in requests.outgoing) {
        if (r.user.id == profile.id) {
          outgoingRequestId = r.relationshipId;
          break;
        }
      }
    } else if (profile.relationship?.isRequestSent == true) {
      outgoingRequestId = profile.relationship?.relationshipId;
    }

    if (outgoingRequestId != null) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: null,
              icon: const Icon(Icons.hourglass_top_rounded, size: 18),
              label: const Text('Friend Request Pending'),
              style: OutlinedButton.styleFrom(
                disabledForegroundColor: TeritoryColors.textSecondary,
                side: const BorderSide(color: TeritoryColors.border),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          OutlinedButton(
            onPressed: () => onCancel(outgoingRequestId!),
            style: OutlinedButton.styleFrom(
              foregroundColor: TeritoryColors.textSecondary,
              side: const BorderSide(color: TeritoryColors.border),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text('Cancel'),
          ),
        ],
      );
    }

    // D. Not friends: Show Add Friend CTA
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onAdd,
        icon: const Icon(Icons.person_add_rounded, size: 18),
        label: Text(
          'Send Friend Request',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: TeritoryColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 2,
          shadowColor: TeritoryColors.primary.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}

// ─── Expedition Telemetry Stats Grid ─────────────────────────────────────────

class _ExpeditionStatsGrid extends StatelessWidget {
  const _ExpeditionStatsGrid({required this.profile});

  final ApiUser profile;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: TeritoryColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _statItem(
                icon: Icons.flag_rounded,
                color: TeritoryColors.primary,
                value: '${profile.totalFlags}',
                label: 'Flags Staked',
              ),
              _verticalDivider(),
              _statItem(
                icon: Icons.military_tech_rounded,
                color: TeritoryColors.majorGold,
                value: '${profile.majorFlags}',
                label: 'World Wonders',
              ),
              _verticalDivider(),
              _statItem(
                icon: Icons.public_rounded,
                color: TeritoryColors.sapphireBlue,
                value: '${profile.countriesVisited}',
                label: 'Nations',
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: TeritoryColors.border),
          const SizedBox(height: 12),
          Row(
            children: [
              _statItem(
                icon: Icons.explore_rounded,
                color: TeritoryColors.communityIndigo,
                value: '${profile.continentsVisited}',
                label: 'Continents',
              ),
              _verticalDivider(),
              _statItem(
                icon: Icons.route_rounded,
                color: TeritoryColors.emeraldGreen,
                value: '${profile.completedTripsCount}',
                label: 'Treks Logged',
              ),
              _verticalDivider(),
              _statItem(
                icon: Icons.bolt_rounded,
                color: TeritoryColors.rallyGold,
                value: '${profile.legendaryRalliesCount}',
                label: 'Rallies',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statItem({
    required IconData icon,
    required Color color,
    required String value,
    required String label,
  }) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(
                value,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: TeritoryColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: TeritoryColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _verticalDivider() {
    return Container(
      width: 1,
      height: 32,
      color: TeritoryColors.border,
    );
  }
}

// ─── Mutual Friends Section ──────────────────────────────────────────────────

class _MutualFriendsSection extends StatelessWidget {
  const _MutualFriendsSection({required this.mutualFriends});

  final List<ApiMutualFriend> mutualFriends;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TeritoryColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.people_alt_rounded,
                size: 16,
                color: TeritoryColors.communityIndigo,
              ),
              const SizedBox(width: 8),
              Text(
                'MUTUAL CONNECTIONS (${mutualFriends.length})',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: TeritoryColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 60,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: mutualFriends.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final friend = mutualFriends[index];
                return GestureDetector(
                  onTap: () => FriendProfileScreen.open(
                    context,
                    userId: friend.id,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: TeritoryColors.surfaceContainer,
                        backgroundImage: friend.avatarUrl.isNotEmpty
                            ? NetworkImage(friend.avatarUrl)
                            : null,
                        child: friend.avatarUrl.isEmpty
                            ? Text(
                                friend.displayName.isEmpty
                                    ? '?'
                                    : friend.displayName[0].toUpperCase(),
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            friend.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: TeritoryColors.textPrimary,
                            ),
                          ),
                          Text(
                            '@${friend.handle}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10.5,
                              color: TeritoryColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Mutual Explored Areas Section ───────────────────────────────────────────

class _MutualExploredAreasSection extends StatelessWidget {
  const _MutualExploredAreasSection({
    required this.targetName,
    required this.areas,
  });

  final String targetName;
  final ApiMutualExploredAreas areas;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TeritoryColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.travel_explore_rounded,
                size: 16,
                color: TeritoryColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'SHARED EXPLORED FRONTIERS',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: TeritoryColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Territories both you and $targetName have flagged',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: TeritoryColors.textMuted,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              for (final country in areas.commonCountries)
                _territoryChip(
                  icon: Icons.flag_rounded,
                  label: country,
                  color: TeritoryColors.primary,
                ),
              for (final state in areas.commonStates)
                _territoryChip(
                  icon: Icons.terrain_rounded,
                  label: state,
                  color: TeritoryColors.communityIndigo,
                ),
              for (final continent in areas.commonContinents)
                _territoryChip(
                  icon: Icons.public_rounded,
                  label: continent,
                  color: TeritoryColors.sapphireBlue,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _territoryChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Clans & Fleets Section ──────────────────────────────────────────────────

class _ClansSection extends StatelessWidget {
  const _ClansSection({required this.clans});

  final List<ApiUserClan> clans;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TeritoryColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.shield_rounded,
                size: 16,
                color: TeritoryColors.clanPurple,
              ),
              const SizedBox(width: 8),
              Text(
                'CLANS & EXPEDITION FLEETS (${clans.length})',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: TeritoryColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Column(
            children: clans.map((clan) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: TeritoryColors.clanPurple.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          clan.tag.isNotEmpty
                              ? clan.tag
                              : (clan.name.isNotEmpty
                                  ? clan.name[0].toUpperCase()
                                  : 'C'),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: TeritoryColors.clanPurple,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            clan.name,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: TeritoryColors.textPrimary,
                            ),
                          ),
                          Text(
                            '${clan.category} • ${clan.memberCount} members',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: TeritoryColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: TeritoryColors.surfaceContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        clan.role,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: TeritoryColors.clanPurple,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ─── Passport Stamp Card ─────────────────────────────────────────────────────

class _PassportStampCard extends StatelessWidget {
  const _PassportStampCard({required this.stamp});

  final ApiPassportStamp stamp;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: TeritoryColors.majorGold.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(
                Icons.star_rounded,
                size: 14,
                color: TeritoryColors.majorGold,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  stamp.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: TeritoryColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          Text(
            '${stamp.category} • ${stamp.date}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 9.5,
              color: TeritoryColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Interactive Footprint Map ───────────────────────────────────────────────

class _FootprintMap extends StatefulWidget {
  const _FootprintMap({required this.flags});

  final List<ApiFlag> flags;

  @override
  State<_FootprintMap> createState() => _FootprintMapState();
}

class _FootprintMapState extends State<_FootprintMap> {
  bool _isOceanicTheme = false;

  @override
  Widget build(BuildContext context) {
    final center = widget.flags.isNotEmpty
        ? widget.flags.first.coordinates
        : const LatLng(10.0889, 77.0595);

    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: _isOceanicTheme ? const Color(0xFF0B1120) : Colors.white,
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
              options: MapOptions(
                initialCenter: center,
                initialZoom: widget.flags.length > 1 ? 5.5 : 8.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.onway.teritory',
                  tileBuilder: _isOceanicTheme
                      ? (context, tileWidget, tile) => ColorFiltered(
                            colorFilter: const ColorFilter.matrix(<double>[
                              -0.20, -0.15, -0.30, 0.0, 140,
                              -0.45, 0.20, -0.35, 0.0, 165,
                              -0.55, 0.05, -0.05, 0.0, 185,
                              0.0, 0.0, 0.0, 1.0, 0,
                            ]),
                            child: tileWidget,
                          )
                      : null, // Default Daylight OpenStreetMap matching user profile
                ),
                MarkerLayer(
                  markers: widget.flags.map((flag) {
                    return Marker(
                      point: flag.coordinates,
                      width: 30,
                      height: 30,
                      child: GestureDetector(
                        onTap: () => LiveFlagDetailSheet.show(
                          context,
                          flag: flag,
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: flag.isMajorFlag
                                ? TeritoryColors.majorGold
                                : TeritoryColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.25),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            flag.isMajorFlag
                                ? Icons.military_tech_rounded
                                : Icons.flag_rounded,
                            color: Colors.white,
                            size: 15,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
            if (widget.flags.isEmpty)
              const Center(
                child: Text(
                  'No flags on the map yet',
                  style: TextStyle(color: TeritoryColors.textSecondary),
                ),
              ),
            // Theme selector matching ProfileScreen: Daylight (default) & Oceanic
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _themePill('☀️ Daylight', false),
                    _themePill('🌊 Oceanic', true),
                  ],
                ),
              ),
            ),
            if (widget.flags.isNotEmpty)
              Positioned(
                top: 10,
                right: 10,
                child: Material(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.82),
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => WorldwideFlagMapScreen(
                            flags: widget.flags,
                            startInLandscape: false,
                            initialOceanic: _isOceanicTheme,
                          ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.fullscreen_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Full Map',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _themePill(String label, bool isOceanic) {
    final isSelected = _isOceanicTheme == isOceanic;
    return GestureDetector(
      onTap: () => setState(() => _isOceanicTheme = isOceanic),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F172A) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected
                ? (isOceanic
                    ? const Color(0xFF38BDF8)
                    : const Color(0xFFF59E0B))
                : TeritoryColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ─── Flag List Tile ──────────────────────────────────────────────────────────

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
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: flag.isMajorFlag
                    ? TeritoryColors.majorGold.withValues(alpha: 0.12)
                    : TeritoryColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                flag.isMajorFlag
                    ? Icons.military_tech_rounded
                    : Icons.flag_rounded,
                color: flag.isMajorFlag
                    ? TeritoryColors.majorGoldDark
                    : TeritoryColors.primary,
                size: 18,
              ),
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

// ─── Error / Empty State ─────────────────────────────────────────────────────

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
            const Icon(
              Icons.person_off_outlined,
              size: 52,
              color: TeritoryColors.textMuted,
            ),
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
