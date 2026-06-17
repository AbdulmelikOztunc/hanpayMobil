import 'package:hanpay_mobil/shared/models/json_helpers.dart';

class AppNotificationDto {
  const AppNotificationDto({
    required this.id,
    required this.eventType,
    required this.severity,
    required this.eventKey,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
    this.data,
    this.entityType,
    this.entityId,
    this.link,
  });

  final int id;
  final String eventType;
  final String severity;
  final String eventKey;
  final Map<String, String>? data;
  final String title;
  final String message;
  final String? entityType;
  final int? entityId;
  final String? link;
  final bool isRead;
  final DateTime createdAt;

  factory AppNotificationDto.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'] ?? json['Data'];
    Map<String, String>? data;
    if (rawData is Map) {
      data = rawData.map((k, v) => MapEntry(k.toString(), v?.toString() ?? ''));
    }
    return AppNotificationDto(
      id: jsonInt(json['id'] ?? json['Id']),
      eventType: jsonStr(json['eventType'] ?? json['EventType']),
      severity: jsonStr(json['severity'] ?? json['Severity']),
      eventKey: jsonStr(json['eventKey'] ?? json['EventKey']),
      data: data,
      title: jsonStr(json['title'] ?? json['Title']),
      message: jsonStr(json['message'] ?? json['Message']),
      entityType: json['entityType'] as String? ?? json['EntityType'] as String?,
      entityId: (json['entityId'] ?? json['EntityId'] as num?)?.toInt(),
      link: json['link'] as String? ?? json['Link'] as String?,
      isRead: json['isRead'] == true || json['IsRead'] == true,
      createdAt: jsonDate(json['createdAt'] ?? json['CreatedAt']),
    );
  }
}
