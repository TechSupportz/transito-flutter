// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bus_services.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AllBusServices _$AllBusServicesFromJson(Map<String, dynamic> json) =>
    AllBusServices(
      metadata: json['odata.metadata'] as String,
      busServices: (json['value'] as List<dynamic>)
          .map((e) => BusServiceInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

BusServiceInfo _$BusServiceInfoFromJson(Map<String, dynamic> json) =>
    BusServiceInfo(
      serviceNo: json['ServiceNo'] as String,
      operator: BusServiceInfo.decodeBusOperator(json['Operator'] as String),
      direction: json['Direction'] as int,
      category: json['Category'] as String,
      originCode: json['OriginCode'] as String,
      destinationCode: json['DestinationCode'] as String,
      AMPeakFreq: json['AM_Peak_Freq'] as String,
      AMOffPeakFreq: json['AM_Offpeak_Freq'] as String,
      PMPeakFreq: json['PM_Peak_Freq'] as String,
      PMOffPeakFreq: json['PM_Offpeak_Freq'] as String,
    );
