import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/rally_models.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/mock_data_service.dart';
import '../../../core/theme/teritory_theme.dart';

class LegendaryRallySheet extends ConsumerStatefulWidget {
  const LegendaryRallySheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const LegendaryRallySheet(),
    );
  }

  @override
  ConsumerState<LegendaryRallySheet> createState() =>
      _LegendaryRallySheetState();
}

class _LegendaryRallySheetState extends ConsumerState<LegendaryRallySheet> {
  final TextEditingController _nameController = TextEditingController();
  int _selectedWindowHours = 2;
  RallyInviteType _selectedInviteType = RallyInviteType.community;

  // Mock participant roster
  late final List<_RallyParticipantEntry> _participants;

  @override
  void initState() {
    super.initState();
    final users = MockDataService.instance.users;
    _participants = [
      _RallyParticipantEntry(
        userId: users[1].id,
        userName: users[1].displayName,
        userAvatar: users[1].avatarUrl,
        joinStatus: _JoinStatus.joined,
      ),
      _RallyParticipantEntry(
        userId: users[2].id,
        userName: users[2].displayName,
        userAvatar: users[2].avatarUrl,
        joinStatus: _JoinStatus.joined,
      ),
      _RallyParticipantEntry(
        userId: users[3].id,
        userName: users[3].displayName,
        userAvatar: users[3].avatarUrl,
        joinStatus: _JoinStatus.pending,
      ),
      _RallyParticipantEntry(
        userId: users[4].id,
        userName: users[4].displayName,
        userAvatar: users[4].avatarUrl,
        joinStatus: _JoinStatus.declined,
      ),
    ];
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  int get _joinedCount =>
      _participants.where((p) => p.joinStatus == _JoinStatus.joined).length;

  bool get _canDropFlag => _joinedCount >= 2;

  void _dropRallyFlag() {
    if (!_canDropFlag) return;
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a rally name')),
      );
      return;
    }

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            const Icon(Icons.flag_circle_rounded, color: TeritoryColors.rallyGold),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '🏴 Legendary Rally "$name" created! +200 XP',
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
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final currentUser = ref.watch(currentUserProvider);

    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
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
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFEF3C7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.flag_circle_rounded,
                    color: TeritoryColors.rallyGold,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Start Legendary Rally',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: TeritoryColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Organize by ${currentUser.displayName}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: TeritoryColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Rally Name Field
            Text(
              'Rally Name',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: TeritoryColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'e.g. Munnar Sunrise Rally',
                filled: true,
                fillColor: TeritoryColors.surfaceContainer,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(
                  Icons.edit_rounded,
                  color: TeritoryColors.rallyGold,
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Time Window Chips
            Text(
              'Time Window',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: TeritoryColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [1, 2, 4, 8].map((hours) {
                final isSelected = _selectedWindowHours == hours;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: hours == 8 ? 0 : 8,
                    ),
                    child: ChoiceChip(
                      label: Text('${hours}h'),
                      selected: isSelected,
                      selectedColor: const Color(0xFFFEF3C7),
                      backgroundColor: TeritoryColors.surfaceContainer,
                      labelStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected
                            ? TeritoryColors.rallyGold
                            : TeritoryColors.textSecondary,
                      ),
                      side: BorderSide(
                        color: isSelected
                            ? TeritoryColors.rallyGold
                            : TeritoryColors.border,
                      ),
                      showCheckmark: false,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedWindowHours = hours;
                          });
                        }
                      },
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),

            // Invite Type
            Text(
              'Invite Type',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: TeritoryColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: RallyInviteType.values.map((type) {
                final isSelected = _selectedInviteType == type;
                final label = switch (type) {
                  RallyInviteType.community => 'Community',
                  RallyInviteType.friends => 'Friends',
                  RallyInviteType.open => 'Open',
                };
                final icon = switch (type) {
                  RallyInviteType.community => Icons.groups_rounded,
                  RallyInviteType.friends => Icons.people_rounded,
                  RallyInviteType.open => Icons.public_rounded,
                };
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: type == RallyInviteType.open ? 0 : 8,
                    ),
                    child: ChoiceChip(
                      avatar: Icon(
                        icon,
                        size: 18,
                        color: isSelected
                            ? TeritoryColors.rallyGold
                            : TeritoryColors.textMuted,
                      ),
                      label: Text(label),
                      selected: isSelected,
                      selectedColor: const Color(0xFFFEF3C7),
                      backgroundColor: TeritoryColors.surfaceContainer,
                      labelStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected
                            ? TeritoryColors.rallyGold
                            : TeritoryColors.textSecondary,
                      ),
                      side: BorderSide(
                        color: isSelected
                            ? TeritoryColors.rallyGold
                            : TeritoryColors.border,
                      ),
                      showCheckmark: false,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedInviteType = type;
                          });
                        }
                      },
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Participant Roster
            Row(
              children: [
                Text(
                  'Participant Roster',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: TeritoryColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$_joinedCount joined',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: TeritoryColors.rallyGold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: TeritoryColors.surfaceContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: _participants.asMap().entries.map((entry) {
                  final index = entry.key;
                  final participant = entry.value;
                  final isLast = index == _participants.length - 1;
                  return _buildParticipantRow(participant, isLast);
                }).toList(),
              ),
            ),
            const SizedBox(height: 22),

            // Drop Rally Flag Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _canDropFlag ? _dropRallyFlag : null,
                icon: Icon(
                  Icons.flag_rounded,
                  color: _canDropFlag ? Colors.white : TeritoryColors.textMuted,
                ),
                label: Text(
                  _canDropFlag
                      ? 'Drop Rally Flag'
                      : 'Need ≥2 Participants to Rally',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color:
                        _canDropFlag ? Colors.white : TeritoryColors.textMuted,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _canDropFlag
                      ? TeritoryColors.rallyGold
                      : TeritoryColors.border,
                  disabledBackgroundColor: TeritoryColors.border,
                  elevation: _canDropFlag ? 2 : 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipantRow(
      _RallyParticipantEntry participant, bool isLast) {
    final statusColor = switch (participant.joinStatus) {
      _JoinStatus.joined => TeritoryColors.validatedGreen,
      _JoinStatus.pending => TeritoryColors.rallyGold,
      _JoinStatus.declined => TeritoryColors.expiredRed,
    };
    final statusLabel = switch (participant.joinStatus) {
      _JoinStatus.joined => 'Joined',
      _JoinStatus.pending => 'Pending',
      _JoinStatus.declined => 'Declined',
    };
    final statusIcon = switch (participant.joinStatus) {
      _JoinStatus.joined => Icons.check_circle_rounded,
      _JoinStatus.pending => Icons.schedule_rounded,
      _JoinStatus.declined => Icons.cancel_rounded,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(
                  color: TeritoryColors.border,
                  width: 0.5,
                ),
              ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundImage: NetworkImage(participant.userAvatar),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              participant.userName,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: TeritoryColors.textPrimary,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(statusIcon, size: 14, color: statusColor),
                const SizedBox(width: 4),
                Text(
                  statusLabel,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _JoinStatus { joined, pending, declined }

class _RallyParticipantEntry {
  final String userId;
  final String userName;
  final String userAvatar;
  final _JoinStatus joinStatus;

  const _RallyParticipantEntry({
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.joinStatus,
  });
}
