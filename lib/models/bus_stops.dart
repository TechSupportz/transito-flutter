import 'package:json_annotation/json_annotation.dart';

part 'bus_stops.g.dart';

@JsonSerializable(explicitToJson: true, createToJson: false)
class AllBusStops {
  @JsonKey(name: 'odata.metadata')
  String metadata;

  @JsonKey(name: 'value')
  List<BusStopInfo> busStops;

  AllBusStops({
    required this.metadata,
    required this.busStops,
  });

  factory AllBusStops.fromJson(Map<String, dynamic> json) => _$AllBusStopsFromJson(json);
}

@JsonSerializable(fieldRename: FieldRename.pascal, explicitToJson: true, createToJson: false)
class BusStopInfo {
  String busStopCode;
  String roadName;

  @JsonKey(name: 'Description')
  String busStopName;

  double latitude;
  double longitude;

  BusStopInfo({
    required this.busStopCode,
    required this.roadName,
    required this.busStopName,
    required this.latitude,
    required this.longitude,
  });

  factory BusStopInfo.fromJson(Map<String, dynamic> json) => _$BusStopInfoFromJson(json);
}
