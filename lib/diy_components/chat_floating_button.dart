import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:traveltalkbd/diy_components/traveltalktheme.dart';
import 'package:traveltalkbd/services/auth_service.dart';
import 'package:traveltalkbd/services/chat_service.dart';
import 'package:traveltalkbd/screens/chat_screen.dart';

/// Floating chat button for WebHome and MobileHome
class ChatFloatingButton extends StatefulWidget {
  const ChatFloatingButton({super.key});

  @override
  State<ChatFloatingButton> createState() => _ChatFloatingButtonState();
}

class _ChatFloatingButtonState extends State<ChatFloatingButton> {
  final ChatService _chat = ChatService();
  final AuthService _auth = AuthService();
  StreamSubscription<int>? _unreadSub;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    if (_auth.isSignedIn) {
      _unreadSub = _chat.watchUnreadCountForUser().listen((count) {
        if (mounted) setState(() => _unreadCount = count);
      });
    }
  }

  @override
  void dispose() {
    _unreadSub?.cancel();
    super.dispose();
  }

  void _openChat() {
    if (!_auth.isSignedIn) {
      _showLoginPrompt();
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ChatScreen(),
      ),
    );
  }

  void _showLoginPrompt() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Login to Chat'),
        content: const Text(
          'Please sign in to chat with our support team.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Get.toNamed('/login');
            },
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(28),
      color: Colors.transparent,
      child: InkWell(
        onTap: _openChat,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: Traveltalktheme.primaryGradient,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const Center(
                child: Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              if (_unreadCount > 0)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      _unreadCount > 99 ? '99+' : '$_unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
