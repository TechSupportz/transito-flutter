// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserSettings _$UserSettingsFromJson(Map<String, dynamic> json) => UserSettings(
      accentColour: json['accentColour'] as String,
      isETAminutes: json['isETAminutes'] as bool,
      isNearbyGrid: json['isNearbyGrid'] as bool,
    );

Map<String, dynamic> _$UserSettingsToJson(UserSettings instance) =>
    <String, dynamic>{
      'accentColour': instance.accentColour,
      'isETAminutes': instance.isETAminutes,
      'isNearbyGrid': instance.isNearbyGrid,
    };
