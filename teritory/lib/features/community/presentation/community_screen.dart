import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/teritory_data_service.dart';
import '../../../core/theme/teritory_theme.dart';
import '../../flag/presentation/flag_detail_sheet.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final Set<String> _joinedTribes = {'tr_1'};

  void _toggleTribe(String id) {
    setState(() {
      if (_joinedTribes.contains(id)) {
        _joinedTribes.remove(id);
      } else {
        _joinedTribes.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: TeritoryDataService.instance,
      builder: (context, _) {
        final dataService = TeritoryDataService.instance;
        if (!dataService.isLoaded) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: TeritoryColors.primary),
            ),
          );
        }

        final tribes = dataService.travelTribes;
        final friendFlags = dataService.friendFlags;

        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                const Icon(Icons.forum_rounded,
                    color: TeritoryColors.primary, size: 22),
                const SizedBox(width: 8),
                Text(
                  'Travel Community & Tribes',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.search_rounded),
                onPressed: () {},
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Hero Banner: Socialize & Travel Together ──
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: TeritoryColors.primary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'GLOBAL TRAVEL TRIBES',
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Claim Territories Together',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Join community expeditions, unlock group badges and discover secret trails.',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white70,
                                fontSize: 12,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Text('🧭', style: TextStyle(fontSize: 32)),
                      ),
                    ],
                  ),
                ),

                // ── Travel Tribes Section ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.groups_rounded,
                          size: 18, color: TeritoryColors.primary),
                      const SizedBox(width: 6),
                      Text(
                        'Featured Travel Tribes',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: TeritoryColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Horizontal Tribes Cards
                SizedBox(
                  height: 175,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: tribes.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                    itemBuilder: (ctx, index) {
                      final tribe = tribes[index];
                      final isJoined = _joinedTribes.contains(tribe.id);

                      return Container(
                        width: 250,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isJoined
                                ? TeritoryColors.primary.withValues(alpha: 0.6)
                                : TeritoryColors.border,
                            width: isJoined ? 1.5 : 1.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Text(tribe.badge,
                                      style: const TextStyle(fontSize: 24)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      tribe.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: TeritoryColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                tribe.tagline,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: TeritoryColors.textSecondary,
                                  height: 1.3,
                                ),
                              ),
                              Row(
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${tribe.membersCount} explorers',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: TeritoryColors.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        '${tribe.totalFlagsDropped} flags',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 10,
                                          color: TeritoryColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Spacer(),
                                  TextButton(
                                    onPressed: () => _toggleTribe(tribe.id),
                                    style: TextButton.styleFrom(
                                      backgroundColor: isJoined
                                          ? TeritoryColors.surfaceContainer
                                          : TeritoryColors.primary,
                                      foregroundColor: isJoined
                                          ? TeritoryColors.textPrimary
                                          : Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 6),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: Text(
                                      isJoined ? 'Joined ✓' : 'Join Tribe',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
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
                ),
                const SizedBox(height: 24),

                // ── Friends Live Flag Activity Feed ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.dynamic_feed_rounded,
                          size: 18, color: TeritoryColors.primary),
                      const SizedBox(width: 6),
                      Text(
                        'Recent Footprints From Friends',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: TeritoryColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: friendFlags.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 14),
                  itemBuilder: (ctx, index) {
                    final fFlag = friendFlags[index];

                    return GestureDetector(
                      onTap: () =>
                          FlagDetailSheet.show(context, friendFlag: fFlag),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: fFlag.isMajorFlag
                                ? TeritoryColors.majorGold.withValues(alpha: 0.6)
                                : TeritoryColors.border,
                            width: fFlag.isMajorFlag ? 1.5 : 1.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Author Header
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundImage:
                                        NetworkImage(fFlag.friendAvatar),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          fFlag.friendName,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                            color: TeritoryColors.textPrimary,
                                          ),
                                        ),
                                        Text(
                                          'Flagged ${fFlag.placeName} • ${fFlag.flaggedTimeAgo}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 11,
                                            color: TeritoryColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (fFlag.isMajorFlag)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: TeritoryColors.majorGoldLight,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.star_rounded,
                                              size: 13,
                                              color:
                                                  TeritoryColors.majorGoldDark),
                                          const SizedBox(width: 3),
                                          Text(
                                            'MAJOR',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w900,
                                              color:
                                                  TeritoryColors.majorGoldDark,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),

                            // Photo
                            if (fFlag.photoUrl.isNotEmpty)
                              ClipRRect(
                                child: Image.network(
                                  fFlag.photoUrl,
                                  height: 180,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),

                            // Caption & Interaction
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    fFlag.caption,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      color: TeritoryColors.textPrimary,
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      const Icon(Icons.favorite_rounded,
                                          size: 16, color: Colors.redAccent),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${fFlag.kudosCount} Kudos',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: TeritoryColors.textSecondary,
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        'Tap to view pin on map',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: TeritoryColors.primary,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(Icons.arrow_forward_rounded,
                                          size: 14,
                                          color: TeritoryColors.primary),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }
}
