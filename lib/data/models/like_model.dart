import 'package:equatable/equatable.dart';

class LikeModel extends Equatable {
  final String id;
  final String userId;
  final String targetType; // 'confession' or 'comment'
  final String targetId;
  final DateTime createdAt;

  const LikeModel({
    required this.id,
    required this.userId,
    required this.targetType,
    required this.targetId,
    required this.createdAt,
  });

  factory LikeModel.fromJson(Map<String, dynamic> json, String id) {
    return LikeModel(
      id: id,
      userId: json['userId'] as String,
      targetType: json['targetType'] as String,
      targetId: json['targetId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'targetType': targetType,
      'targetId': targetId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, userId, targetType, targetId, createdAt];
}
