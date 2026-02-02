import 'dart:async';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:traveltalkbd/diy_components/chat_message_bubble.dart'
    show ChatMessageBubble, pickAndUploadChatImage;
import 'package:traveltalkbd/diy_components/traveltalktheme.dart';
import 'package:traveltalkbd/diy_components/user_avatar.dart';
import 'package:traveltalkbd/services/chat_service.dart';

/// Admin tab for real-time chat with users
class AdminChatTab extends StatefulWidget {
  const AdminChatTab({super.key});

  @override
  State<AdminChatTab> createState() => _AdminChatTabState();
}

class _AdminChatTabState extends State<AdminChatTab> {
  final ChatService _chat = ChatService();
  StreamSubscription<List<ChatConversation>>? _conversationsSub;
  List<ChatConversation> _conversations = [];
  String? _selectedUserId;
  bool _isLoading = true;

  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _conversationsSub =
        _chat.watchConversationsForAdmin().listen(
      (conversations) {
        if (mounted) {
          setState(() {
            _conversations = conversations;
            _isLoading = false;
            _errorMessage = null;
          });
        }
      },
      onError: (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage =
                'Permission denied. Add your UID to admins in Firebase Database. See README.';
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _conversationsSub?.cancel();
    super.dispose();
  }

  String? _selectedUserName;
  String? _selectedUserPhotoUrl;
  int? _selectedLastActivity;

  void _selectUser(String userId, String displayName, String? photoUrl,
      int lastActivity) {
    setState(() {
      _selectedUserId = userId;
      _selectedUserName = displayName;
      _selectedUserPhotoUrl = photoUrl;
      _selectedLastActivity = lastActivity;
    });
  }

  void _backToList() {
    setState(() {
      _selectedUserId = null;
      _selectedUserName = null;
      _selectedUserPhotoUrl = null;
      _selectedLastActivity = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedUserId != null) {
      return _AdminChatConversation(
        userId: _selectedUserId!,
        userName: _selectedUserName ?? _selectedUserId!,
        userPhotoUrl: _selectedUserPhotoUrl,
        lastActivity: _selectedLastActivity ?? 0,
        onBack: _backToList,
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ],
          ),
        ),
      );
    }

    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _conversations.isEmpty
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
                      'No conversations yet',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Users will appear here when they start a chat',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _conversations.length,
                itemBuilder: (context, i) {
                  final conv = _conversations[i];
                  final displayName =
                      _chat.getUserDisplayNameFromConversation(conv);
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          conv.userPhotoUrl != null &&
                                  conv.userPhotoUrl!.isNotEmpty
                              ? UserAvatar(
                                  photoUrl: conv.userPhotoUrl,
                                  size: 44,
                                  showBorder: false,
                                )
                              : CircleAvatar(
                              backgroundColor:
                                  Traveltalktheme.primaryGradient.colors.first,
                              child: Text(
                                displayName.isNotEmpty
                                    ? displayName[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: conv.isUserActive
                                    ? Colors.green
                                    : Colors.grey.shade400,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      title: Text(
                        displayName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        conv.lastMessage ?? 'No messages',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                      trailing: conv.unreadCount > 0
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${conv.unreadCount}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            )
                          : null,
                      onTap: () => _selectUser(
                        conv.userId,
                        _chat.getUserDisplayNameFromConversation(conv),
                        conv.userPhotoUrl,
                        conv.lastActivity,
                      ),
                    ),
                  );
                },
              );
  }
}

class _AdminChatConversation extends StatefulWidget {
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final int lastActivity;
  final VoidCallback onBack;

  const _AdminChatConversation({
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    required this.lastActivity,
    required this.onBack,
  });

  @override
  State<_AdminChatConversation> createState() => _AdminChatConversationState();
}

class _AdminChatConversationState extends State<_AdminChatConversation> {
  final ChatService _chat = ChatService();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  StreamSubscription<List<ChatMessage>>? _messagesSub;
  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _messagesSub = _chat.watchMessages(widget.userId).listen((messages) {
      if (mounted) {
        setState(() {
          _messages = messages;
          _isLoading = false;
        });
        _chat.markAsRead(widget.userId);
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      }
    });
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

  Future<void> _sendMessage({String? imageUrl}) async {
    final text = _textController.text.trim();
    if ((text.isEmpty && imageUrl == null) || _isSending) return;

    setState(() => _isSending = true);
    if (text.isNotEmpty) _textController.clear();

    try {
      await _chat.sendMessageFromAdmin(
        widget.userId,
        text.isEmpty ? '📷' : text,
        imageUrl: imageUrl,
      );
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
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          decoration: BoxDecoration(
            gradient: Traveltalktheme.primaryGradient,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: widget.onBack,
              ),
              const SizedBox(width: 8),
              widget.userPhotoUrl != null && widget.userPhotoUrl!.isNotEmpty
                  ? UserAvatar(
                      photoUrl: widget.userPhotoUrl,
                      size: 44,
                      showBorder: false,
                    )
                  : CircleAvatar(
                      backgroundColor: Colors.white24,
                      child: Text(
                        widget.userName.isNotEmpty
                            ? widget.userName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.userName.isNotEmpty
                          ? widget.userName
                          : widget.userId,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Builder(
                      builder: (context) {
                        final lastTs = _messages.isNotEmpty
                            ? _messages.last.timestamp
                            : widget.lastActivity;
                        final diff =
                            DateTime.now().millisecondsSinceEpoch - lastTs;
                        final status = diff < 3 * 60 * 1000
                            ? 'Active now'
                            : timeago.format(
                                DateTime.fromMillisecondsSinceEpoch(lastTs),
                              );
                        return Text(
                          status,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _messages.isEmpty
                  ? Center(
                      child: Text(
                        'No messages yet. Start the conversation!',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length,
                      itemBuilder: (context, i) {
                        final msg = _messages[i];
                        return ChatMessageBubble(
                          message: msg,
                          showReadTick: msg.isFromCurrentUser,
                          otherUserPhotoUrl: widget.userPhotoUrl,
                          isAdminView: true,
                          onReaction: (emoji) =>
                              _chat.toggleReaction(widget.userId, msg.id, emoji),
                        );
                      },
                    ),
        ),
        Container(
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
                IconButton(
                  onPressed: _isSending
                      ? null
                      : () async {
                          final url = await pickAndUploadChatImage();
                          if (url != null && mounted) _sendMessage(imageUrl: url);
                        },
                  icon: Icon(
                    Icons.image_outlined,
                    color: _isSending ? Colors.grey : Colors.grey.shade700,
                  ),
                ),
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
                    onTap: _isSending ? null : () => _sendMessage(),
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
        ),
      ],
    );
  }
}
