import 'package:equatable/equatable.dart';

class HashtagStatModel extends Equatable {
  final String hashtag;
  final int count;
  final DateTime lastUsed;
  final DateTime createdAt;

  const HashtagStatModel({
    required this.hashtag,
    required this.count,
    required this.lastUsed,
    required this.createdAt,
  });

  factory HashtagStatModel.fromJson(Map<String, dynamic> json) {
    return HashtagStatModel(
      hashtag: json['hashtag'] as String,
      count: json['count'] as int? ?? 0,
      lastUsed: DateTime.parse(json['lastUsed'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hashtag': hashtag,
      'count': count,
      'lastUsed': lastUsed.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  HashtagStatModel copyWith({
    String? hashtag,
    int? count,
    DateTime? lastUsed,
    DateTime? createdAt,
  }) {
    return HashtagStatModel(
      hashtag: hashtag ?? this.hashtag,
      count: count ?? this.count,
      lastUsed: lastUsed ?? this.lastUsed,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [hashtag, count, lastUsed, createdAt];
}
