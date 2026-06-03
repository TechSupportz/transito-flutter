import 'package:json_annotation/json_annotation.dart';

part 'bus_stops.g.dart';

@JsonSerializable(includeIfNull: false)
class BusStopProviderSources {
  @JsonKey(name: 'LTA')
  String? lta;

  @JsonKey(name: 'NUS')
  String? nus;

  BusStopProviderSources({this.lta, this.nus});

  factory BusStopProviderSources.fromJson(Map<String, dynamic> json) =>
      _$BusStopProviderSourcesFromJson(json);
  Map<String, dynamic> toJson() => _$BusStopProviderSourcesToJson(this);
}

@JsonSerializable(explicitToJson: true)
class BusStop {
  String code;
  String name;
  String roadName;

  double latitude;
  double longitude;
  List<String>? services;
  BusStopProviderSources? sources;

  BusStop({
    required this.code,
    required this.roadName,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.services,
    this.sources,
  });

  factory BusStop.fromJson(Map<String, dynamic> json) => _$BusStopFromJson(json);
  Map<String, dynamic> toJson() => _$BusStopToJson(this);
}

@JsonSerializable(explicitToJson: true, createToJson: false)
class BusStopSearchApiResponse {
  String message;
  int count;
  List<BusStop> data;

  BusStopSearchApiResponse({required this.message, required this.count, required this.data});

  factory BusStopSearchApiResponse.fromJson(Map<String, dynamic> json) =>
      _$BusStopSearchApiResponseFromJson(json);
}

@JsonSerializable(explicitToJson: true, createToJson: false)
class BusStopDetailsApiResponse {
  String message;
  BusStop data;

  BusStopDetailsApiResponse({required this.message, required this.data});

  factory BusStopDetailsApiResponse.fromJson(Map<String, dynamic> json) =>
      _$BusStopDetailsApiResponseFromJson(json);
}
