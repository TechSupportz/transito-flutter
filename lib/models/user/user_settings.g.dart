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
      themeMode: $enumDecodeNullable(_$ThemeModeEnumMap, json['themeMode']) ??
          ThemeMode.system,
    );

Map<String, dynamic> _$UserSettingsToJson(UserSettings instance) =>
    <String, dynamic>{
      'accentColour': instance.accentColour,
      'isETAminutes': instance.isETAminutes,
      'isNearbyGrid': instance.isNearbyGrid,
      'showNearbyDistance': instance.showNearbyDistance,
      'themeMode': _$ThemeModeEnumMap[instance.themeMode]!,
    };

const _$ThemeModeEnumMap = {
  ThemeMode.system: 'system',
  ThemeMode.light: 'light',
  ThemeMode.dark: 'dark',
};
