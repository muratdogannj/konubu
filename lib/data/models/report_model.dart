enum ReportType {
  confession,
  comment,
}

enum ReportReason {
  profanity,      // Küfür/Hakaret
  obscene,        // Müstehcen İçerik
  spam,           // Spam
  misleading,     // Yanıltıcı Bilgi
  other,          // Diğer
}

enum ReportStatus {
  pending,        // Beklemede
  reviewed,       // İncelendi
  actionTaken,    // Aksiyon Alındı
  dismissed,      // Reddedildi
}

class ReportModel {
  final String id;
  final ReportType type;
  final String targetId;              // Confession ID veya Comment ID
  final String? confessionId;         // Comment için parent confession
  final String reporterId;
  final String reporterName;
  final ReportReason reason;
  final String? description;
  final ReportStatus status;
  final DateTime createdAt;
  final String? reviewedBy;           // Moderator ID
  final DateTime? reviewedAt;
  final String? reviewNotes;

  const ReportModel({
    required this.id,
    required this.type,
    required this.targetId,
    this.confessionId,
    required this.reporterId,
    required this.reporterName,
    required this.reason,
    this.description,
    required this.status,
    required this.createdAt,
    this.reviewedBy,
    this.reviewedAt,
    this.reviewNotes,
  });

  factory ReportModel.fromJson(Map<String, dynamic> json, String id) {
    return ReportModel(
      id: id,
      type: ReportType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ReportType.confession,
      ),
      targetId: json['targetId'] as String,
      confessionId: json['confessionId'] as String?,
      reporterId: json['reporterId'] as String,
      reporterName: json['reporterName'] as String,
      reason: ReportReason.values.firstWhere(
        (e) => e.name == json['reason'],
        orElse: () => ReportReason.other,
      ),
      description: json['description'] as String?,
      status: ReportStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ReportStatus.pending,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      reviewedBy: json['reviewedBy'] as String?,
      reviewedAt: json['reviewedAt'] != null
          ? DateTime.parse(json['reviewedAt'] as String)
          : null,
      reviewNotes: json['reviewNotes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'targetId': targetId,
      'confessionId': confessionId,
      'reporterId': reporterId,
      'reporterName': reporterName,
      'reason': reason.name,
      'description': description,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'reviewedBy': reviewedBy,
      'reviewedAt': reviewedAt?.toIso8601String(),
      'reviewNotes': reviewNotes,
    };
  }

  ReportModel copyWith({
    String? id,
    ReportType? type,
    String? targetId,
    String? confessionId,
    String? reporterId,
    String? reporterName,
    ReportReason? reason,
    String? description,
    ReportStatus? status,
    DateTime? createdAt,
    String? reviewedBy,
    DateTime? reviewedAt,
    String? reviewNotes,
  }) {
    return ReportModel(
      id: id ?? this.id,
      type: type ?? this.type,
      targetId: targetId ?? this.targetId,
      confessionId: confessionId ?? this.confessionId,
      reporterId: reporterId ?? this.reporterId,
      reporterName: reporterName ?? this.reporterName,
      reason: reason ?? this.reason,
      description: description ?? this.description,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewNotes: reviewNotes ?? this.reviewNotes,
    );
  }

  // Helper methods
  String get reasonText {
    switch (reason) {
      case ReportReason.profanity:
        return 'Küfür/Hakaret';
      case ReportReason.obscene:
        return 'Müstehcen İçerik';
      case ReportReason.spam:
        return 'Spam';
      case ReportReason.misleading:
        return 'Yanıltıcı Bilgi';
      case ReportReason.other:
        return 'Diğer';
    }
  }

  String get statusText {
    switch (status) {
      case ReportStatus.pending:
        return 'Beklemede';
      case ReportStatus.reviewed:
        return 'İncelendi';
      case ReportStatus.actionTaken:
        return 'Aksiyon Alındı';
      case ReportStatus.dismissed:
        return 'Reddedildi';
    }
  }

  String get typeText {
    switch (type) {
      case ReportType.confession:
        return 'Konu';
      case ReportType.comment:
        return 'Yorum';
    }
  }
}
