import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dedikodu_app/data/models/chat_room_model.dart';
import 'package:dedikodu_app/data/models/chat_message_model.dart';

class ChatRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  CollectionReference get _chatRoomsRef => _firestore.collection('chatRooms');

  /// Get all chat rooms (general + city rooms)
  Stream<List<ChatRoomModel>> getChatRooms() {
    return _chatRoomsRef
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ChatRoomModel.fromFirestore(doc))
          .toList();
    });
  }

  /// Get general chat room
  Future<ChatRoomModel?> getGeneralRoom() async {
    try {
      final doc = await _chatRoomsRef.doc('general').get();
      if (doc.exists) {
        return ChatRoomModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting general room: $e');
      return null;
    }
  }

  /// Get city chat room
  Future<ChatRoomModel?> getCityRoom(String cityId) async {
    try {
      final roomId = 'city_$cityId';
      final doc = await _chatRoomsRef.doc(roomId).get();
      if (doc.exists) {
        return ChatRoomModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting city room: $e');
      return null;
    }
  }

  /// Create or update chat room
  Future<void> createOrUpdateRoom(ChatRoomModel room) async {
    try {
      await _chatRoomsRef.doc(room.id).set(room.toFirestore(), SetOptions(merge: true));
    } catch (e) {
      print('Error creating/updating room: $e');
      rethrow;
    }
  }

  /// Get messages for a room (real-time stream)
  Stream<List<ChatMessageModel>> getMessages(String roomId, {int limit = 100}) {
    return _chatRoomsRef
        .doc(roomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ChatMessageModel.fromFirestore(doc, roomId))
          .toList();
    });
  }

  /// Send a message
  Future<void> sendMessage({
    required String roomId,
    required String userId,
    required String userName,
    required String message,
    required bool isAnonymous,
  }) async {
    try {
      final messageData = ChatMessageModel(
        id: '',
        roomId: roomId,
        userId: userId,
        userName: userName,
        isAnonymous: isAnonymous,
        message: message,
        timestamp: DateTime.now(),
      );

      // Add message to subcollection
      await _chatRoomsRef
          .doc(roomId)
          .collection('messages')
          .add(messageData.toFirestore());

      // Update room's last message
      await _chatRoomsRef.doc(roomId).update({
        'lastMessageAt': Timestamp.now(),
        'lastMessage': message.length > 50 
            ? '${message.substring(0, 50)}...' 
            : message,
      });
    } catch (e) {
      print('Error sending message: $e');
      rethrow;
    }
  }

  /// Like a message
  Future<void> likeMessage({
    required String roomId,
    required String messageId,
    required String userId,
  }) async {
    try {
      final messageRef = _chatRoomsRef
          .doc(roomId)
          .collection('messages')
          .doc(messageId);

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(messageRef);
        if (!snapshot.exists) return;

        final data = snapshot.data() as Map<String, dynamic>;
        final likedBy = List<String>.from(data['likedBy'] ?? []);

        if (likedBy.contains(userId)) {
          // Unlike
          likedBy.remove(userId);
        } else {
          // Like
          likedBy.add(userId);
        }

        transaction.update(messageRef, {
          'likedBy': likedBy,
          'likes': likedBy.length,
        });
      });
    } catch (e) {
      print('Error liking message: $e');
      rethrow;
    }
  }

  /// Report a message
  Future<void> reportMessage({
    required String roomId,
    required String messageId,
    required String userId,
  }) async {
    try {
      final messageRef = _chatRoomsRef
          .doc(roomId)
          .collection('messages')
          .doc(messageId);

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(messageRef);
        if (!snapshot.exists) return;

        final data = snapshot.data() as Map<String, dynamic>;
        final reportedBy = List<String>.from(data['reportedBy'] ?? []);

        if (!reportedBy.contains(userId)) {
          reportedBy.add(userId);
        }

        final reportCount = reportedBy.length;

        // If 5+ reports, delete message
        if (reportCount >= 5) {
          transaction.delete(messageRef);
        } else {
          transaction.update(messageRef, {
            'reportedBy': reportedBy,
            'reports': reportCount,
          });
        }
      });
    } catch (e) {
      print('Error reporting message: $e');
      rethrow;
    }
  }

  /// Delete a message (only by owner)
  Future<void> deleteMessage({
    required String roomId,
    required String messageId,
    required String userId,
  }) async {
    try {
      final messageRef = _chatRoomsRef
          .doc(roomId)
          .collection('messages')
          .doc(messageId);

      final snapshot = await messageRef.get();
      if (!snapshot.exists) return;

      final data = snapshot.data() as Map<String, dynamic>;
      if (data['userId'] == userId) {
        await messageRef.delete();
      }
    } catch (e) {
      print('Error deleting message: $e');
      rethrow;
    }
  }

  /// Initialize default rooms (call once)
  Future<void> initializeDefaultRooms() async {
    try {
      // Create general room
      final generalRoom = ChatRoomModel(
        id: 'general',
        name: 'Genel Sohbet',
        type: 'general',
        createdAt: DateTime.now(),
      );
      await createOrUpdateRoom(generalRoom);

      print('Default rooms initialized');
    } catch (e) {
      print('Error initializing rooms: $e');
    }
  }
}
