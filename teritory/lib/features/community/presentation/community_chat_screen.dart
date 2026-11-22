import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/config/app_config.dart';
import '../../../core/models/community_models.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/teritory_repository.dart';
import '../../../core/theme/teritory_theme.dart';
import '../../profile/presentation/friend_profile_screen.dart';
import '../application/community_detail_provider.dart';

class CommunityChatScreen extends ConsumerStatefulWidget {
  final String communityId;

  const CommunityChatScreen({super.key, required this.communityId});

  @override
  ConsumerState<CommunityChatScreen> createState() =>
      _CommunityChatScreenState();
}

class _CommunityChatScreenState extends ConsumerState<CommunityChatScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'just now';
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);
    try {
      await ref
          .read(communityMessagesProvider(widget.communityId).notifier)
          .sendMessage(text);
      if (!mounted) return;
      _controller.clear();
    } on ApiException catch (e) {
      _toast(e.message);
    } catch (_) {
      _toast('Could not send your message. Check your connection.');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _pickAndSendPhoto() async {
    if (_sending) return;
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (picked == null) return;

      setState(() => _sending = true);
      final url = await TeritoryRepository.instance.uploadImage(picked.path);
      await ref
          .read(communityMessagesProvider(widget.communityId).notifier)
          .sendMessage('', imageUrl: url);
    } catch (e) {
      _toast('Failed to upload image: $e');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: TeritoryColors.expiredRed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync =
        ref.watch(communityMessagesProvider(widget.communityId));
    final currentUserId = ref.watch(currentUserProvider).id;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Community Chat',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(
                    color: TeritoryColors.communityIndigo),
              ),
              error: (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.cloud_off_rounded,
                          size: 40, color: TeritoryColors.textMuted),
                      const SizedBox(height: 10),
                      Text(
                        error is ApiException
                            ? error.message
                            : 'Could not load messages.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: TeritoryColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton(
                        onPressed: () => ref.invalidate(
                            communityMessagesProvider(widget.communityId)),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (messages) {
                if (messages.isEmpty) {
                  return Center(
                    child: Text(
                      'No messages yet — say hello',
                      style: GoogleFonts.plusJakartaSans(
                        color: TeritoryColors.textMuted,
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    return _buildBubble(
                      message,
                      message.userId == currentUserId,
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: TeritoryColors.border, width: 1),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _sending ? null : _pickAndSendPhoto,
                    icon: const Icon(Icons.photo_camera_rounded),
                    color: TeritoryColors.communityIndigo,
                    tooltip: 'Send photo',
                  ),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      style: GoogleFonts.plusJakartaSans(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: GoogleFonts.plusJakartaSans(
                          color: TeritoryColors.textMuted,
                          fontSize: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide:
                              BorderSide(color: TeritoryColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide:
                              BorderSide(color: TeritoryColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(
                              color: TeritoryColors.communityIndigo,
                              width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _sending ? null : _send,
                    icon: _sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send_rounded),
                    color: TeritoryColors.primary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBubble(CommunityMessage msg, bool isSelf) {
    return Row(
      mainAxisAlignment:
          isSelf ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!isSelf) ...{
          _BubbleAvatar(
            userId: msg.userId,
            name: msg.userName,
            avatarUrl: msg.userAvatar,
          ),
          const SizedBox(width: 8),
        },
        Flexible(
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelf
                  ? TeritoryColors.chatBubbleSelf
                  : TeritoryColors.chatBubbleOther,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isSelf ? 16 : 4),
                bottomRight: Radius.circular(isSelf ? 4 : 16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isSelf)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      msg.userName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: TeritoryColors.communityIndigo,
                      ),
                    ),
                  ),
                if (msg.imageUrl != null ||
                    msg.text.startsWith('[Photo] ')) ...[
                  Builder(
                    builder: (context) {
                      // Older rows stored the image as `[Photo] <url>`; keep
                      // rendering them after the structured column landed.
                      final rawUrl = msg.imageUrl ??
                          msg.text.substring(8).trim();
                      final fullUrl = AppConfig.resolveMediaUrl(rawUrl);
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: fullUrl,
                          width: 200,
                          height: 150,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            width: 200,
                            height: 150,
                            color: Colors.black12,
                            child: const Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            width: 200,
                            height: 100,
                            color: Colors.black12,
                            child: const Icon(Icons.broken_image_rounded),
                          ),
                        ),
                      );
                    },
                  ),
                ] else
                  Text(
                    msg.text,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: isSelf ? Colors.white : TeritoryColors.textPrimary,
                      height: 1.4,
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  _timeAgo(msg.createdAt),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    color: isSelf
                        ? Colors.white.withValues(alpha: 0.6)
                        : TeritoryColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _BubbleAvatar extends StatelessWidget {
  final String userId;
  final String name;
  final String avatarUrl;

  const _BubbleAvatar({
    required this.userId,
    required this.name,
    required this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: userId.isNotEmpty
          ? () => FriendProfileScreen.open(context, userId: userId)
          : null,
      child: CircleAvatar(
        radius: 14,
        backgroundColor:
            TeritoryColors.communityIndigo.withValues(alpha: 0.15),
        backgroundImage: avatarUrl.isEmpty ? null : NetworkImage(avatarUrl),
        onBackgroundImageError: avatarUrl.isEmpty ? null : (_, _) {},
        child: avatarUrl.isEmpty
            ? Text(
                name.isEmpty ? '?' : name[0].toUpperCase(),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: TeritoryColors.communityIndigo,
                ),
              )
            : null,
      ),
    );
  }
}
