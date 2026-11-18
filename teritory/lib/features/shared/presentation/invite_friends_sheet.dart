import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/models/api_user.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/teritory_repository.dart';
import '../../../core/theme/teritory_theme.dart';
import '../../profile/application/profile_providers.dart';

/// What the invitation is for. The API speaks `CLAN` / `COMMUNITY` / `TRIP` /
/// `RALLY`; the matching notification type and deep link are built server-side.
enum InviteTargetType {
  clan,
  community,
  trip,
  rally;

  String get apiType => name.toUpperCase();
}

/// Live friend picker used by every invite surface.
///
/// Friends come from `GET /users/friends` (live-only, no mock rows) and sending
/// posts `POST /users/invites` with the target's `type` and `targetId`, which is
/// what makes the invitee's notification deep-link correctly.
///
/// Completes with the number of invitations the server accepted, or `null` when
/// dismissed.
class InviteFriendsSheet extends ConsumerStatefulWidget {
  const InviteFriendsSheet({
    super.key,
    required this.targetType,
    required this.targetName,
    this.targetId,
    this.excludeUserIds = const {},
    this.title,
    this.message,
  });

  final InviteTargetType targetType;
  final String targetName;
  final String? targetId;

  /// People who already have access (members/participants) so the picker does
  /// not offer a pointless invite.
  final Set<String> excludeUserIds;

  /// Optional custom copy forwarded to the notification.
  final String? title;
  final String? message;

  static Future<int?> show(
    BuildContext context, {
    required InviteTargetType targetType,
    required String targetName,
    String? targetId,
    Set<String> excludeUserIds = const {},
    String? title,
    String? message,
  }) {
    return showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => InviteFriendsSheet(
        targetType: targetType,
        targetName: targetName,
        targetId: targetId,
        excludeUserIds: excludeUserIds,
        title: title,
        message: message,
      ),
    );
  }

  @override
  ConsumerState<InviteFriendsSheet> createState() => _InviteFriendsSheetState();
}

class _InviteFriendsSheetState extends ConsumerState<InviteFriendsSheet> {
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _selected = {};
  String _query = '';
  bool _sending = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ApiFriend> _visible(List<ApiFriend> friends) {
    final query = _query.trim().toLowerCase();
    return friends.where((friend) {
      if (widget.excludeUserIds.contains(friend.user.id)) return false;
      if (query.isEmpty) return true;
      return friend.user.displayName.toLowerCase().contains(query) ||
          friend.user.handle.toLowerCase().contains(query);
    }).toList();
  }

  Future<void> _send() async {
    if (_selected.isEmpty || _sending) return;
    setState(() => _sending = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final count = await TeritoryRepository.instance.sendInvites(
        userIds: _selected.toList(),
        type: widget.targetType.apiType,
        targetId: widget.targetId,
        title: widget.title,
        message: widget.message,
      );
      if (!mounted) return;
      Navigator.pop(context, count);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _sending = false);
      messenger.showSnackBar(
        SnackBar(
          content: Text(error.message),
          backgroundColor: TeritoryColors.expiredRed,
        ),
      );
    } catch (_) {
      // Network/timeout failures arrive as non-ApiException errors; without this
      // the button would stay disabled and the sheet would look stuck.
      if (!mounted) return;
      setState(() => _sending = false);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Could not send invitations. Check your connection.'),
          backgroundColor: TeritoryColors.expiredRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final friendsAsync = ref.watch(friendsLiveProvider);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.78,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Invite friends',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: TeritoryColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Invitees get a notification for ${widget.targetName}.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: TeritoryColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value),
              style: GoogleFonts.plusJakartaSans(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search friends...',
                hintStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: TeritoryColors.textMuted,
                ),
                filled: true,
                fillColor: TeritoryColors.surfaceContainer,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: TeritoryColors.textSecondary,
                  size: 20,
                ),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 12,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: friendsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: TeritoryColors.primary),
              ),
              error: (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        error is ApiException
                            ? error.message
                            : 'Could not load your friends.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: TeritoryColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton(
                        onPressed: () => ref.invalidate(friendsLiveProvider),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (friends) {
                final visible = _visible(friends);
                if (visible.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        friends.isEmpty
                            ? 'No friends to invite yet.'
                            : _query.isNotEmpty
                            ? 'No friends match "$_query".'
                            : 'Everyone you know is already in here.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: TeritoryColors.textMuted,
                        ),
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: visible.length,
                  itemBuilder: (context, index) {
                    final friend = visible[index];
                    final selected = _selected.contains(friend.user.id);
                    return CheckboxListTile(
                      value: selected,
                      onChanged: (value) => setState(() {
                        if (value == true) {
                          _selected.add(friend.user.id);
                        } else {
                          _selected.remove(friend.user.id);
                        }
                      }),
                      activeColor: TeritoryColors.primary,
                      title: Text(
                        friend.user.displayName,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: friend.user.handle.isEmpty
                          ? null
                          : Text(
                              '@${friend.user.handle}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: TeritoryColors.textMuted,
                              ),
                            ),
                      secondary: _FriendAvatar(user: friend.user),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _selected.isEmpty || _sending ? null : _send,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TeritoryColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _sending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _selected.isEmpty
                              ? 'Select friends'
                              : 'Send ${_selected.length} '
                                    '${widget.targetType.name} '
                                    'invite${_selected.length == 1 ? '' : 's'}',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FriendAvatar extends StatelessWidget {
  const _FriendAvatar({required this.user});

  final ApiUser user;

  @override
  Widget build(BuildContext context) {
    final initial = user.displayName.isEmpty
        ? '?'
        : user.displayName[0].toUpperCase();
    return CircleAvatar(
      radius: 18,
      backgroundColor: TeritoryColors.primary.withValues(alpha: 0.15),
      backgroundImage: user.avatarUrl.isEmpty
          ? null
          : NetworkImage(user.avatarUrl),
      onBackgroundImageError: user.avatarUrl.isEmpty ? null : (_, _) {},
      child: user.avatarUrl.isEmpty
          ? Text(
              initial,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: TeritoryColors.primary,
              ),
            )
          : null,
    );
  }
}
