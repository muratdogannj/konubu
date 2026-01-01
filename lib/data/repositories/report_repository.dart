import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dedikodu_app/data/models/report_model.dart';

class ReportRepository {
  final FirebaseFirestore _firestore;

  ReportRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // Create a new report
  Future<void> createReport(ReportModel report) async {
    await _firestore.collection('reports').add(report.toJson());
  }

  // Get all pending reports (for admin)
  Stream<List<ReportModel>> getPendingReports() {
    return _firestore
        .collection('reports')
        .where('status', isEqualTo: ReportStatus.pending.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ReportModel.fromJson(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  // Get all reports with optional status filter
  Stream<List<ReportModel>> getReports({ReportStatus? status}) {
    Query query = _firestore.collection('reports');
    
    if (status != null) {
      query = query.where('status', isEqualTo: status.name);
    }
    
    return query
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ReportModel.fromJson(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  // Update report status
  Future<void> updateReportStatus(
    String reportId,
    ReportStatus status,
    String moderatorId, {
    String? notes,
  }) async {
    await _firestore.collection('reports').doc(reportId).update({
      'status': status.name,
      'reviewedBy': moderatorId,
      'reviewedAt': DateTime.now().toIso8601String(),
      if (notes != null) 'reviewNotes': notes,
    });
  }

  // Dismiss report
  Future<void> dismissReport(String reportId, String moderatorId) async {
    await updateReportStatus(
      reportId,
      ReportStatus.dismissed,
      moderatorId,
    );
  }

  // Mark as action taken
  Future<void> markActionTaken(
    String reportId,
    String moderatorId, {
    String? notes,
  }) async {
    await updateReportStatus(
      reportId,
      ReportStatus.actionTaken,
      moderatorId,
      notes: notes,
    );
  }

  // Check if user already reported this content
  Future<bool> hasUserReported(String userId, String targetId) async {
    final snapshot = await _firestore
        .collection('reports')
        .where('reporterId', isEqualTo: userId)
        .where('targetId', isEqualTo: targetId)
        .get();
    
    return snapshot.docs.isNotEmpty;
  }

  // Get report count for a target
  Future<int> getReportCount(String targetId) async {
    final snapshot = await _firestore
        .collection('reports')
        .where('targetId', isEqualTo: targetId)
        .get();
    
    return snapshot.docs.length;
  }

  // Delete report
  Future<void> deleteReport(String reportId) async {
    await _firestore.collection('reports').doc(reportId).delete();
  }
}
