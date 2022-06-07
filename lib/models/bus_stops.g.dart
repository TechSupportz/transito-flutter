// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bus_stops.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AllBusStops _$AllBusStopsFromJson(Map<String, dynamic> json) => AllBusStops(
      metadata: json['odata.metadata'] as String,
      busStops: (json['value'] as List<dynamic>)
          .map((e) => BusStopInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

BusStopInfo _$BusStopInfoFromJson(Map<String, dynamic> json) => BusStopInfo(
      busStopCode: json['BusStopCode'] as String,
      roadName: json['RoadName'] as String,
      busStopName: json['Description'] as String,
      latitude: (json['Latitude'] as num).toDouble(),
      longitude: (json['Longitude'] as num).toDouble(),
    );
