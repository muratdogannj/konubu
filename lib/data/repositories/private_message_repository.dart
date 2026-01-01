import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dedikodu_app/data/models/private_message_model.dart';
import 'package:dedikodu_app/data/models/conversation_model.dart';
import 'package:dedikodu_app/core/services/auth_service.dart';
import 'package:dedikodu_app/core/services/message_credit_service.dart';
import 'package:dedikodu_app/core/services/storage_service.dart';
import 'package:image_picker/image_picker.dart';

class PrivateMessageRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();
  final MessageCreditService _creditService = MessageCreditService();
  final StorageService _storageService = StorageService();

  /// Send a private message
  Future<bool> sendMessage({
    required String receiverId,
    required String content,
  }) async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) return false;

    // Kredi kontrolü
    final hasCredits = await _creditService.hasCredits();
    if (!hasCredits) return false;

    try {
      // Get user data from Firestore to access username
      final userDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();
      final username = userDoc.data()?['username'] ?? 'Anonim';

      // Conversation ID oluştur (alfabetik sıra)
      final conversationId = _getConversationId(currentUser.uid, receiverId);

      // Mesaj gönder
      final messageRef = _firestore
          .collection('private_messages')
          .doc(conversationId)
          .collection('messages')
          .doc();

      final message = PrivateMessage(
        id: messageRef.id,
        senderId: currentUser.uid,
        senderName: username,
        senderImageUrl: currentUser.photoURL,
        receiverId: receiverId,
        content: content,
        timestamp: DateTime.now(),
      );

      await messageRef.set(message.toJson());

      // Conversation güncelle
      await _updateConversation(
        conversationId: conversationId,
        senderId: currentUser.uid,
        receiverId: receiverId,
        lastMessage: content,
      );

      // Kredi kullan
      await _creditService.useCredit();

      return true;
    } catch (e) {
      print('Error sending message: $e');
      return false;
    }
  }

  /// Get conversation ID (alfabetik sıra)
  String _getConversationId(String userId1, String userId2) {
    final ids = [userId1, userId2]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  /// Update conversation
  Future<void> _updateConversation({
    required String conversationId,
    required String senderId,
    required String receiverId,
    required String lastMessage,
  }) async {
    final conversationRef = _firestore.collection('conversations').doc(conversationId);
    final conversationDoc = await conversationRef.get();

    if (conversationDoc.exists) {
      // Mevcut conversation'ı güncelle
      // Profil resimlerini de güncelle (kullanıcı resmi değişmiş olabilir)
      final senderDoc = await _firestore.collection('users').doc(senderId).get();
      final receiverDoc = await _firestore.collection('users').doc(receiverId).get();
      
      await conversationRef.update({
        'lastMessage': lastMessage,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'unreadCount.$receiverId': FieldValue.increment(1),
        'participantImages.$senderId': senderDoc.data()?['profileImageUrl'],
        'participantImages.$receiverId': receiverDoc.data()?['profileImageUrl'],
      });
    } else {
      // Yeni conversation oluştur
      final senderDoc = await _firestore.collection('users').doc(senderId).get();
      final receiverDoc = await _firestore.collection('users').doc(receiverId).get();

      await conversationRef.set({
        'participants': [senderId, receiverId],
        'lastMessage': lastMessage,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'unreadCount': {
          senderId: 0,
          receiverId: 1,
        },
        'participantNames': {
          senderId: senderDoc.data()?['username'] ?? 'Anonim',
          receiverId: receiverDoc.data()?['username'] ?? 'Anonim',
        },
        'participantImages': {
          senderId: senderDoc.data()?['profileImageUrl'],
          receiverId: receiverDoc.data()?['profileImageUrl'],
        },
      });
    }
  }

  /// Get messages stream for a conversation
  Stream<List<PrivateMessage>> getMessages(String otherUserId) {
    final currentUser = _authService.currentUser;
    if (currentUser == null) return Stream.value([]);

    final conversationId = _getConversationId(currentUser.uid, otherUserId);

    return _firestore
        .collection('private_messages')
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => PrivateMessage.fromJson(doc.data(), doc.id))
          .toList();
    });
  }

  /// Get user's conversations
  Stream<List<Conversation>> getConversations() {
    final currentUser = _authService.currentUser;
    if (currentUser == null) return Stream.value([]);

    return _firestore
        .collection('conversations')
        .where('participants', arrayContains: currentUser.uid)
        .snapshots()
        .map((snapshot) {
      final conversations = snapshot.docs
          .map((doc) => Conversation.fromJson(doc.data(), doc.id))
          .toList();
      
      // Sort by lastMessageTime descending (client-side)
      conversations.sort((a, b) {
        if (a.lastMessageTime == null && b.lastMessageTime == null) return 0;
        if (a.lastMessageTime == null) return 1;
        if (b.lastMessageTime == null) return -1;
        return b.lastMessageTime!.compareTo(a.lastMessageTime!);
      });
      
      return conversations;
    });
  }

  /// Mark messages as read
  Future<void> markAsRead(String otherUserId) async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) return;

    final conversationId = _getConversationId(currentUser.uid, otherUserId);

    // Conversation'daki unread count'u sıfırla (varsa)
    final conversationDoc = _firestore.collection('conversations').doc(conversationId);
    final docSnapshot = await conversationDoc.get();
    
    if (docSnapshot.exists) {
      await conversationDoc.update({
        'unreadCount.${currentUser.uid}': 0,
      });
    }

    // Mesajları read olarak işaretle
    final messagesSnapshot = await _firestore
        .collection('private_messages')
        .doc(conversationId)
        .collection('messages')
        .where('receiverId', isEqualTo: currentUser.uid)
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    for (var doc in messagesSnapshot.docs) {
      batch.update(doc.reference, {
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  /// Get total unread message count
  Future<int> getTotalUnreadCount() async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) return 0;

    final conversationsSnapshot = await _firestore
        .collection('conversations')
        .where('participants', arrayContains: currentUser.uid)
        .get();

    int totalUnread = 0;
    for (var doc in conversationsSnapshot.docs) {
      final data = doc.data();
      final unreadCount = data['unreadCount'] as Map<String, dynamic>?;
      totalUnread += (unreadCount?[currentUser.uid] as int?) ?? 0;
    }

    return totalUnread;
  }

  /// Delete conversation
  Future<void> deleteConversation(String otherUserId) async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) return;

    final conversationId = _getConversationId(currentUser.uid, otherUserId);

    // Mesajları sil
    final messagesSnapshot = await _firestore
        .collection('private_messages')
        .doc(conversationId)
        .collection('messages')
        .get();

    final batch = _firestore.batch();
    for (var doc in messagesSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // Conversation'ı sil
    batch.delete(_firestore.collection('conversations').doc(conversationId));

    await batch.commit();
  }

  /// Send image message
  Future<bool> sendImageMessage({
    required String receiverId,
    required XFile imageFile,
    bool isOneTime = false,
  }) async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) return false;

    // Kredi kontrolü
    final hasCredits = await _creditService.hasCredits();
    if (!hasCredits) return false;

    try {
      // Get user data
      final userDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();
      final username = userDoc.data()?['username'] ?? 'Anonim';

      // Conversation ID
      final conversationId = _getConversationId(currentUser.uid, receiverId);

      // Create message reference
      final messageRef = _firestore
          .collection('private_messages')
          .doc(conversationId)
          .collection('messages')
          .doc();

      // Upload image to Firebase Storage
      final imageUrl = await _storageService.uploadMessageImage(
        conversationId: conversationId,
        messageId: messageRef.id,
        imageFile: imageFile,
      );

      if (imageUrl == null) {
        return false;
      }

      // Create message
      final message = PrivateMessage(
        id: messageRef.id,
        senderId: currentUser.uid,
        senderName: username,
        senderImageUrl: currentUser.photoURL,
        receiverId: receiverId,
        content: isOneTime ? '🔥 Tek Kullanımlık Fotoğraf' : '📷 Fotoğraf',
        timestamp: DateTime.now(),
        imageUrl: imageUrl,
        isImage: true,
        isOneTime: isOneTime,
      );

      await messageRef.set(message.toJson());

      // Update conversation
      await _updateConversation(
        conversationId: conversationId,
        senderId: currentUser.uid,
        receiverId: receiverId,
        lastMessage: isOneTime ? '🔥 Tek Kullanımlık Fotoğraf' : '📷 Fotoğraf',
      );

      // Use credit
      await _creditService.useCredit();

      return true;
    } catch (e) {
      print('Error sending image message: $e');
      return false;
    }
  }

  /// Mark image as viewed and delete if one-time
  Future<void> markImageAsViewed(String messageId, String conversationId) async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) return;

    try {
      final messageRef = _firestore
          .collection('private_messages')
          .doc(conversationId)
          .collection('messages')
          .doc(messageId);

      final messageDoc = await messageRef.get();
      if (!messageDoc.exists) return;

      final message = PrivateMessage.fromJson(messageDoc.data()!, messageDoc.id);

      // If one-time and not viewed by current user
      if (message.isOneTime && !message.viewedBy.contains(currentUser.uid)) {
        // Add to viewedBy
        await messageRef.update({
          'viewedBy': FieldValue.arrayUnion([currentUser.uid]),
        });

        // Delete image from Storage and Firestore
        if (message.imageUrl != null) {
          await _storageService.deleteMessageImage(message.imageUrl!);
        }

        // Delete message after 3 seconds
        Future.delayed(const Duration(seconds: 3), () async {
          await messageRef.delete();
        });
      }
    } catch (e) {
      print('Error marking image as viewed: $e');
    }
  }
}
