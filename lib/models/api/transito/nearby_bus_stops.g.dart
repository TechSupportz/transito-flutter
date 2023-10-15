// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nearby_bus_stops.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NearbyBusStopsApiResponse _$NearbyBusStopsApiResponseFromJson(
        Map<String, dynamic> json) =>
    NearbyBusStopsApiResponse(
      count: json['count'] as int,
      data: (json['data'] as List<dynamic>)
          .map((e) => NearbyBusStop.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

NearbyBusStop _$NearbyBusStopFromJson(Map<String, dynamic> json) =>
    NearbyBusStop(
      busStop: BusStopInfo.fromJson(json['busStop'] as Map<String, dynamic>),
      distanceAway: (json['distanceAway'] as num).toDouble(),
    );
