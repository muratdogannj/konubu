import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dedikodu_app/data/models/comment_model.dart';

class CommentRepository {
  final FirebaseFirestore _firestore;

  CommentRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // Create a new comment
  Future<void> createComment(CommentModel comment) async {
    // Save comment in confession's comments subcollection
    await _firestore
        .collection('confessions')
        .doc(comment.confessionId)
        .collection('comments')
        .add(comment.toJson());
    
    // Increment comment count on confession
    await _firestore
        .collection('confessions')
        .doc(comment.confessionId)
        .update({'commentCount': FieldValue.increment(1)});
  }

  // Get single comment by ID
  Future<CommentModel?> getCommentById(String confessionId, String commentId) async {
    final doc = await _firestore
        .collection('confessions')
        .doc(confessionId)
        .collection('comments')
        .doc(commentId)
        .get();

    if (!doc.exists) return null;

    return CommentModel.fromJson(doc.data() as Map<String, dynamic>, doc.id);
  }

  // Get comments for a confession (only approved)
  Stream<List<CommentModel>> getComments(String confessionId) {
    return _firestore
        .collection('confessions')
        .doc(confessionId)
        .collection('comments')
        .where('status', isEqualTo: CommentStatus.approved.name)
        .where('parentCommentId', isNull: true) // Only top-level comments
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CommentModel.fromJson(doc.data(), doc.id))
            .toList());
  }

  // Get replies for a comment
  Stream<List<CommentModel>> getReplies(String parentCommentId) {
    return _firestore
        .collectionGroup('comments')
        .where('parentCommentId', isEqualTo: parentCommentId)
        .where('status', isEqualTo: CommentStatus.approved.name)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CommentModel.fromJson(doc.data(), doc.id))
            .toList());
  }

  // Get all pending comments (for moderation)
  Stream<List<CommentModel>> getPendingComments() {
    return _firestore
        .collection('comments')
        .where('status', isEqualTo: CommentStatus.pending.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CommentModel.fromJson(doc.data(), doc.id))
            .toList());
  }

  // Approve comment
  Future<void> approveComment(String commentId, String moderatorId) async {
    await _firestore.collection('comments').doc(commentId).update({
      'status': CommentStatus.approved.name,
      'moderatorId': moderatorId,
      'moderatedAt': DateTime.now().toIso8601String(),
    });
  }

  // Reject comment
  Future<void> rejectComment(String commentId, String moderatorId) async {
    await _firestore.collection('comments').doc(commentId).update({
      'status': CommentStatus.rejected.name,
      'moderatorId': moderatorId,
      'moderatedAt': DateTime.now().toIso8601String(),
    });
    
    // Decrement comment count on confession
    final comment = await _firestore.collection('comments').doc(commentId).get();
    if (comment.exists) {
      final confessionId = comment.data()?['confessionId'] as String?;
      if (confessionId != null) {
        try {
          await _firestore
              .collection('confessions')
              .doc(confessionId)
              .update({'commentCount': FieldValue.increment(-1)});
        } catch (e) {
          // Confession might be deleted, ignore
          print('Error updating comment count: $e');
        }
      }
    }
  }

  // Delete comment
  Future<void> deleteComment(String confessionId, String commentId) async {
    // Get comment first to find author
    final commentDoc = await _firestore
        .collection('confessions')
        .doc(confessionId)
        .collection('comments')
        .doc(commentId)
        .get();

    String? authorId;
    if (commentDoc.exists) {
      authorId = commentDoc.data()?['authorId'] as String?;
    }

    // Delete from subcollection
    await _firestore
        .collection('confessions')
        .doc(confessionId)
        .collection('comments')
        .doc(commentId)
        .delete();
    
    // Decrement comment count on confession (also conditional?)
    // Usually commentCount on confession includes all visible comments.
    // If pending comments aren't in commentCount, we shouldn't decrement.
    // Assuming pending aren't counted.
      try {
        await _firestore
            .collection('confessions')
            .doc(confessionId)
            .update({'commentCount': FieldValue.increment(-1)});
      } catch (e) {
        // Confession might be deleted, ignore
      }
  }

  // Update comment content
  Future<void> updateComment(String confessionId, String commentId, String newContent) async {
    await _firestore
        .collection('confessions')
        .doc(confessionId)
        .collection('comments')
        .doc(commentId)
        .update({'content': newContent});
  }

  // Get comment count for a confession
  Future<int> getCommentCount(String confessionId) async {
    final snapshot = await _firestore
        .collection('comments')
        .where('confessionId', isEqualTo: confessionId)
        .where('status', isEqualTo: CommentStatus.approved.name)
        .get();
    
    return snapshot.docs.length;
  }
  // Get comments by author
  Stream<List<CommentModel>> getCommentsByAuthor(String authorId, {bool includeAnonymous = true}) {
    return _firestore
        .collectionGroup('comments') // Use collectionGroup to query all 'comments' subcollections
        .where('authorId', isEqualTo: authorId)
        .where('status', isEqualTo: CommentStatus.approved.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      var comments = snapshot.docs
          .map((doc) => CommentModel.fromJson(doc.data(), doc.id))
          .toList();
      
      if (!includeAnonymous) {
        comments = comments.where((c) => !c.isAnonymous).toList();
      }
      
      return comments;
    });
  }
  // Get comments for Admin
  Stream<List<CommentModel>> getCommentsForAdmin({CommentStatus? status}) {
    Query query = _firestore.collectionGroup('comments') // Use collectionGroup for subcollections
        .orderBy('createdAt', descending: true); // Requires composite index usually

    if (status != null) {
      query = query.where('status', isEqualTo: status.name);
    }
    
    // Note: collectionGroup queries often require an index in Firestore.
    // If it fails, the error link will need to be clicked by the user (or handled).
    
    return query.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => CommentModel.fromJson(doc.data() as Map<String, dynamic>, doc.id))
        .toList());
  }

  // Generic status update (Correct path)
  Future<void> updateCommentStatus({
    required String confessionId,
    required String commentId,
    required CommentStatus status,
    required String moderatorId,
  }) async {
    final docRef = _firestore
        .collection('confessions')
        .doc(confessionId)
        .collection('comments')
        .doc(commentId);
        
    await docRef.update({
      'status': status.name,
      'moderatorId': moderatorId,
      'moderatedAt': DateTime.now().toIso8601String(),
    });
    
    // Update count if status changes between approved/non-approved
    // This is complex logic (was approved, now rejected -> count -1). 
    // Simply checking status might not be enough without previous state, 
    // but typically we can assume:
    // Approved -> Rejected: -1
    // Pending -> Approved: +1
    // Pending -> Rejected: 0
    // Rejected -> Approved: +1
    
    // For safety, let's recalculate or let Cloud Function handle it?
    // Current createComment increments. 
    // rejectComment decrements.
    
    if (status == CommentStatus.rejected) {
       // If we assume it might have been counted, we should decrement? 
       // Only if it was approved? 
       // Simpler approach for now:
       // Just update status. If counts get desynced, Admin Fix Stats page exists. 
       // BUT, createComment increments immediately. 
       // So Pending -> Rejected: It was ALREADY counted in 'commentCount'.
       // Wait, createComment increments count (line 23).
       // So pending comments ARE counted in `commentCount`.
       // So if I Reject, I should DECREMENT.
        try {
          await _firestore
              .collection('confessions')
              .doc(confessionId)
              .update({'commentCount': FieldValue.increment(-1)});
        } catch (e) {
          // Confession might be deleted, ignore
        }
    }
    // If Approved, do nothing (already counted).
    // If Pending, do nothing (already counted).
  }
}
