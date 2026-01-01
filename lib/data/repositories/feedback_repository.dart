import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dedikodu_app/data/models/feedback_model.dart';

class FeedbackRepository {
  final FirebaseFirestore _firestore;

  FeedbackRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // Create new feedback
  Future<void> createFeedback(FeedbackModel feedback) async {
    await _firestore.collection('feedbacks').add(feedback.toJson());
  }

  // Get all feedbacks for admin (Stream)
  Stream<List<FeedbackModel>> getFeedbacksStream({
    FeedbackType? typeFilter,
    FeedbackStatus? statusFilter,
    int limit = 50,
  }) {
    Query query = _firestore.collection('feedbacks').orderBy('createdAt', descending: true);

    if (typeFilter != null) {
      query = query.where('type', isEqualTo: typeFilter.name);
    }

    if (statusFilter != null) {
      query = query.where('status', isEqualTo: statusFilter.name);
    }
    
    query = query.limit(limit);

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => FeedbackModel.fromJson(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .toList();
    });
  }

  // Mark feedback as read
  Future<void> markAsRead(String id) async {
    await _firestore.collection('feedbacks').doc(id).update({
      'status': FeedbackStatus.read.name,
    });
  }

  // Close feedback
  Future<void> closeFeedback(String id) async {
    await _firestore.collection('feedbacks').doc(id).update({
      'status': FeedbackStatus.closed.name,
      'closedAt': FieldValue.serverTimestamp(),
    });
  }
  
  // Update status manually
  Future<void> updateStatus(String id, FeedbackStatus status) async {
    final Map<String, dynamic> updates = {
      'status': status.name,
    };
    
    if (status == FeedbackStatus.closed) {
      updates['closedAt'] = FieldValue.serverTimestamp();
    }
    
    await _firestore.collection('feedbacks').doc(id).update(updates);
  }
}
