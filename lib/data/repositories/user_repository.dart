import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dedikodu_app/core/constants/app_constants.dart';
import 'package:dedikodu_app/data/models/user_model.dart';

class UserRepository {
  final FirebaseFirestore _firestore;

  UserRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // Get user by ID
  Future<UserModel?> getUserById(String uid) async {
    final doc = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .get();

    if (!doc.exists) return null;

    return UserModel.fromJson(doc.data() as Map<String, dynamic>, doc.id);
  }

  // Get user by username
  Future<UserModel?> getUserByUsername(String username) async {
    try {
      print('🔍 Searching for username: ${username.toLowerCase()}');
      
      final querySnapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .where('username', isEqualTo: username.toLowerCase())
          .limit(1)
          .get();

      print('📊 Query result: ${querySnapshot.docs.length} documents found');
      
      if (querySnapshot.docs.isEmpty) {
        print('❌ No user found with username: $username');
        return null;
      }

      final doc = querySnapshot.docs.first;
      print('✅ User found: ${doc.id}');
      return UserModel.fromJson(doc.data(), doc.id);
    } catch (e) {
      print('❌ Error in getUserByUsername: $e');
      rethrow;
    }
  }

  // Create new user
  Future<void> createUser(UserModel user) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(user.uid)
        .set(user.toJson());
  }

  // Update user
  Future<void> updateUser(UserModel user) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(user.uid)
        .set(user.toJson(), SetOptions(merge: true));
  }

  // Update specific user fields
  Future<void> updateUserFields(String userId, Map<String, dynamic> data) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .update(data);
  }

  // Delete user and all related data
  Future<void> deleteUser(String userId) async {
    try {
      // 1. Delete user's confessions
      final confessions = await _firestore
          .collection(AppConstants.confessionsCollection)
          .where('authorId', isEqualTo: userId)
          .get();
      for (var doc in confessions.docs) {
        await doc.reference.delete();
      }

      // 2. Delete user's comments (from all confessions)
      final allConfessions = await _firestore
          .collection(AppConstants.confessionsCollection)
          .get();
      for (var confession in allConfessions.docs) {
        final comments = await confession.reference
            .collection('comments')
            .where('authorId', isEqualTo: userId)
            .get();
        for (var comment in comments.docs) {
          await comment.reference.delete();
        }
      }

      // 3. Delete user's likes
      final likes = await _firestore
          .collection('likes')
          .where('userId', isEqualTo: userId)
          .get();
      for (var doc in likes.docs) {
        await doc.reference.delete();
      }

      // 4. Delete user's conversations
      final conversations = await _firestore
          .collection('conversations')
          .where('participants', arrayContains: userId)
          .get();
      for (var doc in conversations.docs) {
        // Delete messages in conversation
        final conversationId = doc.id;
        final messages = await _firestore
            .collection('private_messages')
            .doc(conversationId)
            .collection('messages')
            .get();
        for (var msg in messages.docs) {
          await msg.reference.delete();
        }
        // Delete conversation
        await doc.reference.delete();
      }

      // 5. Delete user's notifications
      final notifications = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .get();
      for (var doc in notifications.docs) {
        await doc.reference.delete();
      }

      // 6. Finally delete user document
      await _firestore.collection(AppConstants.usersCollection).doc(userId).delete();
      
    } catch (e) {
      print('Error deleting user data: $e');
      rethrow;
    }
  }

  // Subscribe to city
  Future<void> subscribeToCity(String uid, int cityPlateCode) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .update({
      'subscribedCities': FieldValue.arrayUnion([cityPlateCode]),
    });
  }

  // Unsubscribe from city
  Future<void> unsubscribeFromCity(String uid, int cityPlateCode) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .update({
      'subscribedCities': FieldValue.arrayRemove([cityPlateCode]),
    });
  }

  // Subscribe to district
  Future<void> subscribeToDistrict(String uid, int districtId) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .update({
      'subscribedDistricts': FieldValue.arrayUnion([districtId]),
    });
  }

  // Unsubscribe from district
  Future<void> unsubscribeFromDistrict(String uid, int districtId) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .update({
      'subscribedDistricts': FieldValue.arrayRemove([districtId]),
    });
  }

  // Get user stream
  Stream<UserModel?> getUserStream(String uid) {
    return _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromJson(doc.data() as Map<String, dynamic>, doc.id);
    });
  }

  // ========== Statistics Tracking Methods ==========

  /// Increment confession count
  Future<void> incrementConfessionCount(String uid) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .update({
      'confessionCount': FieldValue.increment(1),
    });
  }

  /// Increment total likes received
  Future<void> incrementLikesReceived(String uid) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .update({
      'totalLikesReceived': FieldValue.increment(1),
    });
  }

  /// Decrement total likes received
  Future<void> decrementLikesReceived(String uid) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .update({
      'totalLikesReceived': FieldValue.increment(-1),
    });
  }

  /// Increment total comments given
  Future<void> incrementCommentsGiven(String uid) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .update({
      'totalCommentsGiven': FieldValue.increment(1),
    });
  }

  /// Increment total views received
  Future<void> incrementViewsReceived(String uid, int count) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .update({
      'totalViewsReceived': FieldValue.increment(count),
    });
  }

  /// Update user badges
  Future<void> updateBadges(String uid, List<String> badges, String currentBadge) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .update({
      'badges': badges,
      'currentBadge': currentBadge,
    });
  }

  // ========== Notification Methods ==========

  /// Update FCM token
  Future<void> updateUserFCMToken(String uid, String token) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .update({
      'fcmToken': token,
      'tokenUpdatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Update notification settings
  Future<void> updateNotificationSettings(String uid, bool enabled) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .update({
      'notificationsEnabled': enabled,
    });
  }

  /// Update followed cities for notifications
  Future<void> updateFollowedCities(String uid, List<int> cityPlateCodes) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .update({
      'followedCities': cityPlateCodes,
    });
  }

  /// Add city to followed list
  Future<void> followCity(String uid, int cityPlateCode) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .update({
      'followedCities': FieldValue.arrayUnion([cityPlateCode]),
    });
  }

  /// Remove city from followed list
  Future<void> unfollowCity(String uid, int cityPlateCode) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .update({
      'followedCities': FieldValue.arrayRemove([cityPlateCode]),
    });
  }

  /// Check and update premium status if expired
  Future<void> checkAndUpdatePremiumStatus(String uid) async {
    try {
      final userDoc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .get();

      if (!userDoc.exists) return;

      final data = userDoc.data();
      if (data == null) return;

      final isPremium = data['isPremium'] as bool? ?? false;
      final premiumExpiry = data['premiumExpiry'] as Timestamp?;

      // If user is premium and has expiry date
      if (isPremium && premiumExpiry != null) {
        final expiryDate = premiumExpiry.toDate();
        final now = DateTime.now();

        // If premium has expired, revoke it
        if (now.isAfter(expiryDate)) {
          await _firestore
              .collection(AppConstants.usersCollection)
              .doc(uid)
              .update({
            'isPremium': false,
            'premiumExpiry': null,
          });
          print('Premium status revoked for user $uid (expired on $expiryDate)');
        }
      }
    } catch (e) {
      print('Error checking premium status: $e');
    }
  }

  /// Activate premium for user with specified duration
  /// Duration: 'monthly' (1 month), 'quarterly' (3 months), 'yearly' (12 months)
  Future<void> activatePremium(String uid, String duration) async {
    try {
      DateTime expiryDate;
      final now = DateTime.now();

      // Calculate expiry date based on duration
      switch (duration.toLowerCase()) {
        case 'monthly':
          expiryDate = DateTime(now.year, now.month + 1, now.day);
          break;
        case 'quarterly':
          expiryDate = DateTime(now.year, now.month + 3, now.day);
          break;
        case 'yearly':
          expiryDate = DateTime(now.year + 1, now.month, now.day);
          break;
        default:
          throw ArgumentError('Invalid duration: $duration. Use monthly, quarterly, or yearly');
      }

      // Update user document
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .update({
        'isPremium': true,
        'premiumExpiry': Timestamp.fromDate(expiryDate),
      });

      print('Premium activated for user $uid until $expiryDate');
    } catch (e) {
      print('Error activating premium: $e');
      rethrow;
    }
  }

  // ========== Ban Methods ==========

  /// Ban user for a specific duration or permanently
  Future<void> banUser(String uid, DateTime? bannedUntil, String reason) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .update({
        'bannedUntil': bannedUntil != null ? Timestamp.fromDate(bannedUntil) : null,
        'banReason': reason,
      });
      print('🚫 User $uid banned until $bannedUntil for: $reason');
    } catch (e) {
      print('❌ Error banning user: $e');
      rethrow;
    }
  }

  /// Unban user
  Future<void> unbanUser(String uid) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .update({
        'bannedUntil': null,
        'banReason': null,
      });
      print('✅ User $uid unbanned');
    } catch (e) {
      print('❌ Error unbanning user: $e');
      rethrow;
    }
  }

  // Recalculate and fix user statistics
  Future<void> recalculateUserStats(String uid) async {
    print('🔄 Recalculating stats for user: $uid');

    // 1. Count Confessions
    final confessionsSnapshot = await _firestore
        .collection(AppConstants.confessionsCollection)
        .where('authorId', isEqualTo: uid)
        .get();
    final confessionCount = confessionsSnapshot.docs.length;

    // 2. Sum Likes Received (from user's confessions)
    int totalLikesReceived = 0;
    int totalViewsReceived = 0;
    for (var doc in confessionsSnapshot.docs) {
      final data = doc.data();
      totalLikesReceived += (data['likeCount'] as num?)?.toInt() ?? 0;
      totalViewsReceived += (data['viewCount'] as num?)?.toInt() ?? 0;
    }

    // 3. Count Comments Given by User
    // Note: We need a collection group query or iterate all confessions?
    // Collection Group is more efficient but requires an index.
    // Let's use collectionGroup if available, or just keeping it simple for now as we don't know index state.
    // 'comments' is a subcollection. collectionGroup('comments').where('authorId'...) works!
    final commentsSnapshot = await _firestore
        .collectionGroup('comments')
        .where('authorId', isEqualTo: uid)
        .get();
    final totalCommentsGiven = commentsSnapshot.docs.length;

    // 4. Count Likes Given by User
    final likesGivenSnapshot = await _firestore
        .collection('likes')
        .where('userId', isEqualTo: uid)
        .get();
    final totalLikesGiven = likesGivenSnapshot.docs.length;

    print('✅ Stats Calculated: Confessions=$confessionCount, LikesRec=$totalLikesReceived, CommentsGiven=$totalCommentsGiven, LikesGiven=$totalLikesGiven');

    // 5. Update User Document
    await _firestore.collection(AppConstants.usersCollection).doc(uid).update({
      'confessionCount': confessionCount,
      'totalLikesReceived': totalLikesReceived,
      'totalViewsReceived': totalViewsReceived,
      'totalCommentsGiven': totalCommentsGiven,
      'totalLikesGiven': totalLikesGiven, // We might not be displaying this yet, but good to sync
    });

    print('💾 Stats updated in Firestore');
  }
}
