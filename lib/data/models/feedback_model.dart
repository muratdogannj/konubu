import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum FeedbackType {
  complaint, // Şikayet
  suggestion, // Öneri
  other,     // Diğer
}

enum FeedbackStatus {
  open,
  read,
  closed,
}

class FeedbackModel extends Equatable {
  final String id;
  final String userId;
  final String? userName;
  final String? userEmail;
  final FeedbackType type;
  final String content;
  final FeedbackStatus status;
  final DateTime createdAt;
  final DateTime? closedAt;

  const FeedbackModel({
    required this.id,
    required this.userId,
    this.userName,
    this.userEmail,
    required this.type,
    required this.content,
    this.status = FeedbackStatus.open,
    required this.createdAt,
    this.closedAt,
  });

  factory FeedbackModel.fromJson(Map<String, dynamic> json, String id) {
    return FeedbackModel(
      id: id,
      userId: json['userId'] as String,
      userName: json['userName'] as String?,
      userEmail: json['userEmail'] as String?,
      type: FeedbackType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => FeedbackType.other,
      ),
      content: json['content'] as String,
      status: FeedbackStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => FeedbackStatus.open,
      ),
      createdAt: json['createdAt'] == null
          ? DateTime.now()
          : (json['createdAt'] is Timestamp
              ? (json['createdAt'] as Timestamp).toDate()
              : DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()),
      closedAt: json['closedAt'] == null
          ? null
          : (json['closedAt'] is Timestamp
              ? (json['closedAt'] as Timestamp).toDate()
              : DateTime.tryParse(json['closedAt'].toString())),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'type': type.name,
      'content': content,
      'status': status.name,
      'createdAt': FieldValue.serverTimestamp(),
      'closedAt': closedAt != null ? Timestamp.fromDate(closedAt!) : null,
    };
  }

  FeedbackModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userEmail,
    FeedbackType? type,
    String? content,
    FeedbackStatus? status,
    DateTime? createdAt,
    DateTime? closedAt,
  }) {
    return FeedbackModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      type: type ?? this.type,
      content: content ?? this.content,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      closedAt: closedAt ?? this.closedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        userName,
        userEmail,
        type,
        content,
        status,
        createdAt,
        closedAt,
      ];
      
  String get typeDisplay {
    switch (type) {
      case FeedbackType.complaint:
        return 'Şikayet';
      case FeedbackType.suggestion:
        return 'Öneri';
      case FeedbackType.other:
        return 'Diğer';
    }
  }
}
