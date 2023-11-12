import 'package:json_annotation/json_annotation.dart';
import 'package:transito/models/api/transito/bus_stops.dart';

part 'bus_routes.g.dart';

@JsonSerializable(explicitToJson: true)
class BusSchedule {
  String weekdays;
  String saturday;
  String sunday;

  BusSchedule({
    required this.weekdays,
    required this.saturday,
    required this.sunday,
  });

  factory BusSchedule.fromJson(Map<String, dynamic> json) => _$BusScheduleFromJson(json);
  Map<String, dynamic> toJson() => _$BusScheduleToJson(this);
}

@JsonSerializable(explicitToJson: true)
class BusRouteInfo {
  SimpleBusStop busStop;

  // NOTE - this can probably be improved, only values possible are 1 and 2
  int direction;

  int sequence;
  double distance;
  BusSchedule firstBus;
  BusSchedule lastBus;

  BusRouteInfo({
    required this.busStop,
    required this.direction,
    required this.sequence,
    required this.distance,
    required this.firstBus,
    required this.lastBus,
  });

  factory BusRouteInfo.fromJson(Map<String, dynamic> json) => _$BusRouteInfoFromJson(json);
  Map<String, dynamic> toJson() => _$BusRouteInfoToJson(this);
}
