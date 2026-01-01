import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dedikodu_app/core/constants/app_constants.dart';
import 'package:dedikodu_app/data/models/confession_model.dart';
import 'package:dedikodu_app/core/utils/keyword_helper.dart';
import 'package:dedikodu_app/core/services/analytics_service.dart';

class ConfessionRepository {
  final FirebaseFirestore _firestore;

  ConfessionRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // Get approved confessions with optional filters
  Stream<List<ConfessionModel>> getConfessions({
    List<int>? cityPlateCodes,
    int? districtId,
    int limit = 20,
  }) {
    Query query = _firestore
        .collection(AppConstants.confessionsCollection)
        .where('status', isEqualTo: 'approved')
        .orderBy('createdAt', descending: true);
        // .limit(limit); // User requested all confessions

    return query.snapshots().map((snapshot) {
      // DEBUG: Log fetch count
      print('CONF_REPO: Fetched ${snapshot.docs.length} APPROVED docs from Firestore');
      
      var confessions = snapshot.docs
          .map((doc) => ConfessionModel.fromJson(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .toList();

      // Apply city filter - multiple cities (kept client-side to avoid index explosion for now)
      if (cityPlateCodes != null && cityPlateCodes.isNotEmpty) {
        print('CONF_REPO: Filtering for cities: $cityPlateCodes');
        confessions = confessions
            .where((c) {
               final matches = cityPlateCodes.contains(c.cityPlateCode);
               if (!matches) print('CONF_REPO: Doc ${c.id} skipped (City: ${c.cityPlateCode})');
               return matches;
            })
            .toList();
      }

      // Apply district filter
      if (districtId != null) {
        confessions = confessions
            .where((c) => c.districtId == districtId)
            .toList();
      }
      
      print('CONF_REPO: Returning ${confessions.length} confessions');

      return confessions;
    });
  }

  // Get single confession by ID
  Future<ConfessionModel?> getConfessionById(String id) async {
    final doc = await _firestore
        .collection(AppConstants.confessionsCollection)
        .doc(id)
        .get();

    if (!doc.exists) return null;

    return ConfessionModel.fromJson(
      doc.data() as Map<String, dynamic>,
      doc.id,
    );
  }

  // Search confessions by content keyword
  Future<List<ConfessionModel>> searchConfessions(String query) async {
    final keywords = KeywordHelper.generateKeywords(query);
    if (keywords.isEmpty) return [];
    
    // Firestore supports only one array-contains clause.
    // We use the first valid keyword to query.
    final searchTerm = keywords.first;

    final snapshot = await _firestore
        .collection(AppConstants.confessionsCollection)
        .where('status', isEqualTo: 'approved')
        .where('keywords', arrayContains: searchTerm)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .get();

    // Client-side filtering for subsequent keywords if any (optional but good for accuracy)
    var results = snapshot.docs
        .map((doc) => ConfessionModel.fromJson(doc.data(), doc.id))
        .toList();

    // If multiple keywords were typed (e.g. "red car"), we filtered by "red". 
    // Now filter by "car" locally to ensure full match intent.
    if (keywords.length > 1) {
      final otherKeywords = keywords.sublist(1);
      results = results.where((confession) {
        // Check if confession contains ALL other keywords
        // We check the 'keywords' field of the model itself which assumes it was populated
        return otherKeywords.every((k) => confession.keywords.contains(k));
      }).toList();
    }

    return results;
  }

  // Stream version of search for live updates
  Stream<List<ConfessionModel>> searchConfessionsStream(String query) {
    final keywords = KeywordHelper.generateKeywords(query);
    if (keywords.isEmpty) return Stream.value([]);
    
    final searchTerm = keywords.first;

    return _firestore
        .collection(AppConstants.confessionsCollection)
        .where('status', isEqualTo: 'approved')
        .where('keywords', arrayContains: searchTerm)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      var results = snapshot.docs
          .map((doc) => ConfessionModel.fromJson(doc.data(), doc.id))
          .toList();

      // Client-side filtering for subsequent keywords
      if (keywords.length > 1) {
        final otherKeywords = keywords.sublist(1);
        results = results.where((confession) {
          return otherKeywords.every((k) => confession.keywords.contains(k));
        }).toList();
      }
      return results;
    });
  }

