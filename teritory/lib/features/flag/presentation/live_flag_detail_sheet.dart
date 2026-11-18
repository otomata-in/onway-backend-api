import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/models/api_flag.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/teritory_repository.dart';
import '../../../core/theme/teritory_theme.dart';
import '../../explore/application/explore_flags_provider.dart';
import '../../trips/application/trips_provider.dart';

/// Live flag detail: reads `GET /v1/flags/:id` and writes reactions, kudos and
/// comments back to the API. Every surface that shows a flag opens this sheet.
class LiveFlagDetailSheet extends ConsumerStatefulWidget {
  final ApiFlag flag;

  const LiveFlagDetailSheet({super.key, required this.flag});

  static Future<void> show(BuildContext context, {required ApiFlag flag}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LiveFlagDetailSheet(flag: flag),
    );
  }

  @override
  ConsumerState<LiveFlagDetailSheet> createState() =>
      _LiveFlagDetailSheetState();
}

class _LiveFlagDetailSheetState extends ConsumerState<LiveFlagDetailSheet> {
  final TextEditingController _commentController = TextEditingController();
  final Set<String> _pendingReactions = {};
  bool _sendingComment = false;
  bool _sendingKudos = false;
  bool _savingWishlist = false;
  bool? _isSavedOverride;
  // `POST /flags/:id/kudos` always increments, so the sheet allows one send per
  // open instead of letting taps inflate the count.
  bool _kudosSent = false;
  int? _kudosOverride;

