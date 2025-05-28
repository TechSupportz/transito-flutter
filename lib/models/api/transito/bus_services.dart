import 'package:json_annotation/json_annotation.dart';
import 'package:transito/models/api/transito/bus_routes.dart';
import 'package:transito/models/api/transito/bus_stops.dart';
import 'package:transito/models/enums/bus_operator_enum.dart';

part 'bus_services.g.dart';

@JsonSerializable(explicitToJson: true, createToJson: false)
class AllBusServices {
  @JsonKey(name: 'odata.metadata')
  String metadata;

  @JsonKey(name: 'value')
  List<BusService> busServices;

  AllBusServices({
    required this.metadata,
    required this.busServices,
  });

  factory AllBusServices.fromJson(Map<String, dynamic> json) => _$AllBusServicesFromJson(json);
}

@JsonSerializable(explicitToJson: true, createToJson: false)
class BusStopServicesApiResponse {
  int count;
  List<String> data;

  BusStopServicesApiResponse({
    required this.count,
    required this.data,
  });

  factory BusStopServicesApiResponse.fromJson(Map<String, dynamic> json) =>
      _$BusStopServicesApiResponseFromJson(json);
}

@JsonSerializable(explicitToJson: true, createToJson: false)
class BusServiceSearchApiResponse {
  String message;
  int count;
  List<BusService> data;

  BusServiceSearchApiResponse({
    required this.message,
    required this.count,
    required this.data,
  });

  factory BusServiceSearchApiResponse.fromJson(Map<String, dynamic> json) =>
      _$BusServiceSearchApiResponseFromJson(json);
}

@JsonSerializable(explicitToJson: true, createToJson: false)
class BusServiceDetailsApiResponse {
  String message;
  BusService data;

  BusServiceDetailsApiResponse({
    required this.message,
    required this.data,
  });

  factory BusServiceDetailsApiResponse.fromJson(Map<String, dynamic> json) =>
      _$BusServiceDetailsApiResponseFromJson(json);
}

@JsonSerializable(explicitToJson: true)
class BusService {
  String serviceNo;

  @JsonKey(defaultValue: BusOperator.NA)
  BusOperator operator;
  
  bool isLoopService;
  bool isSingleRoute;
  List<BusStop> interchanges;
  List<List<BusRouteInfo>>? routes;

  BusService({
    required this.serviceNo,
    required this.operator,
    required this.isLoopService,
    required this.isSingleRoute,
    required this.interchanges,
    this.routes,
  });

  factory BusService.fromJson(Map<String, dynamic> json) => _$BusServiceFromJson(json);
  Map<String, dynamic> toJson() => _$BusServiceToJson(this);
}
