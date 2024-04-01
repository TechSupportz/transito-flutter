// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bus_stops.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BusStop _$BusStopFromJson(Map<String, dynamic> json) => BusStop(
      code: json['code'] as String,
      roadName: json['roadName'] as String,
      name: json['name'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      services: (json['services'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$BusStopToJson(BusStop instance) => <String, dynamic>{
      'code': instance.code,
      'name': instance.name,
      'roadName': instance.roadName,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'services': instance.services,
    };

BusStopSearchApiResponse _$BusStopSearchApiResponseFromJson(
        Map<String, dynamic> json) =>
    BusStopSearchApiResponse(
      message: json['message'] as String,
      count: json['count'] as int,
      data: (json['data'] as List<dynamic>)
          .map((e) => BusStop.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
