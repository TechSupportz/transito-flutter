// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'favourite.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Favourite _$FavouriteFromJson(Map<String, dynamic> json) => Favourite(
      busStopCode: json['busStopCode'] as String,
      busStopName: json['busStopName'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      services:
          (json['services'] as List<dynamic>).map((e) => e as String?).toList(),
    );

Map<String, dynamic> _$FavouriteToJson(Favourite instance) => <String, dynamic>{
      'busStopCode': instance.busStopCode,
      'busStopName': instance.busStopName,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'services': instance.services,
    };
