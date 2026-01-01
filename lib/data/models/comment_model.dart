import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum CommentStatus {
  pending,
  approved,
  rejected,
}

class CommentModel extends Equatable {
  final String id;
  final String confessionId;
  final String content;
  final String authorId;
  final String authorName;
  final String? authorImageUrl;
  final bool isAnonymous;
  final int likeCount;
  final String? parentCommentId; // For replies
  final CommentStatus status;
  final DateTime createdAt;
  final String? moderatorId;
  final DateTime? moderatedAt;

  const CommentModel({
    required this.id,
    required this.confessionId,
    required this.content,
    required this.authorId,
    required this.authorName,
    this.authorImageUrl,
    required this.isAnonymous,
    this.likeCount = 0,
    this.parentCommentId,
    required this.status,
    required this.createdAt,
    this.moderatorId,
    this.moderatedAt,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json, String id) {
    return CommentModel(
      id: id,
      confessionId: json['confessionId'] as String,
      content: json['content'] as String,
      authorId: json['authorId'] as String,
      authorName: json['authorName'] as String,
      authorImageUrl: json['authorImageUrl'] as String?,
      isAnonymous: json['isAnonymous'] as bool,
      likeCount: json['likeCount'] as int? ?? 0,
      parentCommentId: json['parentCommentId'] as String?,
      status: CommentStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => CommentStatus.pending,
      ),
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.parse(json['createdAt'] as String),
      moderatorId: json['moderatorId'] as String?,
      moderatedAt: json['moderatedAt'] == null
          ? null
          : (json['moderatedAt'] is Timestamp
              ? (json['moderatedAt'] as Timestamp).toDate()
              : DateTime.parse(json['moderatedAt'] as String)),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'confessionId': confessionId,
      'content': content,
      'authorId': authorId,
      'authorName': authorName,
      'authorImageUrl': authorImageUrl,
      'isAnonymous': isAnonymous,
      'likeCount': likeCount,
      'parentCommentId': parentCommentId,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'moderatorId': moderatorId,
      'moderatedAt': moderatedAt?.toIso8601String(),
    };
  }

  CommentModel copyWith({
    String? id,
    String? confessionId,
    String? content,
    String? authorId,
    String? authorName,
    String? authorImageUrl,
    bool? isAnonymous,
    int? likeCount,
    String? parentCommentId,
    CommentStatus? status,
    DateTime? createdAt,
    String? moderatorId,
    DateTime? moderatedAt,
  }) {
    return CommentModel(
      id: id ?? this.id,
      confessionId: confessionId ?? this.confessionId,
      content: content ?? this.content,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorImageUrl: authorImageUrl ?? this.authorImageUrl,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      likeCount: likeCount ?? this.likeCount,
      parentCommentId: parentCommentId ?? this.parentCommentId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      moderatorId: moderatorId ?? this.moderatorId,
      moderatedAt: moderatedAt ?? this.moderatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        confessionId,
        content,
        authorId,
        authorName,
        authorImageUrl,
        isAnonymous,
        likeCount,
        parentCommentId,
        status,
        createdAt,
        moderatorId,
        moderatedAt,
      ];
}
