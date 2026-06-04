// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserSettings _$UserSettingsFromJson(Map<String, dynamic> json) => UserSettings(
  accentColour: json['accentColour'] as String,
  isETAminutes: json['isETAminutes'] as bool,
  isNearbyGrid: json['isNearbyGrid'] as bool,
  showNearbyDistance: json['showNearbyDistance'] as bool? ?? true,
  themeMode:
      $enumDecodeNullable(
        _$AppThemeModeEnumMap,
        json['themeMode'],
        unknownValue: AppThemeMode.SYSTEM,
      ) ??
      AppThemeMode.SYSTEM,
  betaServer: json['betaServer'] == null
      ? const BetaServerSettings()
      : _betaServerSettingsFromJson(
          json['betaServer'] as Map<String, dynamic>?,
        ),
);

Map<String, dynamic> _$UserSettingsToJson(UserSettings instance) => <String, dynamic>{
  'accentColour': instance.accentColour,
  'isETAminutes': instance.isETAminutes,
  'isNearbyGrid': instance.isNearbyGrid,
  'showNearbyDistance': instance.showNearbyDistance,
  'themeMode': _$AppThemeModeEnumMap[instance.themeMode]!,
  'betaServer': instance.betaServer.toJson(),
};

const _$AppThemeModeEnumMap = {
  AppThemeMode.LIGHT: 'LIGHT',
  AppThemeMode.DARK: 'DARK',
  AppThemeMode.SYSTEM: 'SYSTEM',
};

BetaServerSettings _$BetaServerSettingsFromJson(Map<String, dynamic> json) => BetaServerSettings(
  enabled: json['enabled'] as bool? ?? false,
  using: json['using'] as bool? ?? false,
);

Map<String, dynamic> _$BetaServerSettingsToJson(BetaServerSettings instance) => <String, dynamic>{
  'enabled': instance.enabled,
  'using': instance.using,
};
