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

BusRouteInfo _$BusRouteInfoFromJson(Map<String, dynamic> json) => BusRouteInfo(
      busStop: SimpleBusStop.fromJson(json['busStop'] as Map<String, dynamic>),
      direction: json['direction'] as int,
      sequence: json['sequence'] as int,
      distance: (json['distance'] as num).toDouble(),
      firstBus: BusSchedule.fromJson(json['firstBus'] as Map<String, dynamic>),
      lastBus: BusSchedule.fromJson(json['lastBus'] as Map<String, dynamic>),
    );
