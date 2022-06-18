// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'favourite.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Favourite _$FavouriteFromJson(Map<String, dynamic> json) => Favourite(
      busStopCode: json['busStopCode'] as String,
      services:
          (json['services'] as List<dynamic>).map((e) => e as String?).toList(),
    );

Map<String, dynamic> _$FavouriteToJson(Favourite instance) => <String, dynamic>{
      'busStopCode': instance.busStopCode,
      'services': instance.services,
    };
