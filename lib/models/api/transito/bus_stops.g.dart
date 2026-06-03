// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bus_stops.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BusStopProviderSources _$BusStopProviderSourcesFromJson(Map<String, dynamic> json) =>
    BusStopProviderSources(lta: json['LTA'] as String?, nus: json['NUS'] as String?);

Map<String, dynamic> _$BusStopProviderSourcesToJson(BusStopProviderSources instance) =>
    <String, dynamic>{'LTA': ?instance.lta, 'NUS': ?instance.nus};

BusStop _$BusStopFromJson(Map<String, dynamic> json) => BusStop(
  code: json['code'] as String,
  roadName: json['roadName'] as String,
  name: json['name'] as String,
  latitude: (json['latitude'] as num).toDouble(),
  longitude: (json['longitude'] as num).toDouble(),
  services: (json['services'] as List<dynamic>?)?.map((e) => e as String).toList(),
  sources: json['sources'] == null
      ? null
      : BusStopProviderSources.fromJson(json['sources'] as Map<String, dynamic>),
);

Map<String, dynamic> _$BusStopToJson(BusStop instance) => <String, dynamic>{
  'code': instance.code,
  'name': instance.name,
  'roadName': instance.roadName,
  'latitude': instance.latitude,
  'longitude': instance.longitude,
  'services': instance.services,
  'sources': instance.sources?.toJson(),
};

BusStopSearchApiResponse _$BusStopSearchApiResponseFromJson(Map<String, dynamic> json) =>
    BusStopSearchApiResponse(
      message: json['message'] as String,
      count: (json['count'] as num).toInt(),
      data: (json['data'] as List<dynamic>)
          .map((e) => BusStop.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

BusStopDetailsApiResponse _$BusStopDetailsApiResponseFromJson(Map<String, dynamic> json) =>
    BusStopDetailsApiResponse(
      message: json['message'] as String,
      data: BusStop.fromJson(json['data'] as Map<String, dynamic>),
    );
