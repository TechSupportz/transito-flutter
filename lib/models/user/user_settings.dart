import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:transito/models/enums/app_theme_mode_enum.dart';

part 'user_settings.g.dart';

@JsonSerializable(explicitToJson: true)
class UserSettings {
  final String accentColour;
  final bool isETAminutes;
  final bool isNearbyGrid;

  @JsonKey(defaultValue: true)
  final bool showNearbyDistance;

  @JsonKey(defaultValue: AppThemeMode.SYSTEM, unknownEnumValue: AppThemeMode.SYSTEM)
  final AppThemeMode themeMode;

  @JsonKey(fromJson: _betaServerSettingsFromJson)
  final BetaServerSettings betaServer;

  UserSettings({
    required this.accentColour,
    required this.isETAminutes,
    required this.isNearbyGrid,
    required this.showNearbyDistance,
    required this.themeMode,
    this.betaServer = const BetaServerSettings(),
  });

  factory UserSettings.fromFirestore(DocumentSnapshot doc) =>
      UserSettings.fromJson(doc.data()! as Map<String, dynamic>);

  factory UserSettings.fromJson(Map<String, dynamic> json) => _$UserSettingsFromJson(json);
  Map<String, dynamic> toJson() => _$UserSettingsToJson(this);
}

@JsonSerializable(explicitToJson: true)
class BetaServerSettings {
  @JsonKey(defaultValue: false)
  final bool enabled;

  @JsonKey(defaultValue: false)
  final bool using;

  const BetaServerSettings({
    this.enabled = false,
    this.using = false,
  });

  bool get isUsingBetaServer => enabled && using;

  factory BetaServerSettings.fromJson(Map<String, dynamic> json) =>
      _$BetaServerSettingsFromJson(json);
  Map<String, dynamic> toJson() => _$BetaServerSettingsToJson(this);
}

BetaServerSettings _betaServerSettingsFromJson(Map<String, dynamic>? json) =>
    json == null ? const BetaServerSettings() : BetaServerSettings.fromJson(json);
