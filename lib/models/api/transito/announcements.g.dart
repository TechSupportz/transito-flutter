// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'announcements.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Announcement _$AnnouncementFromJson(Map<String, dynamic> json) => Announcement(
  id: json['id'] as String,
  title: json['title'] as String,
  body: json['body'] as String,
  severity: $enumDecode(
    _$AnnouncementSeverityEnumMap,
    json['severity'],
    unknownValue: AnnouncementSeverity.INFO,
  ),
  expiresAt: json['expiresAt'] == null
      ? null
      : DateTime.parse(json['expiresAt'] as String),
);

Map<String, dynamic> _$AnnouncementToJson(Announcement instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'body': instance.body,
      'severity': _$AnnouncementSeverityEnumMap[instance.severity]!,
      'expiresAt': instance.expiresAt?.toIso8601String(),
    };

const _$AnnouncementSeverityEnumMap = {
  AnnouncementSeverity.INFO: 'info',
  AnnouncementSeverity.WARNING: 'warning',
  AnnouncementSeverity.CRITICAL: 'critical',
};

AlertsData _$AlertsDataFromJson(Map<String, dynamic> json) => AlertsData(
  announcements: (json['announcements'] as List<dynamic>)
      .map((e) => Announcement.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$AlertsDataToJson(AlertsData instance) =>
    <String, dynamic>{
      'announcements': instance.announcements.map((e) => e.toJson()).toList(),
    };

AlertsApiResponse _$AlertsApiResponseFromJson(Map<String, dynamic> json) =>
    AlertsApiResponse(
      data: AlertsData.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$AlertsApiResponseToJson(AlertsApiResponse instance) =>
    <String, dynamic>{'data': instance.data.toJson()};
