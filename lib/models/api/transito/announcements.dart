// ignore_for_file: constant_identifier_names

import 'package:json_annotation/json_annotation.dart';

part 'announcements.g.dart';

enum AnnouncementSeverity {
  @JsonValue('info')
  INFO,
  @JsonValue('warning')
  WARNING,
  @JsonValue('critical')
  CRITICAL,
}

@JsonSerializable()
class Announcement {
  String id;
  String title;
  String body;

  @JsonKey(unknownEnumValue: AnnouncementSeverity.INFO)
  AnnouncementSeverity severity;

  DateTime? expiresAt;

  Announcement({
    required this.id,
    required this.title,
    required this.body,
    required this.severity,
    this.expiresAt,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) => _$AnnouncementFromJson(json);
  Map<String, dynamic> toJson() => _$AnnouncementToJson(this);
}

@JsonSerializable(explicitToJson: true)
class AlertsData {
  List<Announcement> announcements;

  AlertsData({required this.announcements});

  factory AlertsData.fromJson(Map<String, dynamic> json) => _$AlertsDataFromJson(json);
  Map<String, dynamic> toJson() => _$AlertsDataToJson(this);
}

@JsonSerializable(explicitToJson: true)
class AlertsApiResponse {
  AlertsData data;

  AlertsApiResponse({required this.data});

  factory AlertsApiResponse.fromJson(Map<String, dynamic> json) =>
      _$AlertsApiResponseFromJson(json);
  Map<String, dynamic> toJson() => _$AlertsApiResponseToJson(this);
}
