import 'package:json_annotation/json_annotation.dart';
import 'package:transito/models/enums/bus_operator_enum.dart';

part 'bus_services.g.dart';

@JsonSerializable(explicitToJson: true, createToJson: false)
class BusService {
  @JsonKey(name: 'odata.metadata')
  String metadata;

  @JsonKey(name: 'value')
  List<BusServiceInfo> busServices;

  BusService({
    required this.metadata,
    required this.busServices,
  });

  factory BusService.fromJson(Map<String, dynamic> json) => _$BusServiceFromJson(json);
}

@JsonSerializable(fieldRename: FieldRename.pascal, explicitToJson: true, createToJson: false)
class BusServiceInfo {
  @JsonKey(name: 'ServiceNo')
  String busServiceNo;

  @JsonKey(name: "Operator", fromJson: decodeBusOperator)
  BusOperator busOperator;

  static BusOperator decodeBusOperator(String busOperator) {
    switch (busOperator) {
      case "SBS":
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

  String orginCode;

  String destinationCode;

  @JsonKey(name: "AM_Peak_Freq")
  String AMPeakFreq;

  @JsonKey(name: "AM_OffPeak_Freq")
  String AMOffPeakFreq;

  @JsonKey(name: "PM_Peak_Freq")
  String PMPeakFreq;

  @JsonKey(name: "PM_OffPeak_Freq")
  String PMOffPeakFreq;

  BusServiceInfo({
    required this.busServiceNo,
    required this.busOperator,
    required this.direction,
    required this.category,
    required this.orginCode,
    required this.destinationCode,
    required this.AMPeakFreq,
    required this.AMOffPeakFreq,
    required this.PMPeakFreq,
    required this.PMOffPeakFreq,
  });

  factory BusServiceInfo.fromJson(Map<String, dynamic> json) => _$BusServiceInfoFromJson(json);
}
