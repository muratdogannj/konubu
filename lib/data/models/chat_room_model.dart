import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRoomModel {
  final String id;
  final String name;
  final String type; // 'general' or 'city'
  final String? cityId;
  final String? cityName;
  final DateTime createdAt;
  final DateTime? lastMessageAt;
  final int activeUsers;
  final String? lastMessage;

  ChatRoomModel({
    required this.id,
    required this.name,
    required this.type,
    this.cityId,
    this.cityName,
    required this.createdAt,
    this.lastMessageAt,
    this.activeUsers = 0,
    this.lastMessage,
  });

  factory ChatRoomModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatRoomModel(
      id: doc.id,
      name: data['name'] ?? '',
      type: data['type'] ?? 'general',
      cityId: data['cityId'],
      cityName: data['cityName'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastMessageAt: data['lastMessageAt'] != null
          ? (data['lastMessageAt'] as Timestamp).toDate()
          : null,
      activeUsers: data['activeUsers'] ?? 0,
      lastMessage: data['lastMessage'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'type': type,
      'cityId': cityId,
      'cityName': cityName,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastMessageAt': lastMessageAt != null
          ? Timestamp.fromDate(lastMessageAt!)
          : null,
      'activeUsers': activeUsers,
      'lastMessage': lastMessage,
    };
  }

  ChatRoomModel copyWith({
    String? id,
    String? name,
    String? type,
    String? cityId,
    String? cityName,
    DateTime? createdAt,
    DateTime? lastMessageAt,
    int? activeUsers,
    String? lastMessage,
  }) {
    return ChatRoomModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      cityId: cityId ?? this.cityId,
      cityName: cityName ?? this.cityName,
      createdAt: createdAt ?? this.createdAt,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      activeUsers: activeUsers ?? this.activeUsers,
      lastMessage: lastMessage ?? this.lastMessage,
    );
  }
}
