// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'favourite.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FavouritesList _$FavouritesListFromJson(Map<String, dynamic> json) =>
    FavouritesList(
      favouritesList: (json['favouritesList'] as List<dynamic>)
          .map((e) => Favourite.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$FavouritesListToJson(FavouritesList instance) =>
    <String, dynamic>{
      'favouritesList': instance.favouritesList.map((e) => e.toJson()).toList(),
    };

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
      'busStopLocation':
          Favourite.encodeBusStopLocation(instance.busStopLocation),
      'services': instance.services,
    };
