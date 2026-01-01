import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String userId;
  final String displayName;
  final String? email;
  final bool isAnonymous;
  final bool isModerator;
  final bool isAdmin;
  
  // Statistics
  final int confessionCount;
  final int totalLikesReceived;
  final int totalCommentsGiven;
  final int totalViewsReceived;
  
  // Badge System
  final List<String> badges;
  final String currentBadge;
  
  // City follows
  final List<int> followedCities;
  
  final DateTime createdAt;
  final DateTime? updatedAt;

  UserProfile({
    required this.userId,
    required this.displayName,
    this.email,
    this.isAnonymous = false,
    this.isModerator = false,
    this.isAdmin = false,
    this.confessionCount = 0,
    this.totalLikesReceived = 0,
    this.totalCommentsGiven = 0,
    this.totalViewsReceived = 0,
    this.badges = const [],
    this.currentBadge = '',
    this.followedCities = const [],
    required this.createdAt,
    this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: json['userId'] ?? '',
      displayName: json['displayName'] ?? '',
      email: json['email'],
      isAnonymous: json['isAnonymous'] ?? false,
      isModerator: json['isModerator'] ?? false,
      isAdmin: json['isAdmin'] ?? false,
      confessionCount: json['confessionCount'] ?? 0,
      totalLikesReceived: json['totalLikesReceived'] ?? 0,
      totalCommentsGiven: json['totalCommentsGiven'] ?? 0,
      totalViewsReceived: json['totalViewsReceived'] ?? 0,
      badges: List<String>.from(json['badges'] ?? []),
      currentBadge: json['currentBadge'] ?? '',
      followedCities: List<int>.from(json['followedCities'] ?? []),
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.parse(json['createdAt']),
      updatedAt: json['updatedAt'] != null
          ? (json['updatedAt'] is Timestamp
              ? (json['updatedAt'] as Timestamp).toDate()
              : DateTime.parse(json['updatedAt']))
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'displayName': displayName,
      'email': email,
      'isAnonymous': isAnonymous,
      'isModerator': isModerator,
      'isAdmin': isAdmin,
      'confessionCount': confessionCount,
      'totalLikesReceived': totalLikesReceived,
      'totalCommentsGiven': totalCommentsGiven,
      'totalViewsReceived': totalViewsReceived,
      'badges': badges,
      'currentBadge': currentBadge,
      'followedCities': followedCities,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  UserProfile copyWith({
    String? userId,
    String? displayName,
    String? email,
    bool? isAnonymous,
    bool? isModerator,
    bool? isAdmin,
    int? confessionCount,
    int? totalLikesReceived,
    int? totalCommentsGiven,
    int? totalViewsReceived,
    List<String>? badges,
    String? currentBadge,
    List<int>? followedCities,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      isModerator: isModerator ?? this.isModerator,
      isAdmin: isAdmin ?? this.isAdmin,
      confessionCount: confessionCount ?? this.confessionCount,
      totalLikesReceived: totalLikesReceived ?? this.totalLikesReceived,
      totalCommentsGiven: totalCommentsGiven ?? this.totalCommentsGiven,
      totalViewsReceived: totalViewsReceived ?? this.totalViewsReceived,
      badges: badges ?? this.badges,
      currentBadge: currentBadge ?? this.currentBadge,
      followedCities: followedCities ?? this.followedCities,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
