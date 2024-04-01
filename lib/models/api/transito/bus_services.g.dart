// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bus_services.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AllBusServices _$AllBusServicesFromJson(Map<String, dynamic> json) =>
    AllBusServices(
      metadata: json['odata.metadata'] as String,
      busServices: (json['value'] as List<dynamic>)
          .map((e) => BusService.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

BusStopServicesApiResponse _$BusStopServicesApiResponseFromJson(
        Map<String, dynamic> json) =>
    BusStopServicesApiResponse(
      count: json['count'] as int,
      data: (json['data'] as List<dynamic>).map((e) => e as String).toList(),
    );

BusServiceSearchApiResponse _$BusServiceSearchApiResponseFromJson(
        Map<String, dynamic> json) =>
    BusServiceSearchApiResponse(
      message: json['message'] as String,
      count: json['count'] as int,
      data: (json['data'] as List<dynamic>)
          .map((e) => BusService.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

BusService _$BusServiceFromJson(Map<String, dynamic> json) => BusService(
      serviceNo: json['serviceNo'] as String,
      operator: BusService.decodeBusOperator(json['operator'] as String),
      isLoopService: json['isLoopService'] as bool,
      interchanges: (json['interchanges'] as List<dynamic>)
          .map((e) => BusStop.fromJson(e as Map<String, dynamic>))
          .toList(),
      busRoutes: (json['busRoutes'] as List<dynamic>?)
          ?.map((e) => BusRouteInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$BusServiceToJson(BusService instance) =>
    <String, dynamic>{
      'serviceNo': instance.serviceNo,
      'operator': _$BusOperatorEnumMap[instance.operator]!,
      'isLoopService': instance.isLoopService,
      'interchanges': instance.interchanges.map((e) => e.toJson()).toList(),
      'busRoutes': instance.busRoutes?.map((e) => e.toJson()).toList(),
    };

const _$BusOperatorEnumMap = {
  BusOperator.SBST: 'SBST',
  BusOperator.SMRT: 'SMRT',
  BusOperator.TTS: 'TTS',
  BusOperator.GAS: 'GAS',
  BusOperator.NA: 'NA',
};
