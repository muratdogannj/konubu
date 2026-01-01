import 'package:equatable/equatable.dart';
import 'package:dedikodu_app/core/constants/app_constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ConfessionModel extends Equatable {
  final String id;
  final String content;
  final int cityPlateCode;
  final String cityName;
  final int? districtId;
  final String? districtName;
  final bool isAnonymous;
  final List<String> hashtags;
  final List<String> keywords;
  final String? authorId;
  final String? authorName;
  final String? authorImageUrl;
  final String? authorGender;
  final ConfessionStatus status;
  final int viewCount;
  final int likeCount;
  final int commentCount;
  final DateTime createdAt;
  final DateTime? approvedAt;
  final String? moderatorId;

  const ConfessionModel({
    required this.id,
    required this.content,
    required this.cityPlateCode,
    required this.cityName,
    this.districtId,
    this.districtName,
    required this.isAnonymous,
    this.hashtags = const [],
    this.keywords = const [],
    this.authorId,
    this.authorName,
    this.authorImageUrl,
    this.authorGender,
    required this.status,
    this.viewCount = 0,
    this.likeCount = 0,
    this.commentCount = 0,
    required this.createdAt,
    this.approvedAt,
    this.moderatorId,
  });

  factory ConfessionModel.fromJson(Map<String, dynamic> json, String id) {
    return ConfessionModel(
      id: id,
      content: json['content'] as String,
      cityPlateCode: json['cityPlateCode'] as int,
      cityName: json['cityName'] as String,
      districtId: json['districtId'] as int?,
      districtName: json['districtName'] as String?,
      isAnonymous: json['isAnonymous'] as bool,
      hashtags: (json['hashtags'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      keywords: (json['keywords'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      authorId: json['authorId'] as String?,
      authorName: json['authorName'] as String?,
      authorImageUrl: json['authorImageUrl'] as String?,
      authorGender: json['authorGender'] as String?,
      status: ConfessionStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ConfessionStatus.pending,
      ),
      viewCount: json['viewCount'] as int? ?? 0,
      likeCount: json['likeCount'] as int? ?? 0,
      commentCount: json['commentCount'] as int? ?? 0,
      createdAt: json['createdAt'] == null
          ? DateTime.now()
          : (json['createdAt'] is Timestamp
              ? (json['createdAt'] as Timestamp).toDate()
              : DateTime.parse(json['createdAt'] as String)),
      approvedAt: json['approvedAt'] == null
          ? null
          : (json['approvedAt'] is Timestamp
              ? (json['approvedAt'] as Timestamp).toDate()
              : DateTime.parse(json['approvedAt'] as String)),
      moderatorId: json['moderatorId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'cityPlateCode': cityPlateCode,
      'cityName': cityName,
      'districtId': districtId,
      'districtName': districtName,
      'isAnonymous': isAnonymous,
      'hashtags': hashtags,
      'keywords': keywords,
      'authorId': authorId,
      'authorName': authorName,
      'authorImageUrl': authorImageUrl,
      'authorGender': authorGender,
      'status': status.name,
      'viewCount': viewCount,
      'likeCount': likeCount,
      'commentCount': commentCount,
      'createdAt': createdAt.toIso8601String(),
      'approvedAt': approvedAt?.toIso8601String(),
      'moderatorId': moderatorId,
    };
  }

  ConfessionModel copyWith({
    String? id,
    String? content,
    int? cityPlateCode,
    String? cityName,
    int? districtId,
    String? districtName,
    bool? isAnonymous,
    List<String>? hashtags,
    List<String>? keywords,
    String? authorId,
    String? authorName,
    String? authorImageUrl,
    ConfessionStatus? status,
    int? viewCount,
    int? likeCount,
    int? commentCount,
    DateTime? createdAt,
    DateTime? approvedAt,
    String? moderatorId,
  }) {
    return ConfessionModel(
      id: id ?? this.id,
      content: content ?? this.content,
      cityPlateCode: cityPlateCode ?? this.cityPlateCode,
      cityName: cityName ?? this.cityName,
      districtId: districtId ?? this.districtId,
      districtName: districtName ?? this.districtName,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      hashtags: hashtags ?? this.hashtags,
      keywords: keywords ?? this.keywords,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorImageUrl: authorImageUrl ?? this.authorImageUrl,
      status: status ?? this.status,
      viewCount: viewCount ?? this.viewCount,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      createdAt: createdAt ?? this.createdAt,
      approvedAt: approvedAt ?? this.approvedAt,
      moderatorId: moderatorId ?? this.moderatorId,
    );
  }

  @override
  List<Object?> get props => [
        id,
        content,
        cityPlateCode,
        cityName,
        districtId,
        districtName,
        isAnonymous,
        hashtags,
        keywords,
        authorId,
        authorName,
        authorImageUrl,
        authorGender,
        status,
        viewCount,
        likeCount,
        commentCount,
        createdAt,
        approvedAt,
        moderatorId,
      ];
}
