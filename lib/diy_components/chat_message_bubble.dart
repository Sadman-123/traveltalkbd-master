import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:traveltalkbd/diy_components/traveltalktheme.dart';
import 'package:traveltalkbd/diy_components/user_avatar.dart';
import 'package:traveltalkbd/services/chat_service.dart';
import 'package:traveltalkbd/services/cloudinary_service.dart';
import 'package:url_launcher/url_launcher.dart';

/// Common reaction emojis for chat
const List<String> kReactionEmojis = ['👍', '❤️', '😂', '😮', '😢', '🔥'];

/// Reusable chat message bubble with image, reactions, and reaction button
class ChatMessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool showReadTick;
  final String? currentUserPhotoUrl;
  final String? currentUserInitials;
  final String? otherUserPhotoUrl;
  final bool isAdminView;
  final void Function(String emoji)? onReaction;

  const ChatMessageBubble({
    required this.message,
    required this.showReadTick,
    this.currentUserPhotoUrl,
    this.currentUserInitials,
    this.otherUserPhotoUrl,
    this.isAdminView = false,
    this.onReaction,
  });

  @override
  Widget build(BuildContext context) {
    final isMe = message.isFromCurrentUser;
    final avatarSize = 36.0;
    final bubbleMaxWidth = MediaQuery.of(context).size.width * 0.72;

    final avatar = isMe
        ? (isAdminView
            ? _buildAdminAvatar(avatarSize)
            : UserAvatar(
                photoUrl: currentUserPhotoUrl,
                initials: currentUserInitials,
                size: avatarSize,
                showBorder: false,
              ))
        : (otherUserPhotoUrl != null && otherUserPhotoUrl!.isNotEmpty)
            ? UserAvatar(
                photoUrl: otherUserPhotoUrl,
                size: avatarSize,
                showBorder: false,
              )
            : CircleAvatar(
                radius: avatarSize / 2,
                backgroundColor: Traveltalktheme.primaryGradient.colors.first,
                child: Text(
                  message.senderName.isNotEmpty
                      ? message.senderName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              );

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            avatar,
            const SizedBox(width: 8),
          ],
          Flexible(
            fit: FlexFit.loose,
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                _buildBubble(context, isMe, bubbleMaxWidth),
                if (message.reactions.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Wrap(
                      spacing: 4,
                      runSpacing: 2,
                      children: [
                        for (final e in message.reactions.entries)
                          if (e.value.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${e.key} ${e.value.length > 1 ? e.value.length : ''}'
                                    .trim(),
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            avatar,
          ],
        ],
      ),
    );
  }

  Widget _buildAdminAvatar(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/trv2.png',
          fit: BoxFit.cover,
          alignment: Alignment.center,
        ),
      ),
    );
  }

  Widget _buildBubble(
      BuildContext context, bool isMe, double bubbleMaxWidth) {
    return GestureDetector(
      onLongPress: () => _showReactionMenu(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: bubbleMaxWidth),
        decoration: BoxDecoration(
          gradient: isMe ? Traveltalktheme.primaryGradient : null,
          color: isMe ? null : Colors.grey.shade200,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMe ? 18 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isMe && isAdminView)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  message.senderName,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            if (message.imageUrl != null && message.imageUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 240,
                    maxHeight: 200,
                  ),
                  child: Image.network(
                    message.imageUrl!,
                    fit: BoxFit.cover,
                    loadingBuilder: (_, child, progress) =>
                        progress == null
                            ? child
                            : const SizedBox(
                                height: 120,
                                child: Center(
                                    child: CircularProgressIndicator()),
                              ),
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.broken_image, size: 48),
                  ),
                ),
              ),
            if (message.text.isNotEmpty) ...[
              if (message.imageUrl != null && message.imageUrl!.isNotEmpty)
                const SizedBox(height: 6),
              Text(
                message.text,
                style: TextStyle(
                  color: isMe ? Colors.white : Colors.black87,
                  fontSize: 15,
                ),
              ),
            ],
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(message.timestamp),
                  style: TextStyle(
                    color: isMe ? Colors.white70 : Colors.grey.shade600,
                    fontSize: 11,
                  ),
                ),
                if (showReadTick && isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    message.isRead ? Icons.done_all : Icons.done,
                    size: 16,
                    color: message.isRead
                        ? Colors.blue.shade200
                        : Colors.white70,
                  ),
                ],
                if (message.imageUrl != null &&
                    message.imageUrl!.isNotEmpty) ...[
                  const SizedBox(width: 4),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 24, minHeight: 24),
                    iconSize: 18,
                    onPressed: () => _downloadImage(message.imageUrl!),
                    icon: Icon(
                      Icons.download_outlined,
                      color: isMe ? Colors.white70 : Colors.grey.shade600,
                      size: 18,
                    ),
                  ),
                ],
                const SizedBox(width: 4),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 24, minHeight: 24),
                  iconSize: 18,
                  onPressed: () => _showReactionMenu(context),
                  icon: Icon(
                    Icons.add_reaction_outlined,
                    color: isMe ? Colors.white70 : Colors.grey.shade600,
                    size: 18,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadImage(String url) async {
    try {
      final uri = Uri.parse(url);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // launchUrl may fail on some platforms
    }
  }

  void _showReactionMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (final emoji in kReactionEmojis)
                InkWell(
                  onTap: () {
                    Navigator.pop(ctx);
                    onReaction?.call(emoji);
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(emoji, style: const TextStyle(fontSize: 28)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(int timestamp) {
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    if (dt.day == now.day && dt.month == now.month && dt.year == now.year) {
      return DateFormat.jm().format(dt);
    }
    return DateFormat.MMMd().add_jm().format(dt);
  }
}

/// Helper to pick and upload image for chat
Future<String?> pickAndUploadChatImage() async {
  final picker = ImagePicker();
  final xfile = await picker.pickImage(
    source: ImageSource.gallery,
    maxWidth: 800,
    maxHeight: 800,
    imageQuality: 72,
  );
  if (xfile == null) return null;

  final bytes = await xfile.readAsBytes();
  final name = xfile.name;
  return CloudinaryService.uploadImageFromBytes(
    bytes,
    name.isNotEmpty ? name : 'chat_${DateTime.now().millisecondsSinceEpoch}.jpg',
    folder: 'traveltalkbd/chat',
  );
}
