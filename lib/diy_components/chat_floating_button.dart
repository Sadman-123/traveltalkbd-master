import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:traveltalkbd/diy_components/traveltalktheme.dart';
import 'package:traveltalkbd/services/auth_service.dart';
import 'package:traveltalkbd/services/chat_service.dart';
import 'package:traveltalkbd/screens/chat_screen.dart';
import 'package:traveltalkbd/mobile_related/data/travel_data_service.dart';
import 'package:url_launcher/url_launcher.dart';

/// Expandable support floating button for WebHome and MobileHome.
/// Main button: FAQ icon. Expands to show WhatsApp and Live Chat for clients.
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
  String? _whatsappUrl;

  @override
  void initState() {
    super.initState();
    _loadWhatsAppUrl();
    if (_auth.isSignedIn) {
      _unreadSub = _chat.watchUnreadCountForUser().listen((count) {
        if (mounted) setState(() => _unreadCount = count);
      });
    }
  }

  Future<void> _loadWhatsAppUrl() async {
    final content = await TravelDataService.getContent();
    final url = content.aboutInfo?.socialLinks['whatsapp']?.toString();
    if (mounted && url != null && url.isNotEmpty) {
      setState(() => _whatsappUrl = url);
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

  Future<void> _openWhatsApp() async {
    final url = _whatsappUrl;
    if (url == null || url.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('WhatsApp link is not configured.')),
        );
      }
      return;
    }
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open WhatsApp.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ExpandableFab(
      type: ExpandableFabType.up,
      distance: 72,
      openButtonBuilder: RotateFloatingActionButtonBuilder(
        child: _FaqMainButton(unreadCount: _unreadCount),
        fabSize: ExpandableFabSize.regular,
        foregroundColor: Colors.white,
        backgroundColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
      ),
      closeButtonBuilder: RotateFloatingActionButtonBuilder(
        child: _FaqMainButton(unreadCount: _unreadCount),
        fabSize: ExpandableFabSize.regular,
        foregroundColor: Colors.white,
        backgroundColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
      ),
      overlayStyle: ExpandableFabOverlayStyle(
        color: Colors.black.withValues(alpha: 0.3),
        blur: 4,
      ),
      children: [
        _SubButton(
          icon: FontAwesomeIcons.whatsapp,
          label: 'WhatsApp',
          onPressed: _openWhatsApp,
        ),
        _SubButton(
          icon: FontAwesomeIcons.headset,
          label: 'Live Chat',
          onPressed: _openChat,
        ),
      ],
    );
  }
}

class _FaqMainButton extends StatelessWidget {
  final int unreadCount;

  const _FaqMainButton({required this.unreadCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: Traveltalktheme.primaryGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
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
              Icons.help_outline_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          if (unreadCount > 0)
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
                  unreadCount > 99 ? '99+' : '$unreadCount',
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
    );
  }
}

class _SubButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _SubButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 12),
        Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(24),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(24),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: Traveltalktheme.primaryGradient,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Center(child: FaIcon(icon, color: Colors.white, size: 24),),
            ),
          ),
        ),
      ],
    );
  }
}
