import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/models/api_user.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/teritory_repository.dart';
import '../../../core/theme/teritory_theme.dart';
import '../application/profile_providers.dart';

/// Live friends list: `GET /users/friends` for the rows and
/// `GET /users/friends/requests` for the pending badge.
class FriendsListScreen extends ConsumerStatefulWidget {
  const FriendsListScreen({super.key});

  @override
  ConsumerState<FriendsListScreen> createState() => _FriendsListScreenState();
}

class _FriendsListScreenState extends ConsumerState<FriendsListScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _removingRelationshipId;

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

  /// The API stores `TRAVEL_BUDDIES` / `FAVORITES` / `FAMILY`.
  String? _categoryForTab(int index) {
    switch (index) {
      case 1:
        return 'FAVORITES';
      case 2:
        return 'TRAVEL_BUDDIES';
      case 3:
        return 'FAMILY';
      default:
        return null;
    }
  }

  Future<void> _refresh() async {
    ref.invalidate(friendsLiveProvider);
    ref.invalidate(friendRequestsLiveProvider);
    try {
      await ref.read(friendsLiveProvider.future);
    } on ApiException {
      // The error state renders the message.
    }
  }

  Future<void> _removeFriend(ApiFriend friend) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove friend?'),
        content: Text(
          '${friend.user.displayName} will be removed from your friends.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _removingRelationshipId = friend.relationshipId);
    try {
      await TeritoryRepository.instance.removeFriend(friend.relationshipId);
      ref.invalidate(friendsLiveProvider);
      ref.invalidate(friendRequestsLiveProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Removed ${friend.user.displayName}')),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } finally {
      if (mounted) setState(() => _removingRelationshipId = null);
    }
  }

  List<ApiFriend> _visibleFriends(List<ApiFriend> friends) {
    final category = _categoryForTab(_tabController.index);
    final query = _searchQuery.trim().toLowerCase();

    return friends.where((friend) {
      if (category != null &&
          friend.category.toUpperCase() != category) {
        return false;
      }
      if (query.isEmpty) return true;
      return friend.user.displayName.toLowerCase().contains(query) ||
          friend.user.handle.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final friendsAsync = ref.watch(friendsLiveProvider);
    final pending =
        ref.watch(friendRequestsLiveProvider).valueOrNull?.incoming.length ?? 0;

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
          if (pending > 0)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                onPressed: () => context.go('/profile/friend-requests'),
                icon: const Icon(Icons.person_add_rounded, size: 18),
                label: Text(
                  '$pending Pending',
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
                    onChanged: (value) => setState(() => _searchQuery = value),
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
                tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
              ),
            ],
          ),
        ),
      ),
      body: friendsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: TeritoryColors.primary),
        ),
        error: (error, _) => _MessageState(
          icon: Icons.cloud_off_rounded,
          title: error is ApiException
              ? error.message
              : 'Could not load your friends.',
          actionLabel: 'Retry',
          onAction: () => ref.invalidate(friendsLiveProvider),
        ),
        data: (friends) {
          final visible = _visibleFriends(friends);
          if (visible.isEmpty) {
            return RefreshIndicator(
              color: TeritoryColors.primary,
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.55,
                    child: _MessageState(
                      icon: friends.isEmpty
                          ? Icons.people_outline_rounded
                          : Icons.search_off_rounded,
                      title: friends.isEmpty
                          ? 'No friends yet'
                          : _searchQuery.isNotEmpty
                              ? 'No friends match "$_searchQuery"'
                              : 'No friends in this category yet',
                      subtitle: friends.isEmpty
                          ? 'Add travelers from their profile to see them here.'
                          : null,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: TeritoryColors.primary,
            onRefresh: _refresh,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: visible.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final friend = visible[index];
                return _FriendCard(
                  friend: friend,
                  isRemoving: _removingRelationshipId == friend.relationshipId,
                  onTap: () =>
                      context.go('/profile/friends/${friend.user.id}'),
                  onRemove: () => _removeFriend(friend),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _FriendCard extends StatelessWidget {
  const _FriendCard({
    required this.friend,
    required this.isRemoving,
    required this.onTap,
    required this.onRemove,
  });

  final ApiFriend friend;
  final bool isRemoving;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  String _categoryLabel(String category) {
    switch (category.toUpperCase()) {
      case 'FAVORITES':
        return '⭐ Favorite';
      case 'TRAVEL_BUDDIES':
        return '🎒 Travel Buddy';
      case 'FAMILY':
        return '👨‍👩‍👧 Family';
      default:
        return '';
    }
  }

  String _sinceLabel(DateTime? since) {
    if (since == null) return '';
    final days = DateTime.now().difference(since).inDays;
    if (days > 365) return 'Friends ${days ~/ 365}y';
    if (days > 30) return 'Friends ${days ~/ 30}mo';
    if (days > 0) return 'Friends ${days}d';
    return 'Friends today';
  }

  @override
  Widget build(BuildContext context) {
    final user = friend.user;
    final categoryLabel = _categoryLabel(friend.category);
    final sinceLabel = _sinceLabel(friend.since);

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
            CircleAvatar(
              radius: 26,
              backgroundColor: TeritoryColors.surfaceContainer,
              backgroundImage: user.avatarUrl.isNotEmpty
                  ? NetworkImage(user.avatarUrl)
                  : null,
              child: user.avatarUrl.isEmpty
                  ? const Icon(Icons.person_rounded,
                      color: TeritoryColors.textMuted)
                  : null,
            ),
            const SizedBox(width: 12),
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
                    '@${user.handle}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: TeritoryColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.flag_rounded,
                          size: 13, color: TeritoryColors.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        '${user.totalFlags} flags',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: TeritoryColors.textMuted,
                        ),
                      ),
                      if (sinceLabel.isNotEmpty) ...[
                        const SizedBox(width: 12),
                        const Icon(Icons.handshake_outlined,
                            size: 13, color: TeritoryColors.textMuted),
                        const SizedBox(width: 4),
                        Text(
                          sinceLabel,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: TeritoryColors.textMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (isRemoving)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded,
                    color: TeritoryColors.textSecondary, size: 20),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                onSelected: (value) {
                  if (value == 'view') onTap();
                  if (value == 'remove') onRemove();
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
                    value: 'remove',
                    child: Row(
                      children: [
                        const Icon(Icons.person_remove_rounded,
                            size: 18, color: TeritoryColors.expiredRed),
                        const SizedBox(width: 8),
                        Text(
                          'Remove Friend',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 13, color: TeritoryColors.expiredRed),
                        ),
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

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
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
            Icon(icon,
                size: 56,
                color: TeritoryColors.textMuted.withValues(alpha: 0.6)),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: TeritoryColors.textSecondary,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: TeritoryColors.textMuted,
                ),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
