import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/teritory_models.dart';
import '../../../core/theme/teritory_theme.dart';

class FlagDetailSheet extends StatefulWidget {
  final FlagItem? userFlag;
  final FriendFlag? friendFlag;

  const FlagDetailSheet({
    super.key,
    this.userFlag,
    this.friendFlag,
  }) : assert(userFlag != null || friendFlag != null);

  static void show(
    BuildContext context, {
    FlagItem? userFlag,
    FriendFlag? friendFlag,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => FlagDetailSheet(
        userFlag: userFlag,
        friendFlag: friendFlag,
      ),
    );
  }

  @override
  State<FlagDetailSheet> createState() => _FlagDetailSheetState();
}

class _FlagDetailSheetState extends State<FlagDetailSheet> {
  late int _kudos;
  bool _hasGivenKudos = false;

  // Reaction state
  final Map<String, int> _reactionCounts = {
    'epic': 24,
    'hiddenGem': 12,
    'greatShot': 8,
  };
  final Set<String> _tappedReactions = {};

  // Comment state
  final TextEditingController _commentController = TextEditingController();
  late final List<_MockComment> _comments;

  @override
  void initState() {
    super.initState();
    _kudos = widget.userFlag?.kudos ?? widget.friendFlag?.kudosCount ?? 0;
    _comments = [
      _MockComment(
        userName: 'Arjun N.',
        userAvatar: 'https://picsum.photos/seed/arjun/200',
        text: 'Amazing view from here! The sunset was magical ✨',
        timeAgo: '2h ago',
      ),
      _MockComment(
        userName: 'Priya M.',
        userAvatar: 'https://picsum.photos/seed/priya/200',
        text: 'Added this to my trip plan!',
        timeAgo: '5h ago',
      ),
      _MockComment(
        userName: 'Kiran Das',
        userAvatar: 'https://picsum.photos/seed/kiran/200',
        text: 'Great flag drop! Adding to my bucket list 📋',
        timeAgo: '1d ago',
      ),
    ];
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _toggleKudos() {
    setState(() {
      if (_hasGivenKudos) {
        _kudos--;
        _hasGivenKudos = false;
      } else {
        _kudos++;
        _hasGivenKudos = true;
      }
    });
  }

  void _toggleReaction(String key) {
    setState(() {
      if (_tappedReactions.contains(key)) {
        _tappedReactions.remove(key);
        _reactionCounts[key] = (_reactionCounts[key] ?? 1) - 1;
      } else {
        _tappedReactions.add(key);
        _reactionCounts[key] = (_reactionCounts[key] ?? 0) + 1;
      }
    });
  }

  void _addComment() {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _comments.insert(
        0,
        _MockComment(
          userName: 'You',
          userAvatar:
              'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=200&q=80',
          text: text,
          timeAgo: 'Just now',
        ),
      );
      _commentController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isFriend = widget.friendFlag != null;
    final placeName =
        widget.userFlag?.placeName ?? widget.friendFlag!.placeName;
    final city = widget.userFlag?.city ?? widget.friendFlag!.city;
    final country = widget.userFlag?.country ?? widget.friendFlag!.country;
    final isMajor =
        widget.userFlag?.isMajorFlag ?? widget.friendFlag!.isMajorFlag;
    final category = widget.userFlag?.category ?? 'Explorer Landmark';
    final date =
        widget.userFlag?.flaggedDate ?? widget.friendFlag!.flaggedTimeAgo;
    final notes = widget.userFlag?.notes ?? widget.friendFlag!.caption;
    final photoUrl = widget.userFlag?.photoUrl ?? widget.friendFlag!.photoUrl;
    final authorName = isFriend ? widget.friendFlag!.friendName : 'You (Claimed)';
    final authorAvatar = isFriend
        ? widget.friendFlag!.friendAvatar
        : 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=200&q=80';

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
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

            // Photo preview (if present)
            if (photoUrl.isNotEmpty)
              Container(
                height: 180,
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  image: DecorationImage(
                    image: NetworkImage(photoUrl),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.calendar_today_rounded,
                                color: Colors.white, size: 12),
                            const SizedBox(width: 6),
                            Text(
                              date,
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (isMajor)
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.amber.withValues(alpha: 0.4),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star_rounded,
                                  color: Colors.white, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                'MAJOR WONDER FLAG',
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category Chip & Location
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: TeritoryColors.primaryLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          category,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: TeritoryColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '$city, $country',
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: TeritoryColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Place Name
                  Text(
                    placeName,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: TeritoryColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Flagged by Author Row
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: TeritoryColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundImage: NetworkImage(authorAvatar),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                authorName,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: TeritoryColors.textPrimary,
                                ),
                              ),
                              Text(
                                isFriend
                                    ? 'Flagged while exploring'
                                    : 'Verified GPS Footprint',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  color: TeritoryColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Flag Icon badge
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isMajor
                                ? TeritoryColors.majorGoldLight
                                : TeritoryColors.primaryLight,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.flag_rounded,
                            size: 16,
                            color: isMajor
                                ? TeritoryColors.majorGoldDark
                                : TeritoryColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Travel Note
                  if (notes.isNotEmpty) ...[
                    Text(
                      'Traveler Note',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: TeritoryColors.textMuted,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '"$notes"',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        color: TeritoryColors.textPrimary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],

                  // ═══════════════════════════════════════════════════════
                  // NEW: Reactions Bar
                  // ═══════════════════════════════════════════════════════
                  Row(
                    children: [
                      _buildReactionChip(
                        key: 'epic',
                        emoji: '🔥',
                        label: 'Epic',
                        count: _reactionCounts['epic'] ?? 0,
                        isActive: _tappedReactions.contains('epic'),
                      ),
                      const SizedBox(width: 8),
                      _buildReactionChip(
                        key: 'hiddenGem',
                        emoji: '💎',
                        label: 'Hidden Gem',
                        count: _reactionCounts['hiddenGem'] ?? 0,
                        isActive: _tappedReactions.contains('hiddenGem'),
                      ),
                      const SizedBox(width: 8),
                      _buildReactionChip(
                        key: 'greatShot',
                        emoji: '📸',
                        label: 'Great Shot',
                        count: _reactionCounts['greatShot'] ?? 0,
                        isActive: _tappedReactions.contains('greatShot'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Action Bar: Kudos / High Five & Bucket List
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _toggleKudos,
                          icon: Icon(
                            _hasGivenKudos
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color: _hasGivenKudos
                                ? Colors.redAccent
                                : TeritoryColors.textSecondary,
                            size: 18,
                          ),
                          label: Text(
                            '$_kudos Kudos',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.bold,
                              color: _hasGivenKudos
                                  ? Colors.redAccent
                                  : TeritoryColors.textPrimary,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(
                              color: _hasGivenKudos
                                  ? Colors.redAccent.withValues(alpha: 0.3)
                                  : TeritoryColors.border,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Saved $placeName to Bucket List!'),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          icon: const Icon(Icons.bookmark_add_rounded,
                              size: 18, color: Colors.white),
                          label: Text(
                            'Save to Wishlist',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: TeritoryColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // ═══════════════════════════════════════════════════════
                  // NEW: Comments Section
                  // ═══════════════════════════════════════════════════════
                  const SizedBox(height: 22),
                  Text(
                    'Comments',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: TeritoryColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ..._comments.map((c) => _buildCommentTile(c)),
                  const SizedBox(height: 10),

                  // Add Comment Input
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          decoration: InputDecoration(
                            hintText: 'Add a comment...',
                            hintStyle: GoogleFonts.plusJakartaSans(
                              color: TeritoryColors.textMuted,
                              fontSize: 13,
                            ),
                            filled: true,
                            fillColor: TeritoryColors.surfaceContainer,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Material(
                        color: TeritoryColors.primary,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          onTap: _addComment,
                          borderRadius: BorderRadius.circular(12),
                          child: const Padding(
                            padding: EdgeInsets.all(10),
                            child: Icon(Icons.send_rounded,
                                color: Colors.white, size: 20),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // ═══════════════════════════════════════════════════════
                  // NEW: Nearby Food Shelf
                  // ═══════════════════════════════════════════════════════
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      const Text('🍜', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 6),
                      Text(
                        'Nearby Food Spots',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: TeritoryColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 130,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildFoodCard(
                          name: 'Malabar Kitchen',
                          cuisine: 'Kerala Cuisine',
                          distance: '0.8 km',
                          rating: 4.5,
                        ),
                        const SizedBox(width: 10),
                        _buildFoodCard(
                          name: 'Chai Junction',
                          cuisine: 'Cafe & Snacks',
                          distance: '1.2 km',
                          rating: 4.2,
                        ),
                        const SizedBox(width: 10),
                        _buildFoodCard(
                          name: 'Spice Garden',
                          cuisine: 'Multi-cuisine',
                          distance: '2.1 km',
                          rating: 4.7,
                        ),
                      ],
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

  // ═══════════════════════════════════════════════════════════════════════
  // NEW: Reaction chip builder
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildReactionChip({
    required String key,
    required String emoji,
    required String label,
    required int count,
    required bool isActive,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _toggleReaction(key),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isActive
                ? TeritoryColors.primaryLight
                : TeritoryColors.surfaceContainer,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive ? TeritoryColors.primary : TeritoryColors.border,
              width: isActive ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 2),
              Text(
                '$label $count',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isActive
                      ? TeritoryColors.primary
                      : TeritoryColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // NEW: Comment tile builder
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildCommentTile(_MockComment comment) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundImage: NetworkImage(comment.userAvatar),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: TeritoryColors.surfaceContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        comment.userName,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: TeritoryColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        comment.timeAgo,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          color: TeritoryColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    comment.text,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: TeritoryColors.textPrimary,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // NEW: Food card builder
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildFoodCard({
    required String name,
    required String cuisine,
    required String distance,
    required double rating,
  }) {
    return Container(
      width: 120,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TeritoryColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.restaurant_rounded,
            color: TeritoryColors.foodOrange,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: TeritoryColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            cuisine,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              color: TeritoryColors.foodOrange,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                distance,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  color: TeritoryColors.textMuted,
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.star_rounded,
                size: 12,
                color: TeritoryColors.majorGold,
              ),
              const SizedBox(width: 2),
              Text(
                rating.toString(),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: TeritoryColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MockComment {
  final String userName;
  final String userAvatar;
  final String text;
  final String timeAgo;

  const _MockComment({
    required this.userName,
    required this.userAvatar,
    required this.text,
    required this.timeAgo,
  });
}
