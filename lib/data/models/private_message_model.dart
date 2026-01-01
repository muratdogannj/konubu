import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class PrivateMessage extends Equatable {
  final String id;
  final String senderId;
  final String senderName;
  final String? senderImageUrl;
  final String receiverId;
  final String content;
  final DateTime timestamp;
  final bool isRead;
  final DateTime? readAt;
  final String? imageUrl;
  final bool isImage;
  final bool isOneTime;
  final List<String> viewedBy;

  const PrivateMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.senderImageUrl,
    required this.receiverId,
    required this.content,
    required this.timestamp,
    this.isRead = false,
    this.readAt,
    this.imageUrl,
    this.isImage = false,
    this.isOneTime = false,
    this.viewedBy = const [],
  });

  factory PrivateMessage.fromJson(Map<String, dynamic> json, String id) {
    return PrivateMessage(
      id: id,
      senderId: json['senderId'] as String,
      senderName: json['senderName'] as String,
      senderImageUrl: json['senderImageUrl'] as String?,
      receiverId: json['receiverId'] as String,
      content: json['content'] as String,
      timestamp: (json['timestamp'] as Timestamp).toDate(),
      isRead: json['isRead'] as bool? ?? false,
      readAt: json['readAt'] != null
          ? (json['readAt'] as Timestamp).toDate()
          : null,
      imageUrl: json['imageUrl'] as String?,
      isImage: json['isImage'] as bool? ?? false,
      isOneTime: json['isOneTime'] as bool? ?? false,
      viewedBy: (json['viewedBy'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'senderImageUrl': senderImageUrl,
      'receiverId': receiverId,
      'content': content,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      'readAt': readAt != null ? Timestamp.fromDate(readAt!) : null,
      'imageUrl': imageUrl,
      'isImage': isImage,
      'isOneTime': isOneTime,
      'viewedBy': viewedBy,
    };
  }

  PrivateMessage copyWith({
    String? id,
    String? senderId,
    String? senderName,
    String? senderImageUrl,
    String? receiverId,
    String? content,
    DateTime? timestamp,
    bool? isRead,
    DateTime? readAt,
    String? imageUrl,
    bool? isImage,
    bool? isOneTime,
    List<String>? viewedBy,
  }) {
    return PrivateMessage(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderImageUrl: senderImageUrl ?? this.senderImageUrl,
      receiverId: receiverId ?? this.receiverId,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      imageUrl: imageUrl ?? this.imageUrl,
      isImage: isImage ?? this.isImage,
      isOneTime: isOneTime ?? this.isOneTime,
      viewedBy: viewedBy ?? this.viewedBy,
    );
  }

  @override
  List<Object?> get props => [
        id,
        senderId,
        senderName,
        senderImageUrl,
        receiverId,
        content,
        timestamp,
        isRead,
        readAt,
        imageUrl,
        isImage,
        isOneTime,
        viewedBy,
      ];
}
