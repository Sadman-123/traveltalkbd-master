import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:traveltalkbd/diy_components/traveltalktheme.dart';
import 'package:traveltalkbd/diy_components/user_avatar.dart';
import 'package:traveltalkbd/services/auth_service.dart';
import 'package:traveltalkbd/services/chat_service.dart';

/// Chat screen for users to message support/admin
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chat = ChatService();
  final AuthService _auth = AuthService();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  StreamSubscription<List<ChatMessage>>? _messagesSub;
  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;

  String get _userId => _auth.currentUserId ?? '';

  @override
  void initState() {
    super.initState();
    if (_auth.isSignedIn) {
      _messagesSub = _chat.watchMessages(_userId).listen((messages) {
        if (mounted) {
          setState(() {
            _messages = messages;
            _isLoading = false;
          });
          _chat.markAsRead(_userId);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToBottom();
          });
        }
      });
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _messagesSub?.cancel();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    _textController.clear();

    try {
      await _chat.sendMessageFromUser(text);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: Traveltalktheme.primaryGradient,
          ),
        ),
        title: const Row(
          children: [
            Icon(Icons.support_agent, color: Colors.white),
            SizedBox(width: 8),
            Text('Support Chat', style: TextStyle(color: Colors.white)),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: !_auth.isSignedIn
          ? const Center(
              child: Text('Please sign in to chat with support.'),
            )
          : Column(
              children: [
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _messages.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.chat_bubble_outline,
                                    size: 64,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No messages yet',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Start the conversation!',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : FutureBuilder<Map<String, dynamic>?>(
                              future: _auth.getCurrentUserProfile(),
                              builder: (context, snapshot) {
                                final profile = snapshot.data;
                                final photoUrl =
                                    profile?['photoUrl'] as String? ??
                                        _auth.currentUser?.photoURL;
                                final name = profile?['displayName']
                                        as String? ??
                                    _auth.currentUser?.displayName ??
                                    _auth.currentUser?.email ??
                                    '';
                                final initials = name
                                        .trim()
                                        .isNotEmpty
                                    ? name.trim().substring(0, 1)
                                    : null;
                                return ListView.builder(
                                  controller: _scrollController,
                                  padding: const EdgeInsets.all(16),
                                  itemCount: _messages.length,
                                  itemBuilder: (context, i) {
                                    return _MessageBubble(
                                      message: _messages[i],
                                      showReadTick:
                                          _messages[i].isFromCurrentUser,
                                      currentUserPhotoUrl: photoUrl,
                                      currentUserInitials: initials,
                                    );
                                  },
                                );
                              },
                            ),
                ),
                _buildInputBar(),
              ],
            ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                maxLines: 4,
                minLines: 1,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _isSending ? null : _sendMessage,
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: _isSending
                        ? LinearGradient(
                            colors: [Colors.grey, Colors.grey.shade400],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          )
                        : Traveltalktheme.primaryGradient,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: _isSending
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool showReadTick;
  final String? currentUserPhotoUrl;
  final String? currentUserInitials;

  const _MessageBubble({
    required this.message,
    required this.showReadTick,
    this.currentUserPhotoUrl,
    this.currentUserInitials,
  });

  @override
  Widget build(BuildContext context) {
    final isMe = message.isFromCurrentUser;
    final avatarSize = 36.0;
    final bubbleMaxWidth = MediaQuery.of(context).size.width * 0.72;

    final avatar = isMe
        ? UserAvatar(
            photoUrl: currentUserPhotoUrl,
            initials: currentUserInitials,
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

    final bubble = Container(
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
          Text(
            message.text,
            style: TextStyle(
              color: isMe ? Colors.white : Colors.black87,
              fontSize: 15,
            ),
          ),
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
            ],
          ),
        ],
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
          Flexible(fit: FlexFit.loose, child: bubble),
          if (isMe) ...[
            const SizedBox(width: 8),
            avatar,
          ],
        ],
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
