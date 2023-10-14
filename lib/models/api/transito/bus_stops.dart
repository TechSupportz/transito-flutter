import 'package:json_annotation/json_annotation.dart';

part 'bus_stops.g.dart';

@JsonSerializable(explicitToJson: true, createToJson: false)
class SimpleBusStopInfo {
  String code;
  String name;

  SimpleBusStopInfo({
    required this.code,
    required this.name,
  });

  factory SimpleBusStopInfo.fromJson(Map<String, dynamic> json) =>
      _$SimpleBusStopInfoFromJson(json);
}

@JsonSerializable(explicitToJson: true, createToJson: false)
class BusStopInfo {
  String code;
  String name;
  String roadName;

  double latitude;
  double longitude;
  List<String> services;

  BusStopInfo({
    required this.code,
    required this.roadName,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.services,
  });

  factory BusStopInfo.fromJson(Map<String, dynamic> json) => _$BusStopInfoFromJson(json);
}
