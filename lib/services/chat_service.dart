import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:traveltalkbd/services/auth_service.dart';

/// Chat message model
class ChatMessage {
  final String id;
  final String text;
  final String? imageUrl;
  final String senderId;
  final String senderName;
  final int timestamp;
  final int? readAt;
  final Map<String, List<String>> reactions; // emoji -> [userId, ...]

  ChatMessage({
    required this.id,
    required this.text,
    this.imageUrl,
    required this.senderId,
    required this.senderName,
    required this.timestamp,
    this.readAt,
    this.reactions = const {},
  });

  factory ChatMessage.fromMap(String id, Map<dynamic, dynamic> map) {
    final reactionsRaw = map['reactions'];
    final reactions = <String, List<String>>{};
    if (reactionsRaw is Map) {
      for (final e in reactionsRaw.entries) {
        final val = e.value;
        List<String> list = [];
        if (val is List) {
          list = val.map((x) => x.toString()).toList();
        } else if (val is Map) {
          list = val.values.map((x) => x.toString()).toList();
        }
        if (list.isNotEmpty) {
          reactions[e.key.toString()] = list;
        }
      }
    }
    return ChatMessage(
      id: id,
      text: map['text']?.toString() ?? '',
      imageUrl: map['imageUrl']?.toString(),
      senderId: map['senderId']?.toString() ?? '',
      senderName: map['senderName']?.toString() ?? 'Unknown',
      timestamp: (map['timestamp'] as num?)?.toInt() ?? 0,
      readAt: (map['readAt'] as num?)?.toInt(),
      reactions: reactions,
    );
  }

  bool get isRead => readAt != null;
  bool get isFromCurrentUser => senderId == AuthService().currentUserId;
}

/// Conversation summary for admin list
class ChatConversation {
  final String userId;
  final String? userName;
  final String? userPhotoUrl;
  final String? lastMessage;
  final int lastActivity;
  final String? lastSenderId;
  final int unreadCount;

  ChatConversation({
    required this.userId,
    this.userName,
    this.userPhotoUrl,
    this.lastMessage,
    required this.lastActivity,
    this.lastSenderId,
    this.unreadCount = 0,
  });

  /// User is "active" if they sent last message within last 3 minutes
  bool get isUserActive {
    final diff = DateTime.now().millisecondsSinceEpoch - lastActivity;
    return lastSenderId == userId && diff < 3 * 60 * 1000;
  }
}

/// Service for real-time user-admin chat
class ChatService {
  static final ChatService _instance = ChatService._();
  factory ChatService() => _instance;

  ChatService._();

  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  DatabaseReference get _chatsRef => _db.child('chats');

  /// Get conversation ref for a user (user chats with admin)
  DatabaseReference _conversationRef(String userId) =>
      _chatsRef.child(userId);

  DatabaseReference _messagesRef(String userId) =>
      _conversationRef(userId).child('messages');

  /// Send a message from current user (customer) to admin
  Future<void> sendMessageFromUser(String text, {String? imageUrl}) async {
    final uid = AuthService().currentUserId;
    if (uid == null) throw StateError('User must be signed in to chat');
    await _sendMessage(uid, text, isFromAdmin: false, imageUrl: imageUrl);
  }

  /// Send a message from admin to a user
  Future<void> sendMessageFromAdmin(String userId, String text,
      {String? imageUrl}) async {
    await _sendMessage(userId, text, isFromAdmin: true, imageUrl: imageUrl);
  }

  Future<void> _sendMessage(String conversationUserId, String text,
      {required bool isFromAdmin, String? imageUrl}) async {
    final senderId = AuthService().currentUserId ?? 'admin';
    final profile = await AuthService().getCurrentUserProfile();
    final senderName = profile?['displayName'] as String? ??
        AuthService().currentUser?.displayName ??
        AuthService().currentUser?.email ??
        'Support';

    final msgData = <String, dynamic>{
      'text': text,
      'senderId': senderId,
      'senderName': senderName,
      'timestamp': ServerValue.timestamp,
      'readAt': null,
      'reactions': {},
    };
    if (imageUrl != null && imageUrl.isNotEmpty) {
      msgData['imageUrl'] = imageUrl;
    }
    final msgRef = _messagesRef(conversationUserId).push();
    await msgRef.set(msgData);

    final lastMsgDisplay = imageUrl != null ? '📷 Photo' : text;
    final updates = <String, dynamic>{
      'lastMessage': lastMsgDisplay,
      'lastActivity': ServerValue.timestamp,
      'lastSenderId': senderId,
      'lastMessageType': imageUrl != null ? 'image' : 'text',
    };
    if (!isFromAdmin && senderId == conversationUserId) {
      updates['userName'] = senderName;
      updates['userEmail'] = AuthService().currentUser?.email ?? '';
      final photoUrl = profile?['photoUrl'] as String? ??
          AuthService().currentUser?.photoURL;
      if (photoUrl != null && photoUrl.isNotEmpty) {
        updates['userPhotoUrl'] = photoUrl;
      }
    }
    await _conversationRef(conversationUserId).update(updates);
  }

