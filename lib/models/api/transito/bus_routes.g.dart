// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bus_routes.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BusSchedule _$BusScheduleFromJson(Map<String, dynamic> json) => BusSchedule(
      weekdays: json['weekdays'] as String,
      saturday: json['saturday'] as String,
      sunday: json['sunday'] as String,
    );

Map<String, dynamic> _$BusScheduleToJson(BusSchedule instance) =>
    <String, dynamic>{
      'weekdays': instance.weekdays,
      'saturday': instance.saturday,
      'sunday': instance.sunday,
    };

BusRouteInfo _$BusRouteInfoFromJson(Map<String, dynamic> json) => BusRouteInfo(
      busStop: BusStop.fromJson(json['busStop'] as Map<String, dynamic>),
      direction: json['direction'] as int,
      sequence: json['sequence'] as int,
      distance: (json['distance'] as num).toDouble(),
      firstBus: BusSchedule.fromJson(json['firstBus'] as Map<String, dynamic>),
      lastBus: BusSchedule.fromJson(json['lastBus'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$BusRouteInfoToJson(BusRouteInfo instance) =>
    <String, dynamic>{
      'busStop': instance.busStop.toJson(),
      'direction': instance.direction,
      'sequence': instance.sequence,
      'distance': instance.distance,
      'firstBus': instance.firstBus.toJson(),
      'lastBus': instance.lastBus.toJson(),
    };
