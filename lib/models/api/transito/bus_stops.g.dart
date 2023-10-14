// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bus_stops.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SimpleBusStopInfo _$SimpleBusStopInfoFromJson(Map<String, dynamic> json) =>
    SimpleBusStopInfo(
      code: json['code'] as String,
      name: json['name'] as String,
    );

BusStopInfo _$BusStopInfoFromJson(Map<String, dynamic> json) => BusStopInfo(
      code: json['code'] as String,
      roadName: json['roadName'] as String,
      name: json['name'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      services:
          (json['services'] as List<dynamic>).map((e) => e as String).toList(),
    );
