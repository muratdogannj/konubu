import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel extends Equatable {
  final String uid;
  final String? email;
  final String? username; // Unique username for login
  final String? profileImageUrl;
  final String? gender; // 'male', 'female', 'other', 'prefer_not_to_say'
  final List<int> subscribedCities;
  final List<int> subscribedDistricts;
  final bool isModerator;
  final DateTime createdAt;
  
  // Statistics
  final int confessionCount;
  final int totalLikesReceived;
  final int totalLikesGiven;
  final int totalCommentsGiven;
  final int totalViewsReceived;
  
  // Badges
  final List<String> badges;
  final String currentBadge;
  
  // Notifications
  final String? fcmToken;
  final bool notificationsEnabled;
  final List<int> followedCities;
  
  // Notification Preferences
  final bool notifyOnLike;           // Konuma beğeni geldiğinde
  final bool notifyOnComment;        // Konuma yorum yapıldığında
  final bool notifyOnReply;          // Yorumuma yanıt verildiğinde
  final bool notifyOnCityConfession; // Takip ettiğim şehirden konu paylaşıldığında
  final bool notifyOnMessage;        // Yeni mesaj geldiğinde
  
  // Premium & Credits
  final bool isPremium;
  final DateTime? premiumExpiry;
  final int messageCredits;
  final int dailyMessageCount;
  final String? lastMessageReset;
  final int totalMessagesSent;
  
  // Dynamic Badge
  final int unreadNotificationCount;

  // Ban System
  final DateTime? bannedUntil;
  final String? banReason;

  bool get isBanned {
    if (bannedUntil == null) return false;
    return bannedUntil!.isAfter(DateTime.now());
  }

  const UserModel({
    required this.uid,
    this.email,
    this.username,
    this.profileImageUrl,
    this.gender,
    this.subscribedCities = const [],
    this.subscribedDistricts = const [],
    this.isModerator = false,
    required this.createdAt,
    this.confessionCount = 0,
    this.totalLikesReceived = 0,
    this.totalLikesGiven = 0,
    this.totalCommentsGiven = 0,
    this.totalViewsReceived = 0,
    this.badges = const [],
    this.currentBadge = '',
    this.fcmToken,
    this.notificationsEnabled = true,
    this.followedCities = const [],
    this.notifyOnLike = true,
    this.notifyOnComment = true,
    this.notifyOnReply = true,
    this.notifyOnCityConfession = true,
    this.notifyOnMessage = true,
    this.isPremium = false,
    this.premiumExpiry,
    this.messageCredits = 0,
    this.dailyMessageCount = 0,
    this.lastMessageReset,
    this.totalMessagesSent = 0,
    this.unreadNotificationCount = 0,
    this.bannedUntil,
    this.banReason,
  });

  factory UserModel.fromJson(Map<String, dynamic> json, String id) {
    return UserModel(
      uid: id,
      email: json['email'] as String?,
      username: json['username'] as String?,
      profileImageUrl: json['profileImageUrl'] as String?,
      gender: json['gender'] as String?,
      subscribedCities: (json['subscribedCities'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [],
      subscribedDistricts: (json['subscribedDistricts'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [],
      isModerator: json['isModerator'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      confessionCount: (json['confessionCount'] as num?)?.toInt() ?? 0,
      totalLikesReceived: (json['totalLikesReceived'] as num?)?.toInt() ?? 0,
      totalLikesGiven: (json['totalLikesGiven'] as num?)?.toInt() ?? 0,
      totalCommentsGiven: (json['totalCommentsGiven'] as num?)?.toInt() ?? 0,
      totalViewsReceived: (json['totalViewsReceived'] as num?)?.toInt() ?? 0,
      badges: (json['badges'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      currentBadge: json['currentBadge'] as String? ?? '',
      fcmToken: json['fcmToken'] as String?,
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      followedCities: (json['followedCities'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [],
      notifyOnLike: json['notifyOnLike'] as bool? ?? true,
      notifyOnComment: json['notifyOnComment'] as bool? ?? true,
      notifyOnReply: json['notifyOnReply'] as bool? ?? true,
      notifyOnCityConfession: json['notifyOnCityConfession'] as bool? ?? true,
      notifyOnMessage: json['notifyOnMessage'] as bool? ?? true,
      isPremium: json['isPremium'] as bool? ?? false,
      premiumExpiry: json['premiumExpiry'] != null
          ? (json['premiumExpiry'] as Timestamp).toDate()
          : null,
      messageCredits: (json['messageCredits'] as num?)?.toInt() ?? 0,
      dailyMessageCount: (json['dailyMessageCount'] as num?)?.toInt() ?? 0,
      lastMessageReset: json['lastMessageReset'] as String?,
      totalMessagesSent: (json['totalMessagesSent'] as num?)?.toInt() ?? 0,
      unreadNotificationCount: (json['unreadNotificationCount'] as num?)?.toInt() ?? 0,
      bannedUntil: json['bannedUntil'] != null
          ? (json['bannedUntil'] as Timestamp).toDate()
          : null,
      banReason: json['banReason'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'username': username,
      'profileImageUrl': profileImageUrl,
      'gender': gender,
      'subscribedCities': subscribedCities,
      'subscribedDistricts': subscribedDistricts,
      'isModerator': isModerator,
      'createdAt': createdAt.toIso8601String(),
      'confessionCount': confessionCount,
      'totalLikesReceived': totalLikesReceived,
      'totalLikesGiven': totalLikesGiven,
      'totalCommentsGiven': totalCommentsGiven,
      'totalViewsReceived': totalViewsReceived,
      'badges': badges,
      'currentBadge': currentBadge,
      'fcmToken': fcmToken,
      'notificationsEnabled': notificationsEnabled,
      'followedCities': followedCities,
      'notifyOnLike': notifyOnLike,
      'notifyOnComment': notifyOnComment,
      'notifyOnReply': notifyOnReply,
      'notifyOnCityConfession': notifyOnCityConfession,
      'notifyOnMessage': notifyOnMessage,
      'isPremium': isPremium,
      'premiumExpiry': premiumExpiry != null ? Timestamp.fromDate(premiumExpiry!) : null,
      'messageCredits': messageCredits,
      'dailyMessageCount': dailyMessageCount,
      'lastMessageReset': lastMessageReset,
      'totalMessagesSent': totalMessagesSent,
      'unreadNotificationCount': unreadNotificationCount,
      'bannedUntil': bannedUntil != null ? Timestamp.fromDate(bannedUntil!) : null,
      'banReason': banReason,
    };
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? username,
    String? profileImageUrl,
    String? gender,
    List<int>? subscribedCities,
    List<int>? subscribedDistricts,
    bool? isModerator,
    DateTime? createdAt,
    int? confessionCount,
    int? totalLikesReceived,
    int? totalLikesGiven,
    int? totalCommentsGiven,
    int? totalViewsReceived,
    List<String>? badges,
    String? currentBadge,
    String? fcmToken,
    bool? notificationsEnabled,
    List<int>? followedCities,
    bool? notifyOnLike,
    bool? notifyOnComment,
    bool? notifyOnReply,
    bool? notifyOnCityConfession,
    bool? notifyOnMessage,
    bool? isPremium,
    DateTime? premiumExpiry,
    int? messageCredits,
    int? dailyMessageCount,
    String? lastMessageReset,
    int? totalMessagesSent,
    int? unreadNotificationCount,
    DateTime? bannedUntil,
    String? banReason,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      username: username ?? this.username,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      gender: gender ?? this.gender,
      subscribedCities: subscribedCities ?? this.subscribedCities,
      subscribedDistricts: subscribedDistricts ?? this.subscribedDistricts,
      isModerator: isModerator ?? this.isModerator,
      createdAt: createdAt ?? this.createdAt,
      confessionCount: confessionCount ?? this.confessionCount,
      totalLikesReceived: totalLikesReceived ?? this.totalLikesReceived,
      totalLikesGiven: totalLikesGiven ?? this.totalLikesGiven,
      totalCommentsGiven: totalCommentsGiven ?? this.totalCommentsGiven,
      totalViewsReceived: totalViewsReceived ?? this.totalViewsReceived,
      badges: badges ?? this.badges,
      currentBadge: currentBadge ?? this.currentBadge,
      fcmToken: fcmToken ?? this.fcmToken,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      followedCities: followedCities ?? this.followedCities,
      notifyOnLike: notifyOnLike ?? this.notifyOnLike,
      notifyOnComment: notifyOnComment ?? this.notifyOnComment,
      notifyOnReply: notifyOnReply ?? this.notifyOnReply,
      notifyOnCityConfession: notifyOnCityConfession ?? this.notifyOnCityConfession,
      notifyOnMessage: notifyOnMessage ?? this.notifyOnMessage,
      isPremium: isPremium ?? this.isPremium,
      premiumExpiry: premiumExpiry ?? this.premiumExpiry,
      messageCredits: messageCredits ?? this.messageCredits,
      dailyMessageCount: dailyMessageCount ?? this.dailyMessageCount,
      lastMessageReset: lastMessageReset ?? this.lastMessageReset,
      totalMessagesSent: totalMessagesSent ?? this.totalMessagesSent,
      unreadNotificationCount: unreadNotificationCount ?? this.unreadNotificationCount,
      bannedUntil: bannedUntil ?? this.bannedUntil,
      banReason: banReason ?? this.banReason,
    );
  }

  @override
  List<Object?> get props => [
        uid,
        email,
        username,
        profileImageUrl,
        gender,
        subscribedCities,
        subscribedDistricts,
        isModerator,
        createdAt,
        confessionCount,
        totalLikesReceived,
        totalCommentsGiven,
        totalViewsReceived,
        badges,
        currentBadge,
        fcmToken,
        notificationsEnabled,
        followedCities,
        notifyOnLike,
        notifyOnComment,
        notifyOnReply,
        notifyOnCityConfession,
        notifyOnMessage,
        isPremium,
        premiumExpiry,
        messageCredits,
        dailyMessageCount,
        lastMessageReset,
        totalMessagesSent,
        unreadNotificationCount,
        bannedUntil,
        banReason,
      ];
}
