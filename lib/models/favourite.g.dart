// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'favourite.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Favourite _$FavouriteFromJson(Map<String, dynamic> json) => Favourite(
      busStopCode: json['busStopCode'] as String,
      busStopName: json['busStopName'] as String,
      busStopAddress: json['busStopAddress'] as String,
      busStopLocation:
          Favourite.decodeBusStopLocation(json['busStopLocation'] as GeoPoint),
      services:
          (json['services'] as List<dynamic>).map((e) => e as String?).toList(),
    );

Map<String, dynamic> _$FavouriteToJson(Favourite instance) => <String, dynamic>{
      'busStopCode': instance.busStopCode,
      'busStopName': instance.busStopName,
      'busStopAddress': instance.busStopAddress,
      'busStopLocation': instance.busStopLocation.toJson(),
      'services': instance.services,
    };
