import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessageModel {
  final String id;
  final String roomId;
  final String userId;
  final String userName;
  final bool isAnonymous;
  final String message;
  final DateTime timestamp;
  final int likes;
  final int reports;
  final List<String> likedBy;
  final List<String> reportedBy;

  ChatMessageModel({
    required this.id,
    required this.roomId,
    required this.userId,
    required this.userName,
    required this.isAnonymous,
    required this.message,
    required this.timestamp,
    this.likes = 0,
    this.reports = 0,
    this.likedBy = const [],
    this.reportedBy = const [],
  });

  factory ChatMessageModel.fromFirestore(DocumentSnapshot doc, String roomId) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatMessageModel(
      id: doc.id,
      roomId: roomId,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Anonim',
      isAnonymous: data['isAnonymous'] ?? true,
      message: data['message'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      likes: data['likes'] ?? 0,
      reports: data['reports'] ?? 0,
      likedBy: List<String>.from(data['likedBy'] ?? []),
      reportedBy: List<String>.from(data['reportedBy'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userName': userName,
      'isAnonymous': isAnonymous,
      'message': message,
      'timestamp': Timestamp.fromDate(timestamp),
      'likes': likes,
      'reports': reports,
      'likedBy': likedBy,
      'reportedBy': reportedBy,
    };
  }

  ChatMessageModel copyWith({
    String? id,
    String? roomId,
    String? userId,
    String? userName,
    bool? isAnonymous,
    String? message,
    DateTime? timestamp,
    int? likes,
    int? reports,
    List<String>? likedBy,
    List<String>? reportedBy,
  }) {
    return ChatMessageModel(
      id: id ?? this.id,
      roomId: roomId ?? this.roomId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      likes: likes ?? this.likes,
      reports: reports ?? this.reports,
      likedBy: likedBy ?? this.likedBy,
      reportedBy: reportedBy ?? this.reportedBy,
    );
  }

  String get displayName {
    return isAnonymous ? 'Anonim' : userName;
  }

  bool isLikedBy(String userId) {
    return likedBy.contains(userId);
  }

  bool isReportedBy(String userId) {
    return reportedBy.contains(userId);
  }
}
