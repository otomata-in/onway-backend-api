import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/models/user_models.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/teritory_repository.dart';
import '../../../core/theme/teritory_theme.dart';
import '../application/community_detail_provider.dart';

/// Live replacement for the old "Invite link copied!" toast: pick friends and
/// send a real `POST /users/invites`.
class InviteFriendsSheet extends ConsumerStatefulWidget {
  final String communityId;
  final String communityName;

  const InviteFriendsSheet({
    super.key,
    required this.communityId,
    this.communityName = 'this community',
  });

  static Future<int?> show(
    BuildContext context, {
    required String communityId,
    String communityName = 'this community',
  }) {
    return showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => InviteFriendsSheet(
        communityId: communityId,
        communityName: communityName,
      ),
    );
  }

  @override
  ConsumerState<InviteFriendsSheet> createState() => _InviteFriendsSheetState();
}

class _InviteFriendsSheetState extends ConsumerState<InviteFriendsSheet> {
  final Set<String> _selected = {};
  bool _sending = false;

  Future<void> _send() async {
    if (_selected.isEmpty || _sending) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _sending = true);

    try {
      final count = await TeritoryRepository.instance.sendInvites(
        userIds: _selected.toList(),
        type: 'COMMUNITY',
        targetId: widget.communityId,
      );
      if (!mounted) return;
      Navigator.pop(context, count);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      messenger.showSnackBar(SnackBar(
        content: Text(e.message),
        backgroundColor: TeritoryColors.expiredRed,
      ));
    } catch (_) {
      if (!mounted) return;
      setState(() => _sending = false);
      messenger.showSnackBar(const SnackBar(
        content: Text('Could not send invitations. Check your connection.'),
        backgroundColor: TeritoryColors.expiredRed,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final friendsAsync = ref.watch(inviteCandidatesProvider);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
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
                  'Invitees get a notification for ${widget.communityName}.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: TeritoryColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: friendsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(
                    color: TeritoryColors.communityIndigo),
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
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: () => ref.invalidate(inviteCandidatesProvider),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (friends) {
                if (friends.isEmpty) {
                  return Center(
                    child: Text(
                      'No friends to invite yet.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: TeritoryColors.textMuted,
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: friends.length,
                  itemBuilder: (context, index) {
                    final friend = friends[index];
                    final selected = _selected.contains(friend.id);
                    return CheckboxListTile(
                      value: selected,
                      onChanged: (value) => setState(() {
                        if (value == true) {
                          _selected.add(friend.id);
                        } else {
                          _selected.remove(friend.id);
                        }
                      }),
                      activeColor: TeritoryColors.communityIndigo,
                      title: Text(
                        friend.displayName,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: friend.handle.isEmpty
                          ? null
                          : Text(
                              '@${friend.handle}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: TeritoryColors.textMuted,
                              ),
                            ),
                      secondary: _FriendAvatar(friend: friend),
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
                    backgroundColor: TeritoryColors.communityIndigo,
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
                              : 'Send ${_selected.length} invite${_selected.length == 1 ? '' : 's'}',
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
  final User friend;
  const _FriendAvatar({required this.friend});

  @override
  Widget build(BuildContext context) {
    final initial =
        friend.displayName.isEmpty ? '?' : friend.displayName[0].toUpperCase();
    return CircleAvatar(
      radius: 18,
      backgroundColor: TeritoryColors.communityIndigo.withValues(alpha: 0.15),
      backgroundImage:
          friend.avatarUrl.isEmpty ? null : NetworkImage(friend.avatarUrl),
      onBackgroundImageError: friend.avatarUrl.isEmpty ? null : (_, _) {},
      child: friend.avatarUrl.isEmpty
          ? Text(
              initial,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: TeritoryColors.communityIndigo,
              ),
            )
          : null,
    );
  }
}
