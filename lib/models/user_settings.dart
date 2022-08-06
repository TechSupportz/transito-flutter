import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user_settings.g.dart';

@JsonSerializable(explicitToJson: true)
class UserSettings {
  final String accentColour;
  final bool isETAminutes;
  final bool isNearbyGrid;

  UserSettings({
    required this.accentColour,
    required this.isETAminutes,
    required this.isNearbyGrid,
  });

  factory UserSettings.fromFirestore(DocumentSnapshot doc) =>
      UserSettings.fromJson(doc.data()! as Map<String, dynamic>);

  factory UserSettings.fromJson(Map<String, dynamic> json) => _$UserSettingsFromJson(json);
  Map<String, dynamic> toJson() => _$UserSettingsToJson(this);
}
