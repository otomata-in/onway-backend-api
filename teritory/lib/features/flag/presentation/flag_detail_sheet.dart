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

  @override
  void initState() {
    super.initState();
    _kudos = widget.userFlag?.kudos ?? widget.friendFlag?.kudosCount ?? 0;
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
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}
