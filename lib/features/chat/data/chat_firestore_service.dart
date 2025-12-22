import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatFirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  /// Update chat title with upsert (create if doesn't exist)
  Future<void> updateChatTitle(int chatId, String newTitle) async {
    if (currentUserId == null) return;

    await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('chat_sessions')
        .doc(chatId.toString())
        .set({
          'chatId': chatId,
          'title': newTitle,
          'lastMessageTime': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true)); // ← This ensures it creates if not exists
  }

  /// Save or update a chat session
  Future<void> saveChatSession({
    required int chatId,
    required String title,
    required DateTime lastMessageTime,
  }) async {
    if (currentUserId == null) return;

    await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('chat_sessions')
        .doc(chatId.toString())
        .set({
          'chatId': chatId,
          'title': title,
          'lastMessageTime': Timestamp.fromDate(lastMessageTime),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  /// Get all chat sessions for current user
  Stream<List<ChatSessionModel>> getChatSessions() {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('chat_sessions')
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return ChatSessionModel(
              chatId: data['chatId'] ?? 0,
              title: data['title'] ?? 'Untitled Chat',
              lastMessageTime:
                  (data['lastMessageTime'] as Timestamp?)?.toDate() ??
                  DateTime.now(),
            );
          }).toList();
        });
  }

  /// Delete a chat session
  Future<void> deleteChatSession(int chatId) async {
    if (currentUserId == null) return;

    await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('chat_sessions')
        .doc(chatId.toString())
        .delete();
  }

  /// Get a specific chat session
  Future<ChatSessionModel?> getChatSession(int chatId) async {
    if (currentUserId == null) return null;

    final doc = await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('chat_sessions')
        .doc(chatId.toString())
        .get();

    if (!doc.exists) return null;

    final data = doc.data()!;
    return ChatSessionModel(
      chatId: data['chatId'] ?? 0,
      title: data['title'] ?? 'Untitled Chat',
      lastMessageTime:
          (data['lastMessageTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Generate a title from the first user message
  String generateChatTitle(String message) {
    // Take first 50 characters or until first newline
    final title = message.split('\n').first;
    if (title.length > 50) {
      return '${title.substring(0, 50)}...';
    }
    return title;
  }
}

class ChatSessionModel {
  final int chatId;
  final String title;
  final DateTime lastMessageTime;

  ChatSessionModel({
    required this.chatId,
    required this.title,
    required this.lastMessageTime,
  });
}