  // Create new confession
  Future<String> createConfession(ConfessionModel confession) async {
    final confessionData = confession.toJson();
    // Use ServerTimestamp for consistent sorting and time across devices
    confessionData['createdAt'] = FieldValue.serverTimestamp();
    
    // Generate Keywords for Search with prefixes for partial matching
    confessionData['keywords'] = KeywordHelper.generateKeywords(confession.content, indexPrefixes: true);
    
    final docRef = await _firestore
        .collection(AppConstants.confessionsCollection)
        .add(confessionData);

    // Log to Analytics
    try {
      await AnalyticsService().logConfessionCreated(
        category: confession.cityName,
      );
    } catch (e) {
      // Ignore analytics errors
    }

    return docRef.id;
  }

  // Update confession
  Future<void> updateConfession(ConfessionModel confession) async {
    await _firestore
        .collection(AppConstants.confessionsCollection)
        .doc(confession.id)
        .update(confession.toJson());
  }

  // Delete confession
  // Delete confession (Cascading: Comments + Likes + User Stats)
  Future<void> deleteConfession(String id) async {
    // 1. Fetch Confession details first (to know author ID)
    final confessionDoc = await _firestore
        .collection(AppConstants.confessionsCollection)
        .doc(id)
        .get();

    if (!confessionDoc.exists) return;
    final confessionData = confessionDoc.data();
    final String? authorId = confessionData?['authorId'] as String?;

    final batch = _firestore.batch();

    // 2. Fetch and delete comments (Subcollection)
    final commentsSnapshot = await _firestore
        .collection(AppConstants.confessionsCollection)
        .doc(id)
        .collection('comments')
        .get();

    for (var doc in commentsSnapshot.docs) {
      batch.delete(doc.reference);
      // Cloud Function onCommentDeleted handles stats decrement
    }

    // 3. Fetch and delete likes (Root collection) & Update Liker Stats
    final likesSnapshot = await _firestore
        .collection('likes')
        .where('targetId', isEqualTo: id)
        .where('targetType', isEqualTo: 'confession')
        .get();

    int actualLikeCount = 0;

    for (var doc in likesSnapshot.docs) {
      actualLikeCount++;
      batch.delete(doc.reference);
      // Cloud Function onLikeDeleted handles 'totalLikesGiven' (Liker's stats) because it has userId in event.
      // BUT, it CANNOT handle 'totalLikesReceived' (Author's stats) because the Confession doc is deleted,
      // so it can't look up the authorId. We must do it here.
    }

    // Decrement Author's 'totalLikesReceived'
    if (authorId != null && actualLikeCount > 0) {
       batch.update(
          _firestore.collection('users').doc(authorId),
          {'totalLikesReceived': FieldValue.increment(-actualLikeCount)},
       );
    }

    // 4. Delete Confession Document
    batch.delete(confessionDoc.reference);

    await batch.commit();
  }

