// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bus_services.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BusService _$BusServiceFromJson(Map<String, dynamic> json) => BusService(
      metadata: json['odata.metadata'] as String,
      busServices: (json['value'] as List<dynamic>)
          .map((e) => BusServiceInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

BusServiceInfo _$BusServiceInfoFromJson(Map<String, dynamic> json) =>
    BusServiceInfo(
      busServiceNo: json['ServiceNo'] as String,
      busOperator: BusServiceInfo.decodeBusOperator(json['Operator'] as String),
      direction: json['Direction'] as int,
      category: json['Category'] as String,
      orginCode: json['OrginCode'] as String,
      destinationCode: json['DestinationCode'] as String,
      AMPeakFreq: json['AM_Peak_Freq'] as String,
      AMOffPeakFreq: json['AM_OffPeak_Freq'] as String,
      PMPeakFreq: json['PM_Peak_Freq'] as String,
      PMOffPeakFreq: json['PM_OffPeak_Freq'] as String,
    );
