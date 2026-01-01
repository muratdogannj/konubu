import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dedikodu_app/data/models/like_model.dart';

class LikeRepository {
  final FirebaseFirestore _firestore;

  LikeRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // Toggle like (like if not liked, unlike if already liked)
  Future<bool> toggleLike({
    required String userId,
    required String targetType,
    required String targetId,
  }) async {
    final likeQuery = await _firestore
        .collection('likes')
        .where('userId', isEqualTo: userId)
        .where('targetType', isEqualTo: targetType)
        .where('targetId', isEqualTo: targetId)
        .limit(1)
        .get();

    if (likeQuery.docs.isNotEmpty) {
      // Unlike
      await likeQuery.docs.first.reference.delete();
      await _decrementLikeCount(targetType, targetId);
      return false;
    } else {
      // Like
      await _firestore.collection('likes').add({
        'userId': userId,
        'targetType': targetType,
        'targetId': targetId,
        'createdAt': DateTime.now().toIso8601String(),
      });
      await _incrementLikeCount(targetType, targetId);
      return true;
    }
  }

  // Check if user has liked
  Future<bool> hasUserLiked({
    required String userId,
    required String targetType,
    required String targetId,
  }) async {
    final likeQuery = await _firestore
        .collection('likes')
        .where('userId', isEqualTo: userId)
        .where('targetType', isEqualTo: targetType)
        .where('targetId', isEqualTo: targetId)
        .limit(1)
        .get();

    return likeQuery.docs.isNotEmpty;
  }

  // Get like count for a target
  Future<int> getLikeCount({
    required String targetType,
    required String targetId,
  }) async {
    final doc = await _firestore
        .collection(targetType == 'confession' ? 'confessions' : 'comments')
        .doc(targetId)
        .get();

    return (doc.data()?['likeCount'] as int?) ?? 0;
  }

  // Increment like count
  Future<void> _incrementLikeCount(String targetType, String targetId) async {
    final collection = targetType == 'confession' ? 'confessions' : 'comments';
    await _firestore.collection(collection).doc(targetId).update({
      'likeCount': FieldValue.increment(1),
    });
  }

  // Decrement like count
  Future<void> _decrementLikeCount(String targetType, String targetId) async {
    final collection = targetType == 'confession' ? 'confessions' : 'comments';
    await _firestore.collection(collection).doc(targetId).update({
      'likeCount': FieldValue.increment(-1),
    });
  }

  // Stream of like status for a user and target
  Stream<bool> likeStatusStream({
    required String userId,
    required String targetType,
    required String targetId,
  }) {
    return _firestore
        .collection('likes')
        .where('userId', isEqualTo: userId)
        .where('targetType', isEqualTo: targetType)
        .where('targetId', isEqualTo: targetId)
        .snapshots()
        .map((snapshot) => snapshot.docs.isNotEmpty);
  }
  // Get IDs of confessions liked by user
  Future<List<String>> getLikedConfessionIds(String userId) async {
    final snapshot = await _firestore
        .collection('likes')
        .where('userId', isEqualTo: userId)
        .where('targetType', isEqualTo: 'confession')
        .limit(50) // Limit to last 50 likes for performance
        .get();

    return snapshot.docs.map((doc) => doc.data()['targetId'] as String).toList();
  }
}