  // Update confession content
  Future<void> updateConfessionContent(String id, String newContent) async {
    await _firestore
        .collection(AppConstants.confessionsCollection)
        .doc(id)
        .update({
      'content': newContent,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Increment view count
  Future<void> incrementViewCount(String id) async {
    // Increment on confession
    await _firestore
        .collection(AppConstants.confessionsCollection)
        .doc(id)
        .update({
      'viewCount': FieldValue.increment(1),
    });
  }

  // Increment like count
  Future<void> incrementLikeCount(String id) async {
    await _firestore
        .collection(AppConstants.confessionsCollection)
        .doc(id)
        .update({
      'likeCount': FieldValue.increment(1),
    });
  }

  // Decrement like count
  Future<void> decrementLikeCount(String id) async {
    await _firestore
        .collection(AppConstants.confessionsCollection)
        .doc(id)
        .update({
      'likeCount': FieldValue.increment(-1),
    });
  }

  // Get pending confessions (for moderation)
  Stream<List<ConfessionModel>> getPendingConfessions() {
    return _firestore
        .collection(AppConstants.confessionsCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ConfessionModel.fromJson(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .where((confession) => confession.status == ConfessionStatus.pending)
          .toList();
    });
  }

  // Approve confession
  Future<void> approveConfession(String id, String moderatorId) async {
    // Get confession to find author
    final doc = await _firestore.collection(AppConstants.confessionsCollection).doc(id).get();
    final authorId = doc.data()?['authorId'] as String?;

    final batch = _firestore.batch();

    // 1. Update Confession Status
    batch.update(doc.reference, {
      'status': ConfessionStatus.approved.name,
      'approvedAt': DateTime.now().toIso8601String(),
      'moderatorId': moderatorId,
    });

    // 2. Increment User's Confession Count
    if (authorId != null) {
      batch.update(
        _firestore.collection(AppConstants.usersCollection).doc(authorId), 
        {'confessionCount': FieldValue.increment(1)}
      );
    }

    await batch.commit();
  }

  // Reject confession
  Future<void> rejectConfession(String id, String moderatorId) async {
    await _firestore
        .collection(AppConstants.confessionsCollection)
        .doc(id)
        .update({
      'status': ConfessionStatus.rejected.name,
      'moderatorId': moderatorId,
    });
  }

  // Get confessions by hashtag
  Stream<List<ConfessionModel>> getConfessionsByHashtag(String hashtag) {
    return _firestore
        .collection(AppConstants.confessionsCollection)
        .where('hashtags', arrayContains: hashtag.toLowerCase())
        .where('status', isEqualTo: ConfessionStatus.approved.name)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ConfessionModel.fromJson(
                doc.data(),
                doc.id,
              ))
          .toList();
    });
  }

  // Get confessions by author
  Stream<List<ConfessionModel>> getConfessionsByAuthor(String authorId, {bool includeAnonymous = true}) {
    return _firestore
        .collection(AppConstants.confessionsCollection)
        .where('authorId', isEqualTo: authorId)
        .where('status', isEqualTo: ConfessionStatus.approved.name)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      var confessions = snapshot.docs
          .map((doc) => ConfessionModel.fromJson(
                doc.data(),
                doc.id,
              ))
          .toList();
      
      if (!includeAnonymous) {
        confessions = confessions.where((c) => !c.isAnonymous).toList();
      }
      
      return confessions;
    });
  }
  // Get confessions by IDs
  Future<List<ConfessionModel>> getConfessionsByIds(List<String> ids) async {
    if (ids.isEmpty) return [];

    // Firestore allows max 10 items in 'whereIn' query
    // So we need to batch requests if ID list is larger
    List<ConfessionModel> allConfessions = [];
    
    // Split into chunks of 10
    for (var i = 0; i < ids.length; i += 10) {
      final end = (i + 10 < ids.length) ? i + 10 : ids.length;
      final chunk = ids.sublist(i, end);
      
      final snapshot = await _firestore
          .collection(AppConstants.confessionsCollection)
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
          
      final confessions = snapshot.docs
          .map((doc) => ConfessionModel.fromJson(doc.data(), doc.id))
          .toList();
          
      allConfessions.addAll(confessions);
    }
    
    return allConfessions;
  }
  // Get confessions for Admin (with optional status filter)
  Stream<List<ConfessionModel>> getConfessionsForAdmin({
    ConfessionStatus? status,
    int limit = 50,
  }) {
    Query query = _firestore
        .collection(AppConstants.confessionsCollection)
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (status != null) {
      query = query.where('status', isEqualTo: status.name);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => ConfessionModel.fromJson(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .toList();
    });
  }
}
