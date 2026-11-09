import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/teritory_data_service.dart';
import '../../../core/theme/teritory_theme.dart';

class WondersCatalogScreen extends StatefulWidget {
  const WondersCatalogScreen({super.key});

  @override
  State<WondersCatalogScreen> createState() => _WondersCatalogScreenState();
}

class _WondersCatalogScreenState extends State<WondersCatalogScreen> {
  String _selectedContinent = 'All';

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

        final allWonders = dataService.majorWonders;
        final filteredWonders = _selectedContinent == 'All'
            ? allWonders
            : allWonders.where((w) => w.continent == _selectedContinent).toList();

        final claimedCount = allWonders.where((w) => w.isClaimed).length;

        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                const Icon(Icons.military_tech_rounded,
                    color: TeritoryColors.majorGoldDark, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Major Wonders Registry',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Progress Header Card ──
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 8, 16, 14),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: TeritoryColors.majorGold),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: TeritoryColors.majorGold.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.emoji_events_rounded,
                            color: TeritoryColors.majorGoldDark, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$claimedCount of ${allWonders.length} Wonders Claimed',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: TeritoryColors.majorGoldDark,
                              ),
                            ),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: claimedCount / allWonders.length,
                                minHeight: 6,
                                backgroundColor: Colors.white60,
                                valueColor: const AlwaysStoppedAnimation(
                                    TeritoryColors.majorGoldDark),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Stake flags at official UNESCO & World Wonders to boost your global ranking.',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: TeritoryColors.majorGoldDark
                                    .withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Continent Filter Chips ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ['All', 'Asia', 'Europe', 'South America']
                          .map((c) => Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(c),
                                  selected: _selectedContinent == c,
                                  selectedColor: TeritoryColors.surfaceDark,
                                  labelStyle: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: _selectedContinent == c
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                    color: _selectedContinent == c
                                        ? Colors.white
                                        : TeritoryColors.textPrimary,
                                  ),
                                  side: BorderSide(
                                    color: _selectedContinent == c
                                        ? TeritoryColors.surfaceDark
                                        : TeritoryColors.border,
                                  ),
                                  onSelected: (selected) {
                                    if (selected) {
                                      setState(() {
                                        _selectedContinent = c;
                                      });
                                    }
                                  },
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // ── Grid of Major Wonders ──
                ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: filteredWonders.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 14),
                  itemBuilder: (ctx, index) {
                    final wonder = filteredWonders[index];

                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: wonder.isClaimed
                              ? TeritoryColors.majorGold
                              : TeritoryColors.border,
                          width: wonder.isClaimed ? 1.5 : 1.0,
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
                          Stack(
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(20)),
                                child: Image.network(
                                  wonder.photoUrl,
                                  height: 160,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 12,
                                right: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: wonder.isClaimed
                                        ? TeritoryColors.emeraldGreen
                                        : Colors.black.withValues(alpha: 0.65),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        wonder.isClaimed
                                            ? Icons.check_circle_rounded
                                            : Icons.lock_outline_rounded,
                                        color: Colors.white,
                                        size: 13,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        wonder.isClaimed
                                            ? 'CLAIMED'
                                            : 'UNEXPLORED',
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
                          Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        wonder.name,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: TeritoryColors.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        '${wonder.country} • ${wonder.continent}',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12,
                                          color: TeritoryColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${wonder.totalFlagsClaimed}',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w900,
                                        color: TeritoryColors.primary,
                                      ),
                                    ),
                                    Text(
                                      'Flags worldwide',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 10,
                                        color: TeritoryColors.textSecondary,
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
