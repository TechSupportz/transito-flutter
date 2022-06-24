import 'package:json_annotation/json_annotation.dart';
import 'package:transito/models/enums/bus_operator_enum.dart';
import 'package:transito/models/enums/bus_type_enum.dart';
import 'package:transito/models/enums/crowd_lvl_enum.dart';

part 'arrival_info.g.dart';

@JsonSerializable(fieldRename: FieldRename.pascal, explicitToJson: true, createToJson: false)
class BusArrivalInfo {
  @JsonKey(name: 'odata.metadata')
  String metadata;
  String busStopCode;
  List<ServiceInfo> services;

  BusArrivalInfo({
    required this.metadata,
    required this.busStopCode,
    required this.services,
  });

  factory BusArrivalInfo.fromJson(Map<String, dynamic> json) => _$BusArrivalInfoFromJson(json);
}

@JsonSerializable(fieldRename: FieldRename.pascal, explicitToJson: true, createToJson: false)
class ServiceInfo {
  @JsonKey(name: "ServiceNo")
  String serviceNum;

  @JsonKey(name: "Operator", fromJson: decodeBusOperator)
  BusOperator busOperator;

  IndivArrivalInfo nextBus;
  IndivArrivalInfo nextBus2;
  IndivArrivalInfo nextBus3;

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

  ServiceInfo({
    required this.serviceNum,
    required this.busOperator,
    required this.nextBus,
    required this.nextBus2,
    required this.nextBus3,
  });

  factory ServiceInfo.fromJson(Map<String, dynamic> json) => _$ServiceInfoFromJson(json);
}

@JsonSerializable(fieldRename: FieldRename.pascal, createToJson: false)
class IndivArrivalInfo {
  String? originCode;
  String? destinationCode;
  String? estimatedArrival;

  @JsonKey(fromJson: stringToDouble)
  double latitude;

  @JsonKey(fromJson: stringToDouble)
  double longitude;

  @JsonKey(fromJson: stringToInt)
  int? visitNumber;

  @JsonKey(name: 'Load', fromJson: decodeCrowdLvl)
  CrowdLvl crowdLvl;

  @JsonKey(name: 'Feature', fromJson: decodeIsAccessible)
  bool isAccessible;

  @JsonKey(name: 'Type', fromJson: decodeBusType)
  BusType busType;

  static double stringToDouble(String stringToConvert) {
    if (stringToConvert != '') {
      return double.parse(stringToConvert);
    } else {
      return 0;
    }
  }

  static int stringToInt(String stringToConvert) {
    if (stringToConvert != '') {
      return int.parse(stringToConvert);
    } else {
      return 0;
    }
  }

  static bool decodeIsAccessible(String feature) {
    return feature == 'WAB';
  }

  static CrowdLvl decodeCrowdLvl(String crowdLvl) {
    switch (crowdLvl) {
      case "SEA":
        {
          return CrowdLvl.SEA;
        }
      case "SDA":
        {
          return CrowdLvl.SDA;
        }
      case "LSD":
        {
          return CrowdLvl.LSD;
        }
      default:
        {
          return CrowdLvl.NA;
        }
    }
  }

  static BusType decodeBusType(busTypeString) {
    switch (busTypeString) {
      case "SD":
        {
          return BusType.SD;
        }
      case "DD":
        {
          return BusType.DD;
        }
      case "BD":
        {
          return BusType.BD;
        }
      default:
        {
          return BusType.NA;
        }
    }
  }

  IndivArrivalInfo(this.originCode, this.destinationCode, this.estimatedArrival, this.latitude,
      this.longitude, this.visitNumber, this.crowdLvl, this.isAccessible, this.busType);

  factory IndivArrivalInfo.fromJson(Map<String, dynamic> json) => _$IndivArrivalInfoFromJson(json);
}
