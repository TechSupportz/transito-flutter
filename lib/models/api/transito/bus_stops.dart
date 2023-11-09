import 'package:json_annotation/json_annotation.dart';

part 'bus_stops.g.dart';

@JsonSerializable(explicitToJson: true, createToJson: false)
class BusStop {
  String code;
  String name;
  String roadName;

  double latitude;
  double longitude;
  List<String> services;

  BusStop({
    required this.code,
    required this.roadName,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.services,
  });

  factory BusStop.fromJson(Map<String, dynamic> json) => _$BusStopFromJson(json);
}

@JsonSerializable(explicitToJson: true, createToJson: false)
class BusStopSearch extends BusStop {
  @JsonKey(includeFromJson: false)
  @override
  // ignore: overridden_fields
  List<String> services = [];

  BusStopSearch({
    required String code,
    required String roadName,
    required String name,
    required double latitude,
    required double longitude,
  }) : super(
          code: code,
          roadName: roadName,
          name: name,
          latitude: latitude,
          longitude: longitude,
          services: [],
        );

  factory BusStopSearch.fromJson(Map<String, dynamic> json) => _$BusStopSearchFromJson(json);
}

@JsonSerializable(explicitToJson: true, createToJson: false)
class BusStopSearchApiResponse {
  String message;
  int count;
  List<BusStopSearch> data;

  BusStopSearchApiResponse({
    required this.message,
    required this.count,
    required this.data,
  });

  factory BusStopSearchApiResponse.fromJson(Map<String, dynamic> json) =>
      _$BusStopSearchApiResponseFromJson(json);
}

@JsonSerializable(explicitToJson: true, createToJson: false)
class SimpleBusStop {
  String code;
  String name;

  SimpleBusStop({
    required this.code,
    required this.name,
  });

  factory SimpleBusStop.fromJson(Map<String, dynamic> json) => _$SimpleBusStopFromJson(json);
}
