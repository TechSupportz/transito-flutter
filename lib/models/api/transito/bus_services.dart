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
class BusService {
  String serviceNo;

  @JsonKey(fromJson: decodeBusOperator)
  BusOperator operator;

  bool isLoopService;
  List<SimpleBusStop> interchanges;
  List<BusRouteInfo>? busRoutes;

  static BusOperator decodeBusOperator(String busOperator) {
    switch (busOperator) {
      case "SBST":
        {
          return BusOperator.SBST;
        }
      case "SMRT":
        {
          return BusOperator.SMRT;
        }
      case "TTS":
        {
          return BusOperator.TTS;
        }
      case "GAS":
        {
          return BusOperator.GAS;
        }
      default:
        {
          return BusOperator.NA;
        }
    }
  }

  BusService({
    required this.serviceNo,
    required this.operator,
    required this.isLoopService,
    required this.interchanges,
    this.busRoutes,
  });

  factory BusService.fromJson(Map<String, dynamic> json) => _$BusServiceFromJson(json);
}