  /// Stream of messages for a user's conversation
  Stream<List<ChatMessage>> watchMessages(String userId) {
    return _messagesRef(userId).orderByChild('timestamp').onValue.map((e) {
      if (!e.snapshot.exists) return <ChatMessage>[];
      final map = e.snapshot.value as Map<dynamic, dynamic>?;
      if (map == null) return <ChatMessage>[];
      final list = <ChatMessage>[];
      for (final entry in map.entries) {
        final data = entry.value as Map<dynamic, dynamic>?;
        if (data != null) {
          list.add(ChatMessage.fromMap(entry.key.toString(), data));
        }
      }
      list.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return list;
    });
  }

  /// Mark messages as read by current user (recipient viewing them)
  Future<void> markAsRead(String conversationUserId) async {
    final uid = AuthService().currentUserId;
    if (uid == null) return;

    final snapshot = await _messagesRef(conversationUserId).get();
    if (!snapshot.exists) return;

    final updates = <String, dynamic>{};
    for (final child in snapshot.children) {
      final data = child.value as Map<dynamic, dynamic>?;
      if (data == null) continue;
      final senderId = data['senderId']?.toString() ?? '';
      final readAt = data['readAt'];
      if (senderId != uid && readAt == null) {
        updates['${child.key}/readAt'] = ServerValue.timestamp;
      }
    }
    if (updates.isNotEmpty) {
      await _messagesRef(conversationUserId).update(updates);
    }
  }

  /// Stream of unread count for current user (customer)
  Stream<int> watchUnreadCountForUser() {
    final uid = AuthService().currentUserId;
    if (uid == null) return Stream.value(0);

    return _messagesRef(uid).orderByChild('timestamp').onValue.map((e) {
      if (!e.snapshot.exists) return 0;
      var count = 0;
      for (final child in e.snapshot.children) {
        final data = child.value as Map<dynamic, dynamic>?;
        if (data == null) continue;
        final senderId = data['senderId']?.toString() ?? '';
        final readAt = data['readAt'];
        if (senderId != uid && readAt == null) count++;
      }
      return count;
    });
  }

  /// Stream of all conversations for admin (users who have chatted)
  Stream<List<ChatConversation>> watchConversationsForAdmin() {
    return _chatsRef.onValue.map((e) {
      if (!e.snapshot.exists) return <ChatConversation>[];
      final map = e.snapshot.value as Map<dynamic, dynamic>?;
      if (map == null) return <ChatConversation>[];

      final list = <ChatConversation>[];
      for (final entry in map.entries) {
        final convData = entry.value as Map<dynamic, dynamic>?;
        if (convData == null) continue;
        final userId = entry.key.toString();
        final lastMsg = convData['lastMessage']?.toString();
        final lastActivity = (convData['lastActivity'] as num?)?.toInt() ?? 0;
        final lastSenderId = convData['lastSenderId']?.toString();

        final messages = convData['messages'] as Map<dynamic, dynamic>?;
        var unread = 0;
        if (messages != null) {
          for (final m in messages.values) {
            final msg = m as Map<dynamic, dynamic>?;
            if (msg == null) continue;
            final senderId = msg['senderId']?.toString() ?? '';
            final readAt = msg['readAt'];
            if (senderId == userId && readAt == null) unread++;
          }
        }

        list.add(ChatConversation(
          userId: userId,
          userName: convData['userName']?.toString(),
          userPhotoUrl: convData['userPhotoUrl']?.toString(),
          lastMessage: lastMsg,
          lastActivity: lastActivity,
          lastSenderId: lastSenderId,
          unreadCount: unread,
        ));
      }
      list.sort((a, b) => b.lastActivity.compareTo(a.lastActivity));
      return list;
    });
  }

  /// Get user display name for admin (from conversation or fallback)
  String getUserDisplayNameFromConversation(ChatConversation conv) {
    return conv.userName?.isNotEmpty == true
        ? conv.userName!
        : conv.userId;
  }

  /// Add or toggle reaction on a message
  Future<void> toggleReaction(
      String conversationUserId, String messageId, String emoji) async {
    final uid = AuthService().currentUserId;
    if (uid == null) return;

    final msgRef =
        _messagesRef(conversationUserId).child(messageId).child('reactions');
    final snapshot = await msgRef.child(emoji).get();

    if (snapshot.exists) {
      final list = List<String>.from(
          (snapshot.value as List?)?.map((x) => x.toString()) ?? []);
      if (list.contains(uid)) {
        list.remove(uid);
        if (list.isEmpty) {
          await msgRef.child(emoji).remove();
        } else {
          await msgRef.child(emoji).set(list);
        }
      } else {
        list.add(uid);
        await msgRef.child(emoji).set(list);
      }
    } else {
      await msgRef.child(emoji).set([uid]);
    }
  }
}