  static const Map<String, String> _reactionLabels = {
    'EPIC': '🔥 Epic',
    'HIDDEN_GEM': '💎 Hidden Gem',
    'GREAT_SHOT': '📸 Great Shot',
  };

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _toast(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? TeritoryColors.expiredRed : null,
      ),
    );
  }

  Future<void> _toggleReaction(String type) async {
    if (_pendingReactions.contains(type)) return;
    setState(() => _pendingReactions.add(type));
    try {
      await TeritoryRepository.instance.toggleFlagReaction(widget.flag.id, type);
      if (!mounted) return;
      ref.invalidate(flagDetailProvider(widget.flag.id));
      ref.invalidate(savedFlagsLiveProvider);
    } on ApiException catch (e) {
      _toast(e.message, error: true);
    } catch (_) {
      _toast('Could not save your reaction. Check your connection.', error: true);
    } finally {
      if (mounted) setState(() => _pendingReactions.remove(type));
    }
  }

  Future<void> _sendKudos() async {
    if (_sendingKudos || _kudosSent) return;
    setState(() => _sendingKudos = true);
    try {
      final kudos = await TeritoryRepository.instance.addFlagKudos(widget.flag.id);
      if (!mounted) return;
      setState(() {
        _kudosOverride = kudos;
        _kudosSent = true;
      });
    } on ApiException catch (e) {
      _toast(e.message, error: true);
    } catch (_) {
      _toast('Could not send kudos. Check your connection.', error: true);
    } finally {
      if (mounted) setState(() => _sendingKudos = false);
    }
  }

  Future<void> _toggleWishlist(bool currentSaved) async {
    if (_savingWishlist) return;
    setState(() => _savingWishlist = true);
    try {
      final isSaved =
          await TeritoryRepository.instance.toggleSaveFlag(widget.flag.id);
      if (!mounted) return;
      setState(() {
        _isSavedOverride = isSaved;
      });
      ref.invalidate(flagDetailProvider(widget.flag.id));
      ref.invalidate(savedFlagsLiveProvider);
      _toast(
        isSaved
            ? 'Added to your wishlist!'
            : 'Removed from your wishlist.',
      );
    } on ApiException catch (e) {
      _toast(e.message, error: true);
    } catch (_) {
      _toast(
        'Could not update wishlist. Check your connection.',
        error: true,
      );
    } finally {
      if (mounted) setState(() => _savingWishlist = false);
    }
  }

  Future<void> _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || _sendingComment) return;
    setState(() => _sendingComment = true);
    try {
      await TeritoryRepository.instance.postFlagComment(widget.flag.id, text);
      if (!mounted) return;
      _commentController.clear();
      ref.invalidate(flagDetailProvider(widget.flag.id));
      ref.invalidate(savedFlagsLiveProvider);
    } on ApiException catch (e) {
      _toast(e.message, error: true);
    } catch (_) {
      _toast('Could not post your comment. Check your connection.', error: true);
    } finally {
      if (mounted) setState(() => _sendingComment = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(flagDetailProvider(widget.flag.id));
    final currentUserId = ref.watch(currentUserProvider).id;
    final detail = detailAsync.valueOrNull;
    final flag = detail?.flag ?? widget.flag;

    final kudos = _kudosOverride ?? flag.kudos;
    final reactionCounts = detail?.reactionCounts ??
        const {'EPIC': 0, 'HIDDEN_GEM': 0, 'GREAT_SHOT': 0};
    final comments = detail?.comments ?? const <ApiFlagComment>[];

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

            if (flag.photoUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.network(
                  flag.photoUrl,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: flag.isMajorFlag
                              ? TeritoryColors.majorGoldLight
                              : TeritoryColors.primaryLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          flag.isMajorFlag ? 'MAJOR WONDER' : flag.category,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: flag.isMajorFlag
                                ? TeritoryColors.majorGoldDark
                                : TeritoryColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          [flag.city, flag.country]
                              .where((part) => part.isNotEmpty)
                              .join(', '),
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
                  Text(
                    flag.placeName,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: TeritoryColors.textPrimary,
                    ),
                  ),
                  if (flag.distanceKm > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${flag.distanceKm} km from map centre',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: TeritoryColors.textMuted,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: TeritoryColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: TeritoryColors.border,
                          backgroundImage: flag.authorAvatar.isNotEmpty
                              ? NetworkImage(flag.authorAvatar)
                              : null,
                          child: flag.authorAvatar.isEmpty
                              ? const Icon(Icons.person_rounded,
                                  size: 18, color: Colors.white)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                flag.isOwnedBy(currentUserId)
                                    ? '${flag.authorName} (you)'
                                    : flag.authorName,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: TeritoryColors.textPrimary,
                                ),
                              ),
                              Text(
                                flag.authorHandle.isEmpty
                                    ? 'Verified GPS footprint'
                                    : '@${flag.authorHandle}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  color: TeritoryColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.flag_rounded,
                          size: 16,
                          color: flag.isMajorFlag
                              ? TeritoryColors.majorGoldDark
                              : TeritoryColors.primary,
                        ),
                      ],
                    ),
                  ),

                  if (flag.notes.isNotEmpty) ...[
                    const SizedBox(height: 14),
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
                      '"${flag.notes}"',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        color: TeritoryColors.textPrimary,
                        height: 1.4,
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),

                  // ── Reactions ──────────────────────────────────────
                  if (detailAsync.isLoading && detail == null)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 6),
                      child: LinearProgressIndicator(minHeight: 2),
                    )
                  else if (detailAsync.hasError)
                    _InlineError(
                      message: 'Could not load reactions and comments.',
                      onRetry: () => ref
                          .invalidate(flagDetailProvider(widget.flag.id)),
                    ),

                  Row(
                    children: _reactionLabels.entries.map((entry) {
                      final type = entry.key;
                      final active =
                          detail?.hasReacted(currentUserId, type) ?? false;
                      final pending = _pendingReactions.contains(type);
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: entry.key == _reactionLabels.keys.last ? 0 : 8,
                          ),
                          child: GestureDetector(
                            onTap: pending ? null : () => _toggleReaction(type),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: active
                                    ? TeritoryColors.primaryLight
                                    : TeritoryColors.surfaceContainer,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: active
                                      ? TeritoryColors.primary
                                      : TeritoryColors.border,
                                  width: active ? 1.5 : 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    entry.value,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: active
                                          ? TeritoryColors.primary
                                          : TeritoryColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${reactionCounts[type] ?? 0}',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10,
                                      color: active
                                          ? TeritoryColors.primary
                                          : TeritoryColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed:
                              _sendingKudos || _kudosSent ? null : _sendKudos,
                          icon: Icon(
                            _sendingKudos
                                ? Icons.hourglass_top_rounded
                                : _kudosSent
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                            size: 18,
                            color: Colors.redAccent,
                          ),
                          label: Text(
                            '$kudos Kudos',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.bold,
                              color: TeritoryColors.textPrimary,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: const BorderSide(color: TeritoryColors.border),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _savingWishlist
                              ? null
                              : () {
                                  final isSaved = _isSavedOverride ??
                                      detail?.isSaved ??
                                      false;
                                  _toggleWishlist(isSaved);
                                },
                          icon: _savingWishlist
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Icon(
                                  (_isSavedOverride ?? detail?.isSaved ?? false)
                                      ? Icons.bookmark_added_rounded
                                      : Icons.bookmark_add_rounded,
                                  size: 18,
                                  color: (_isSavedOverride ??
                                          detail?.isSaved ??
                                          false)
                                      ? TeritoryColors.primary
                                      : null,
                                ),
                          label: Text(
                            (_isSavedOverride ?? detail?.isSaved ?? false)
                                ? 'Wishlisted'
                                : 'Wishlist',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.bold,
                              color: (_isSavedOverride ??
                                      detail?.isSaved ??
                                      false)
                                  ? TeritoryColors.primary
                                  : null,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(
                              color: (_isSavedOverride ??
                                      detail?.isSaved ??
                                      false)
                                  ? TeritoryColors.primary
                                  : TeritoryColors.border,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),
                  Text(
                    'Comments (${comments.length})',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: TeritoryColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (detail != null && comments.isEmpty)
                    Text(
                      'No comments yet. Be the first to add one.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: TeritoryColors.textMuted,
                      ),
                    ),
                  ...comments.map(_buildCommentTile),

                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _sendComment(),
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
                        color: _sendingComment
                            ? TeritoryColors.border
                            : TeritoryColors.primary,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          onTap: _sendingComment ? null : _sendComment,
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentTile(ApiFlagComment comment) {
    final diff = DateTime.now().difference(comment.createdAt);
    final timeAgo = diff.inDays > 0
        ? '${diff.inDays}d ago'
        : diff.inHours > 0
            ? '${diff.inHours}h ago'
            : diff.inMinutes > 0
                ? '${diff.inMinutes}m ago'
                : 'just now';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: TeritoryColors.border,
            backgroundImage: comment.userAvatar.isNotEmpty
                ? NetworkImage(comment.userAvatar)
                : null,
            child: comment.userAvatar.isEmpty
                ? const Icon(Icons.person_rounded,
                    size: 16, color: Colors.white)
                : null,
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
                      Expanded(
                        child: Text(
                          comment.userName,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: TeritoryColors.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        timeAgo,
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
}

class _InlineError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _InlineError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: TeritoryColors.expiredRed.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_rounded,
              size: 16, color: TeritoryColors.expiredRed),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: TeritoryColors.expiredRed,
              ),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: Text(
              'Retry',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
