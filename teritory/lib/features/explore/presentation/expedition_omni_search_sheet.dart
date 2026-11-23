import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/models/api_flag.dart';
import '../../../core/models/api_user.dart';
import '../../../core/models/clan_models.dart';
import '../../../core/models/search_models.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/teritory_repository.dart';
import '../../../core/theme/teritory_theme.dart';
import '../../clans/application/clans_provider.dart';
import '../../profile/presentation/friend_profile_screen.dart';
import '../application/explore_flags_provider.dart';

/// Full-featured omni-search sheet allowing explorers to search for:
/// - Places (major flags, minor flags, and worldwide geographic destinations)
/// - Explorers (user profiles with friend request actions)
/// - Clans (with quick-join and clan details view)
class ExpeditionOmniSearchSheet extends ConsumerStatefulWidget {
  const ExpeditionOmniSearchSheet({super.key});

  static Future<ExploreTarget?> show(BuildContext context) {
    return showModalBottomSheet<ExploreTarget>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ExpeditionOmniSearchSheet(),
    );
  }

  @override
  ConsumerState<ExpeditionOmniSearchSheet> createState() =>
      _ExpeditionOmniSearchSheetState();
}

enum _SearchCategory { all, places, explorers, clans }

class _ExpeditionOmniSearchSheetState
    extends ConsumerState<ExpeditionOmniSearchSheet> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  _SearchCategory _activeCategory = _SearchCategory.all;
  Timer? _debounceTimer;

  bool _loading = false;
  String? _error;
  OmniSearchResult _result = const OmniSearchResult();

  // Suggestions when query is empty
  bool _loadingSuggestions = true;
  OmniSearchResult _suggestions = const OmniSearchResult();

  final Set<String> _joiningClanIds = {};

  @override
  void initState() {
    super.initState();
    _loadInitialSuggestions();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadInitialSuggestions() async {
    try {
      final res = await TeritoryRepository.instance.searchOmni(query: '');
      if (mounted) {
        setState(() {
          _suggestions = res;
          _loadingSuggestions = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingSuggestions = false);
    }
  }

  void _onQueryChanged(String query) {
    _debounceTimer?.cancel();
    final trimmed = query.trim();

    if (trimmed.isEmpty) {
      setState(() {
        _loading = false;
        _error = null;
        _result = const OmniSearchResult();
      });
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 250), () {
      _executeSearch(trimmed);
    });
  }

  Future<void> _executeSearch(String query) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    String typeParam = 'all';
    switch (_activeCategory) {
      case _SearchCategory.all:
        typeParam = 'all';
        break;
      case _SearchCategory.places:
        typeParam = 'places';
        break;
      case _SearchCategory.explorers:
        typeParam = 'users';
        break;
      case _SearchCategory.clans:
        typeParam = 'clans';
        break;
    }

    try {
      final result = await TeritoryRepository.instance.searchOmni(
        query: query,
        type: typeParam,
      );
      if (mounted) {
        setState(() {
          _result = result;
          _loading = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Could not search. Please check your connection.';
          _loading = false;
        });
      }
    }
  }

  void _onSelectPlace({
    required LatLng coordinates,
    required String title,
    String? subtitle,
    ApiFlag? flag,
  }) {
    final target = ExploreTarget(
      coordinates: coordinates,
      label: title,
      subtitle: subtitle,
      focusedFlag: flag,
    );

    // 1. Set the active explore target in Riverpod
    ref.read(customExploreTargetProvider.notifier).state = target;

    // 2. Dismiss search sheet with target
    Navigator.of(context).pop(target);
  }

  Future<void> _joinClan(Clan clan) async {
    final api = TeritoryApiService.instance;
    if (!api.isAuthenticated) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please sign in to join a clan.'),
          backgroundColor: TeritoryColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          action: SnackBarAction(
            label: 'Sign In',
            textColor: Colors.white,
            onPressed: () {
              Navigator.of(context).pop();
              context.push('/login');
            },
          ),
        ),
      );
      return;
    }

    setState(() => _joiningClanIds.add(clan.id));
    try {
      await ref.read(clansProvider.notifier).toggleMembership(clan.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Joined ${clan.name}!'),
          backgroundColor: TeritoryColors.emeraldGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      // Re-run search or update suggestion state
      if (_controller.text.trim().isEmpty) {
        _loadInitialSuggestions();
      } else {
        _executeSearch(_controller.text.trim());
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 401) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Your session expired. Please sign in again.'),
            backgroundColor: TeritoryColors.expiredRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            action: SnackBarAction(
              label: 'Sign In',
              textColor: Colors.white,
              onPressed: () {
                Navigator.of(context).pop();
                context.push('/login');
              },
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: TeritoryColors.expiredRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Could not reach Teritory. Check your connection.'),
          backgroundColor: TeritoryColors.expiredRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _joiningClanIds.remove(clan.id));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasQuery = _controller.text.trim().isNotEmpty;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          // 1. Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 8),
              width: 38,
              height: 4.5,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),

          // 2. Top search bar with Back & Clear
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      onChanged: _onQueryChanged,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : TeritoryColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search places, flags, explorers, clans...',
                        hintStyle: GoogleFonts.plusJakartaSans(
                          fontSize: 13.5,
                          color: isDark
                              ? const Color(0xFF64748B)
                              : TeritoryColors.textMuted,
                        ),
                        prefixIcon: Icon(
                          Icons.travel_explore_rounded,
                          size: 21,
                          color: isDark
                              ? TeritoryColors.majorGold
                              : TeritoryColors.primary,
                        ),
                        suffixIcon: hasQuery
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                color: TeritoryColors.textMuted,
                                onPressed: () {
                                  _controller.clear();
                                  _onQueryChanged('');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 13,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: TeritoryColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 3. Category Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                _buildCategoryChip(
                  label: 'All',
                  icon: Icons.all_inclusive_rounded,
                  category: _SearchCategory.all,
                ),
                _buildCategoryChip(
                  label: 'Places & Flags',
                  icon: Icons.place_rounded,
                  category: _SearchCategory.places,
                ),
                _buildCategoryChip(
                  label: 'Explorers',
                  icon: Icons.person_rounded,
                  category: _SearchCategory.explorers,
                ),
                _buildCategoryChip(
                  label: 'Clans',
                  icon: Icons.shield_rounded,
                  category: _SearchCategory.clans,
                ),
              ],
            ),
          ),

          if (_loading)
            const LinearProgressIndicator(
              minHeight: 2.5,
              color: TeritoryColors.primary,
              backgroundColor: Colors.transparent,
            )
          else
            const Divider(height: 1),

          // 4. Body Content
          Expanded(
            child: _buildBody(hasQuery: hasQuery, isDark: isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip({
    required String label,
    required IconData icon,
    required _SearchCategory category,
  }) {
    final isSelected = _activeCategory == category;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        avatar: Icon(
          icon,
          size: 15,
          color: isSelected
              ? Colors.white
              : (isDark ? const Color(0xFF94A3B8) : TeritoryColors.textSecondary),
        ),
        label: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isSelected
                ? Colors.white
                : (isDark ? const Color(0xFFE2E8F0) : TeritoryColors.textPrimary),
          ),
        ),
        backgroundColor:
            isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        selectedColor: TeritoryColors.primary,
        checkmarkColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: isSelected
                ? TeritoryColors.primary
                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          ),
        ),
        onSelected: (_) {
          setState(() => _activeCategory = category);
          if (_controller.text.trim().isNotEmpty) {
            _executeSearch(_controller.text.trim());
          }
        },
      ),
    );
  }

  Widget _buildBody({required bool hasQuery, required bool isDark}) {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 40, color: TeritoryColors.expiredRed),
              const SizedBox(height: 10),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: TeritoryColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => _executeSearch(_controller.text.trim()),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (!hasQuery) {
      return _buildSuggestionsView(isDark);
    }

    if (!_loading && _result.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.search_off_rounded,
                size: 48,
                color: isDark ? const Color(0xFF475569) : TeritoryColors.textMuted,
              ),
              const SizedBox(height: 12),
              Text(
                'No discoveries found for "${_controller.text.trim()}"',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : TeritoryColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Try searching for another world wonder, town, clan name, or explorer handle.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: TeritoryColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        // 1. Places & Flags section
        if (_result.flags.isNotEmpty || _result.locations.isNotEmpty) ...[
          _buildSectionHeader('Places & Flags', Icons.place_rounded),
          ..._result.locations.map((loc) => _buildLocationCard(loc, isDark)),
          ..._result.flags.map((flag) => _buildFlagCard(flag, isDark)),
          const SizedBox(height: 16),
        ],

        // 2. Explorers section
        if (_result.users.isNotEmpty) ...[
          _buildSectionHeader('Explorers', Icons.people_alt_rounded),
          ..._result.users.map((user) => _buildUserCard(user, isDark)),
          const SizedBox(height: 16),
        ],

        // 3. Clans section
        if (_result.clans.isNotEmpty) ...[
          _buildSectionHeader('Clans & Fleets', Icons.shield_rounded),
          ..._result.clans.map((clan) => _buildClanCard(clan, isDark)),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  Widget _buildSuggestionsView(bool isDark) {
    if (_loadingSuggestions) {
      return const Center(
        child: CircularProgressIndicator(color: TeritoryColors.primary),
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        Row(
          children: [
            const Icon(
              Icons.stars_rounded,
              size: 18,
              color: TeritoryColors.majorGold,
            ),
            const SizedBox(width: 6),
            Text(
              'Featured World Wonders',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : TeritoryColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ..._suggestions.flags.map((f) => _buildFlagCard(f, isDark)),
        const SizedBox(height: 20),

        if (_suggestions.clans.isNotEmpty) ...[
          Row(
            children: [
              const Icon(
                Icons.shield_rounded,
                size: 18,
                color: TeritoryColors.clanPurple,
              ),
              const SizedBox(width: 6),
              Text(
                'Top Expedition Clans',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : TeritoryColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ..._suggestions.clans.map((c) => _buildClanCard(c, isDark)),
          const SizedBox(height: 20),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: TeritoryColors.primary),
          const SizedBox(width: 6),
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: isDark ? const Color(0xFF94A3B8) : TeritoryColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  // Card for Flag result (Major or Minor)
  Widget _buildFlagCard(ApiFlag flag, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: flag.isMajorFlag
              ? TeritoryColors.majorGold.withValues(alpha: 0.4)
              : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        onTap: () => _onSelectPlace(
          coordinates: flag.coordinates,
          title: flag.placeName,
          subtitle: '${flag.city}, ${flag.country}',
          flag: flag,
        ),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: flag.isMajorFlag
                ? TeritoryColors.majorGold.withValues(alpha: 0.15)
                : TeritoryColors.primaryLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            flag.isMajorFlag
                ? Icons.military_tech_rounded
                : Icons.flag_rounded,
            color: flag.isMajorFlag
                ? TeritoryColors.majorGold
                : TeritoryColors.primary,
            size: 22,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                flag.placeName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : TeritoryColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: flag.isMajorFlag
                    ? TeritoryColors.majorGold.withValues(alpha: 0.15)
                    : TeritoryColors.surfaceContainer,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                flag.isMajorFlag ? '★ MAJOR WONDER' : 'FLAG',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: flag.isMajorFlag
                      ? TeritoryColors.majorGoldDark
                      : TeritoryColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              '${flag.city}, ${flag.country} • ${flag.category}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: TeritoryColors.textSecondary,
              ),
            ),
            if (flag.authorName.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                'Staked by ${flag.authorName}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10.5,
                  color: TeritoryColors.textMuted,
                ),
              ),
            ],
          ],
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios_rounded,
          size: 14,
          color: TeritoryColors.textMuted,
        ),
      ),
    );
  }

  // Card for Geocoded / General Location result
  Widget _buildLocationCard(SearchLocation loc, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        onTap: () => _onSelectPlace(
          coordinates: loc.coordinates,
          title: loc.title,
          subtitle: loc.subtitle,
        ),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: TeritoryColors.majorGold.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.location_on_rounded,
            color: TeritoryColors.primary,
            size: 22,
          ),
        ),
        title: Text(
          loc.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : TeritoryColors.textPrimary,
          ),
        ),
        subtitle: Text(
          loc.subtitle.isNotEmpty
              ? loc.subtitle
              : 'Global Frontier • Tap to explore',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            color: TeritoryColors.textSecondary,
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: TeritoryColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Explore',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: TeritoryColors.primary,
            ),
          ),
        ),
      ),
    );
  }

  // Card for Explorer (User) result
  Widget _buildUserCard(ApiUser user, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        onTap: () {
          final nav = Navigator.of(context);
          nav.pop();
          FriendProfileScreen.open(nav.context, userId: user.id);
        },
        leading: CircleAvatar(
          radius: 20,
          backgroundColor: TeritoryColors.surfaceContainer,
          backgroundImage:
              user.avatarUrl.isNotEmpty ? NetworkImage(user.avatarUrl) : null,
          child: user.avatarUrl.isEmpty
              ? Text(
                  user.displayName.isEmpty
                      ? '?'
                      : user.displayName[0].toUpperCase(),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: TeritoryColors.primary,
                  ),
                )
              : null,
        ),
        title: Text(
          user.displayName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : TeritoryColors.textPrimary,
          ),
        ),
        subtitle: Text(
          '@${user.handle} • ${user.totalFlags} Flags Staked',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            color: TeritoryColors.textSecondary,
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: TeritoryColors.surfaceContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'View Profile',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: TeritoryColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }

  // Card for Clan result with Join & View actions
  Widget _buildClanCard(Clan clan, bool isDark) {
    final isJoining = _joiningClanIds.contains(clan.id);
    final myClans = ref.watch(clansProvider).valueOrNull?.myClanIds ?? <String>{};
    final currentUser = ref.watch(currentUserProvider);
    final isChieftain = currentUser.id.isNotEmpty && clan.chieftainId == currentUser.id;
    final isJoined = myClans.contains(clan.id) || isChieftain;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: InkWell(
        onTap: () {
          final nav = Navigator.of(context);
          nav.pop();
          nav.context.push('/clans/${clan.id}');
        },
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: TeritoryColors.clanPurple.withValues(alpha: 0.15),
                  backgroundImage: clan.coverImageUrl.isNotEmpty
                      ? NetworkImage(clan.coverImageUrl)
                      : null,
                  child: clan.coverImageUrl.isEmpty
                      ? const Icon(
                          Icons.shield_rounded,
                          color: TeritoryColors.clanPurple,
                          size: 20,
                        )
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        clan.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : TeritoryColors.textPrimary,
                        ),
                      ),
                      Text(
                        '${clan.region} • ${clan.memberCount} Explorers',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          color: TeritoryColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (clan.description.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                clan.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: isDark ? const Color(0xFF94A3B8) : TeritoryColors.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // View Clan button
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    final nav = Navigator.of(context);
                    nav.pop();
                    nav.context.push('/clans/${clan.id}');
                  },
                  child: Text(
                    'View Clan',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Join Clan button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isJoined
                        ? (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))
                        : TeritoryColors.primary,
                    foregroundColor: isJoined
                        ? (isDark ? Colors.white70 : TeritoryColors.textSecondary)
                        : Colors.white,
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: isJoined ? 0 : 2,
                  ),
                  onPressed: (isJoined || isJoining)
                      ? null
                      : () => _joinClan(clan),
                  child: isJoining
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          isJoined
                              ? (isChieftain ? 'Chieftain 👑' : 'Joined ✓')
                              : 'Join Clan',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  }
}
