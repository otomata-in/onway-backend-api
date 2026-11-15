import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/user_models.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/data_providers.dart';
import '../../../core/services/mock_data_service.dart';
import '../../../core/services/teritory_repository.dart';
import '../../../core/theme/teritory_theme.dart';

class InviteFriendsSheet extends ConsumerStatefulWidget {
  final String contextLabel;

  const InviteFriendsSheet({
    super.key,
    required this.contextLabel,
  });

  static void show(BuildContext context, {required String contextLabel}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => InviteFriendsSheet(contextLabel: contextLabel),
    );
  }

  @override
  ConsumerState<InviteFriendsSheet> createState() =>
      _InviteFriendsSheetState();
}

class _InviteFriendsSheetState extends ConsumerState<InviteFriendsSheet> {
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _selectedFriendIds = {};
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<User> _getAvailableFriends() {
    final currentUser = ref.read(currentUserProvider);
    final friendRelations = ref.read(friendsProvider);
    final allUsers = MockDataService.instance.users;

    // Get friend user IDs
    final friendUserIds = <String>{};
    for (final rel in friendRelations) {
      if (rel.userId == currentUser.id) {
        friendUserIds.add(rel.friendId);
      } else if (rel.friendId == currentUser.id) {
        friendUserIds.add(rel.userId);
      }
    }

    // Build friend User list
    final friends = allUsers
        .where((u) => friendUserIds.contains(u.id) && u.id != currentUser.id)
        .toList();

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      return friends
          .where((u) =>
              u.displayName
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ||
              u.handle.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }
    return friends;
  }

  void _toggleFriend(String userId) {
    setState(() {
      if (_selectedFriendIds.contains(userId)) {
        _selectedFriendIds.remove(userId);
      } else {
        _selectedFriendIds.add(userId);
      }
    });
  }

  void _sendInvites() {
    if (_selectedFriendIds.isEmpty) return;
    final ids = _selectedFriendIds.toList();
    TeritoryRepository.instance.inviteFriends(ids, 'COMMUNITY', widget.contextLabel);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: TeritoryColors.validatedGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '✉️ Invites sent to ${_selectedFriendIds.length} friend${_selectedFriendIds.length > 1 ? 's' : ''}!',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final friends = _getAvailableFriends();

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
          // Drag handle
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

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: TeritoryColors.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.people_alt_rounded,
                    color: TeritoryColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Invite Friends',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: TeritoryColors.textPrimary,
                        ),
                      ),
                      Text(
                        widget.contextLabel,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: TeritoryColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search friends...',
                hintStyle: GoogleFonts.plusJakartaSans(
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
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Selected count badge
          if (_selectedFriendIds.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: TeritoryColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: TeritoryColors.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  '${_selectedFriendIds.length} friend${_selectedFriendIds.length > 1 ? 's' : ''} selected',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: TeritoryColors.primary,
                  ),
                ),
              ),
            ),
          if (_selectedFriendIds.isNotEmpty) const SizedBox(height: 8),

          // Friends List
          Flexible(
            child: friends.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.person_search_rounded,
                          size: 48,
                          color: TeritoryColors.textMuted,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'No friends match "$_searchQuery"'
                              : 'No friends to invite',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            color: TeritoryColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: friends.length,
                    itemBuilder: (context, index) {
                      final friend = friends[index];
                      final isSelected =
                          _selectedFriendIds.contains(friend.id);
                      return _buildFriendTile(friend, isSelected);
                    },
                  ),
          ),

          // Send Invites Button
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed:
                    _selectedFriendIds.isNotEmpty ? _sendInvites : null,
                icon: Icon(
                  Icons.send_rounded,
                  color: _selectedFriendIds.isNotEmpty
                      ? Colors.white
                      : TeritoryColors.textMuted,
                ),
                label: Text(
                  _selectedFriendIds.isNotEmpty
                      ? 'Send Invites (${_selectedFriendIds.length})'
                      : 'Select Friends to Invite',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: _selectedFriendIds.isNotEmpty
                        ? Colors.white
                        : TeritoryColors.textMuted,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedFriendIds.isNotEmpty
                      ? TeritoryColors.primary
                      : TeritoryColors.border,
                  disabledBackgroundColor: TeritoryColors.border,
                  elevation: _selectedFriendIds.isNotEmpty ? 2 : 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendTile(User friend, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: isSelected
            ? TeritoryColors.primaryLight
            : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () => _toggleFriend(friend.id),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: NetworkImage(friend.avatarUrl),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        friend.displayName,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: TeritoryColors.textPrimary,
                        ),
                      ),
                      Text(
                        friend.handle,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: TeritoryColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? TeritoryColors.primary
                        : Colors.transparent,
                    border: Border.all(
                      color: isSelected
                          ? TeritoryColors.primary
                          : TeritoryColors.border,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check_rounded,
                          color: Colors.white, size: 18)
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
