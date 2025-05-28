import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:transito/models/enums/app_theme_mode.dart';

part 'user_settings.g.dart';

@JsonSerializable(explicitToJson: true)
class UserSettings {
  final String accentColour;
  final bool isETAminutes;
  final bool isNearbyGrid;

  @JsonKey(defaultValue: true)
  final bool showNearbyDistance;

  @JsonKey(defaultValue: AppThemeMode.SYSTEM)
  final AppThemeMode themeMode;

  UserSettings({
    required this.accentColour,
    required this.isETAminutes,
    required this.isNearbyGrid,
    required this.showNearbyDistance,
    required this.themeMode,
  });

  factory UserSettings.fromFirestore(DocumentSnapshot doc) =>
      UserSettings.fromJson(doc.data()! as Map<String, dynamic>);

  factory UserSettings.fromJson(Map<String, dynamic> json) => _$UserSettingsFromJson(json);
  Map<String, dynamic> toJson() => _$UserSettingsToJson(this);
}
