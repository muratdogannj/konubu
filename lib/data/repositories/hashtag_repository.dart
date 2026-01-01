import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dedikodu_app/data/models/hashtag_stat_model.dart';

class HashtagRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Search hashtags by query
  Future<List<HashtagStatModel>> searchHashtags(String query) async {
    if (query.isEmpty) return [];

    try {
      final queryLower = query.toLowerCase();
      
      // Search for hashtags that start with the query
      // Using range query: hashtag >= query AND hashtag < query + 'z'
      final endQuery = queryLower.substring(0, queryLower.length - 1) +
          String.fromCharCode(queryLower.codeUnitAt(queryLower.length - 1) + 1);
      
      final querySnapshot = await _firestore
          .collection('hashtag_stats')
          .where('hashtag', isGreaterThanOrEqualTo: queryLower)
          .where('hashtag', isLessThan: endQuery)
          .orderBy('hashtag')
          .limit(10)
          .get();

      return querySnapshot.docs
          .map((doc) => HashtagStatModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Error searching hashtags: $e');
      return [];
    }
  }

  /// Get popular hashtags
  Future<List<HashtagStatModel>> getPopularHashtags({int limit = 20}) async {
    try {
      final querySnapshot = await _firestore
          .collection('hashtag_stats')
          .orderBy('count', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => HashtagStatModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting popular hashtags: $e');
      return [];
    }
  }

  /// Increment hashtag count (or create if doesn't exist)
  Future<void> incrementHashtagCount(String hashtag) async {
    if (hashtag.isEmpty) return;

    final hashtagLower = hashtag.toLowerCase();
    final docRef = _firestore.collection('hashtag_stats').doc(hashtagLower);

    try {
      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);

        if (doc.exists) {
          // Update existing
          transaction.update(docRef, {
            'count': FieldValue.increment(1),
            'lastUsed': DateTime.now().toIso8601String(),
          });
        } else {
          // Create new
          final newStat = HashtagStatModel(
            hashtag: hashtagLower,
            count: 1,
            lastUsed: DateTime.now(),
            createdAt: DateTime.now(),
          );
          transaction.set(docRef, newStat.toJson());
        }
      });
    } catch (e) {
      print('Error incrementing hashtag count: $e');
    }
  }

  /// Increment multiple hashtags at once
  Future<void> incrementHashtags(List<String> hashtags) async {
    for (final hashtag in hashtags) {
      await incrementHashtagCount(hashtag);
    }
  }

  /// Get hashtag statistics
  Future<HashtagStatModel?> getHashtagStat(String hashtag) async {
    try {
      final doc = await _firestore
          .collection('hashtag_stats')
          .doc(hashtag.toLowerCase())
          .get();

      if (doc.exists) {
        return HashtagStatModel.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error getting hashtag stat: $e');
      return null;
    }
  }
}
