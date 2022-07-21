// ignore_for_file: non_constant_identifier_names

import 'package:json_annotation/json_annotation.dart';
import 'package:transito/models/enums/bus_operator_enum.dart';

part 'bus_services.g.dart';

@JsonSerializable(explicitToJson: true, createToJson: false)
class AllBusServices {
  @JsonKey(name: 'odata.metadata')
  String metadata;

  @JsonKey(name: 'value')
  List<BusServiceInfo> busServices;

  AllBusServices({
    required this.metadata,
    required this.busServices,
  });

  factory AllBusServices.fromJson(Map<String, dynamic> json) => _$AllBusServicesFromJson(json);
}

@JsonSerializable(fieldRename: FieldRename.pascal, explicitToJson: true, createToJson: false)
class BusServiceInfo {
  String serviceNo;

  @JsonKey(fromJson: decodeBusOperator)
  BusOperator operator;

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

  int direction;

  String category;

  String originCode;

  String destinationCode;

  @JsonKey(name: "AM_Peak_Freq")
  String AMPeakFreq;

  @JsonKey(name: "AM_Offpeak_Freq")
  String AMOffPeakFreq;

  @JsonKey(name: "PM_Peak_Freq")
  String PMPeakFreq;

  @JsonKey(name: "PM_Offpeak_Freq")
  String PMOffPeakFreq;

  BusServiceInfo({
    required this.serviceNo,
    required this.operator,
    required this.direction,
    required this.category,
    required this.originCode,
    required this.destinationCode,
    required this.AMPeakFreq,
    required this.AMOffPeakFreq,
    required this.PMPeakFreq,
    required this.PMOffPeakFreq,
  });

  factory BusServiceInfo.fromJson(Map<String, dynamic> json) => _$BusServiceInfoFromJson(json);
}
