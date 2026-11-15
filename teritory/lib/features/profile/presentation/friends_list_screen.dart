import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/teritory_theme.dart';
import '../../../core/models/user_models.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/data_providers.dart';
import '../../../core/services/mock_data_service.dart';

class FriendsListScreen extends ConsumerStatefulWidget {
  const FriendsListScreen({super.key});

  @override
  ConsumerState<FriendsListScreen> createState() => _FriendsListScreenState();
}

class _FriendsListScreenState extends ConsumerState<FriendsListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  static const List<String> _tabs = [
    'All',
    'Favorites',
    'Travel Buddies',
    'Family',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  FriendCategory? _categoryForTab(int index) {
    switch (index) {
      case 1:
        return FriendCategory.favorites;
      case 2:
        return FriendCategory.travelBuddies;
      case 3:
        return FriendCategory.family;
      default:
        return null;
    }
  }

  List<_FriendDisplay> _buildFriendList(
    List<FriendRelationship> relationships,
    String currentUserId,
  ) {
    final mock = MockDataService.instance;
    final List<_FriendDisplay> result = [];

    final category = _categoryForTab(_tabController.index);

    for (final rel in relationships) {
      if (category != null && rel.category != category) continue;

      final friendUserId =
          rel.userId == currentUserId ? rel.friendId : rel.userId;
      final user = mock.userById(friendUserId);
      if (user == null) continue;

      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        if (!user.displayName.toLowerCase().contains(q) &&
            !user.handle.toLowerCase().contains(q)) {
          continue;
        }
      }

      // Calculate mutual friends count
      final friendFriends = mock.friendsForUser(friendUserId);
      final myFriendIds = relationships
          .map((f) => f.userId == currentUserId ? f.friendId : f.userId)
          .toSet();
      final theirFriendIds = friendFriends
          .map((f) => f.userId == friendUserId ? f.friendId : f.userId)
          .toSet();
      final mutualCount = myFriendIds.intersection(theirFriendIds).length;

      result.add(_FriendDisplay(
        user: user,
        relationship: rel,
        mutualCount: mutualCount,
      ));
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final friends = ref.watch(friendsProvider);
    final pendingRequests = ref.watch(friendRequestsProvider);

    return Scaffold(
      backgroundColor: TeritoryColors.background,
      appBar: AppBar(
        title: Text(
          'Friends',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        actions: [
          if (pendingRequests.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                onPressed: () => context.go('/profile/friend-requests'),
                icon: const Icon(Icons.person_add_rounded, size: 18),
                label: Text(
                  '${pendingRequests.length} Pending',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: TeritoryColors.primary,
                  backgroundColor: TeritoryColors.primaryLight,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
              ),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(108),
          child: Column(
            children: [
              // Search bar
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: TeritoryColors.surfaceContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    style: GoogleFonts.plusJakartaSans(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Search friends...',
                      hintStyle: GoogleFonts.plusJakartaSans(
                        color: TeritoryColors.textMuted,
                        fontSize: 14,
                      ),
                      prefixIcon: const Icon(Icons.search_rounded,
                          color: TeritoryColors.textMuted, size: 20),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
              ),
              // Category tabs
              TabBar(
                controller: _tabController,
                onTap: (_) => setState(() {}),
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelColor: TeritoryColors.primary,
                unselectedLabelColor: TeritoryColors.textSecondary,
                labelStyle: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
                unselectedLabelStyle: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                indicatorColor: TeritoryColors.primary,
                indicatorWeight: 3,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                tabs: _tabs.map((t) => Tab(text: t)).toList(),
              ),
            ],
          ),
        ),
      ),
      body: Builder(
        builder: (context) {
          final friendList = _buildFriendList(friends, currentUser.id);

          if (friendList.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.people_outline_rounded,
                      size: 64,
                      color: TeritoryColors.textMuted.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  Text(
                    _searchQuery.isNotEmpty
                        ? 'No friends match "$_searchQuery"'
                        : 'No friends in this category yet',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: TeritoryColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Invite people to explore together!',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: TeritoryColors.textMuted,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: friendList.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final friend = friendList[index];
              return _FriendCard(
                friend: friend,
                onTap: () => context.go('/profile/friends/${friend.user.id}'),
              );
            },
          );
        },
      ),
    );
  }
}

class _FriendDisplay {
  final User user;
  final FriendRelationship relationship;
  final int mutualCount;

  const _FriendDisplay({
    required this.user,
    required this.relationship,
    required this.mutualCount,
  });
}

class _FriendCard extends StatelessWidget {
  final _FriendDisplay friend;
  final VoidCallback onTap;

  const _FriendCard({
    required this.friend,
    required this.onTap,
  });

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 365) return '${diff.inDays ~/ 365}y ago';
    if (diff.inDays > 30) return '${diff.inDays ~/ 30}mo ago';
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  String _categoryLabel(FriendCategory? cat) {
    switch (cat) {
      case FriendCategory.favorites:
        return '⭐ Favorite';
      case FriendCategory.travelBuddies:
        return '🎒 Travel Buddy';
      case FriendCategory.family:
        return '👨‍👩‍👧 Family';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = friend.user;
    final categoryLabel = _categoryLabel(friend.relationship.category);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
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
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 26,
              backgroundImage: NetworkImage(user.avatarUrl),
              backgroundColor: TeritoryColors.surfaceContainer,
            ),
            const SizedBox(width: 12),
            // Name, handle, mutual
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          user.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: TeritoryColors.textPrimary,
                          ),
                        ),
                      ),
                      if (categoryLabel.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: TeritoryColors.surfaceContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            categoryLabel,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: TeritoryColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user.handle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: TeritoryColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.people_outline_rounded,
                          size: 13, color: TeritoryColors.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        '${friend.mutualCount} mutual',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: TeritoryColors.textMuted,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.access_time_rounded,
                          size: 13, color: TeritoryColors.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        _timeAgo(user.createdAt),
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
            // Actions
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded,
                  color: TeritoryColors.textSecondary, size: 20),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              onSelected: (value) {
                final messenger = ScaffoldMessenger.of(context);
                switch (value) {
                  case 'view':
                    onTap();
                    break;
                  case 'remove':
                    messenger.showSnackBar(
                      SnackBar(
                        content:
                            Text('Removed ${user.displayName} from friends'),
                      ),
                    );
                    break;
                  case 'invite':
                    messenger.showSnackBar(
                      SnackBar(
                        content:
                            Text('Invitation sent to ${user.displayName}'),
                      ),
                    );
                    break;
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'view',
                  child: Row(
                    children: [
                      const Icon(Icons.person_outline_rounded, size: 18),
                      const SizedBox(width: 8),
                      Text('View Profile',
                          style: GoogleFonts.plusJakartaSans(fontSize: 13)),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'invite',
                  child: Row(
                    children: [
                      const Icon(Icons.send_rounded, size: 18),
                      const SizedBox(width: 8),
                      Text('Invite to Trip',
                          style: GoogleFonts.plusJakartaSans(fontSize: 13)),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'remove',
                  child: Row(
                    children: [
                      const Icon(Icons.person_remove_rounded,
                          size: 18, color: TeritoryColors.expiredRed),
                      const SizedBox(width: 8),
                      Text('Remove Friend',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: TeritoryColors.expiredRed)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
