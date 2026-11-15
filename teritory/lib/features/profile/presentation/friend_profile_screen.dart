import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/services/mock_data_service.dart';
import '../../../core/theme/teritory_theme.dart';

class FriendProfileScreen extends ConsumerWidget {
  final String userId;

  const FriendProfileScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = MockDataService.instance.userById(userId);

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: Center(
          child: Text(
            'User not found',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              color: TeritoryColors.textSecondary,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          user.displayName,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert_rounded, size: 20),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('More options coming soon')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Profile Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundImage: NetworkImage(user.avatarUrl),
                    backgroundColor: TeritoryColors.surfaceContainer,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user.displayName,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: TeritoryColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user.handle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: TeritoryColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    user.bio,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: TeritoryColors.textPrimary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Nomad rank badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: TeritoryColors.majorGoldLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Nomad Rank: Explorer • Lvl 5',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: TeritoryColors.majorGoldDark,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Add / Remove Friend button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Friend request sent!')),
                        );
                      },
                      icon: const Icon(Icons.person_add_rounded, size: 18),
                      label: Text(
                        'Add Friend',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
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
            ),
            const SizedBox(height: 18),

            // ── Stats Row ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('42', 'Total Flags'),
                  _buildStatItem('8', 'Major Flags'),
                  _buildStatItem('5', 'Countries'),
                  _buildStatItem('2', 'Continents'),
                  _buildStatItem('3', 'Trips'),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Map Section ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.map_rounded,
                      size: 18, color: TeritoryColors.textPrimary),
                  const SizedBox(width: 6),
                  Text(
                    'Flag Map',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: TeritoryColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                height: 220,
                decoration: BoxDecoration(
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
                  child: FlutterMap(
                    options: const MapOptions(
                      initialCenter: LatLng(10.0889, 77.0595),
                      initialZoom: 8.0,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.onway.teritory',
                        tileBuilder: (context, tileWidget, tile) =>
                            ColorFiltered(
                          colorFilter: const ColorFilter.matrix(<double>[
                            -0.20, -0.15, -0.30, 0.0, 140,
                            -0.45, 0.20, -0.35, 0.0, 165,
                            -0.55, 0.05, -0.05, 0.0, 185,
                            0.0, 0.0, 0.0, 1.0, 0,
                          ]),
                          child: tileWidget,
                        ),
                      ),
                      MarkerLayer(
                        markers: [
                          _buildFlagMarker(
                              const LatLng(10.0889, 77.0595), true),
                          _buildFlagMarker(
                              const LatLng(10.1262, 77.2354), false),
                          _buildFlagMarker(
                              const LatLng(9.9312, 76.2673), false),
                          _buildFlagMarker(
                              const LatLng(10.3000, 77.1833), true),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 22),

            // ── Trip Profiling Section ──
            _buildSectionHeader('Trip Profiling'),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _buildCompletedTripCard(
                    'Munnar Ridge Trek',
                    'Sep 15, 2026',
                    '92 km',
                  ),
                  const SizedBox(height: 10),
                  _buildCompletedTripCard(
                    'Wayanad Forest Circuit',
                    'Aug 20, 2026',
                    '45 km',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // ── Legendary Rally Badges ──
            _buildSectionHeader('Legendary Rally Badges'),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: TeritoryColors.rallyGold,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: TeritoryColors.rallyGold.withValues(alpha: 0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: TeritoryColors.majorGoldLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.emoji_events_rounded,
                          color: TeritoryColors.rallyGold, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Munnar Sunrise Rally',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: TeritoryColors.textPrimary,
                            ),
                          ),
                          Text(
                            '8 participants',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: TeritoryColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 22),

            // ── Action Buttons ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Coming soon')),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TeritoryColors.communityIndigo,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Invite to Community',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Coming soon')),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TeritoryColors.tripRoute,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Invite to Trip',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Coming soon')),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: TeritoryColors.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Send Message',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: TeritoryColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: TeritoryColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: TeritoryColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: TeritoryColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildCompletedTripCard(String name, String date, String distance) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: TeritoryColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$date • $distance',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: TeritoryColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: TeritoryColors.validatedGreen.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '✅ Completed',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: TeritoryColors.validatedGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Marker _buildFlagMarker(LatLng point, bool isMajor) {
    return Marker(
      point: point,
      width: 28,
      height: 28,
      child: Container(
        decoration: BoxDecoration(
          color: isMajor ? TeritoryColors.majorGold : TeritoryColors.primary,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 4,
            ),
          ],
        ),
        child: Icon(
          isMajor ? Icons.military_tech_rounded : Icons.flag_rounded,
          color: Colors.white,
          size: 14,
        ),
      ),
    );
  }
}
