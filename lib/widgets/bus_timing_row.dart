import 'package:flutter/material.dart';
import 'package:jiffy/jiffy.dart';
import 'package:latlong2/latlong.dart';
import 'package:transito/modals/app_colors.dart';

enum CrowdLvl {
  SEA, // for Seats Available
  SDA, // for Standing Available
  LSD, // for Limited Standing
  NA // No value
}

enum BusType {
  SD, // Single decker
  DD, // Double decker
  BD, // Bendy
  NA // No value
}

class BusTimingRow extends StatefulWidget {
  const BusTimingRow({Key? key, required this.arrivalInfo, required this.userLatLng})
      : super(key: key);

  final arrivalInfo;
  final LatLng userLatLng; // user's current latitude and longitude

  @override
  State<BusTimingRow> createState() => _BusTimingRowState();
}

class _BusTimingRowState extends State<BusTimingRow> {
  final Distance distance = new Distance();

  CrowdLvl decodeCrowdLvl(crowdLvlString) {
    switch (crowdLvlString) {
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

  BusType decodeBusType(busTypeString) {
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

  String formatArrivalTime(arrivalTime) {
    num minutesToArrival = Jiffy(arrivalTime).diff(Jiffy().format(), Units.MINUTE);

    if (minutesToArrival < 0) {
      return "left";
    } else if (minutesToArrival <= 1) {
      return "arr";
    } else {
      return minutesToArrival.toString();
    }
  }

  // computes and returns the distance between user and bus either in meters or kilometers
  String calculateDistanceAway() {
    double distanceAway = distance.as(
        LengthUnit.Meter,
        LatLng(
          double.parse(widget.arrivalInfo['NextBus']['Latitude']),
          double.parse(widget.arrivalInfo['NextBus']['Longitude']),
        ),
        widget.userLatLng);

    if (distanceAway < 1000) {
      return '${(distanceAway).toStringAsFixed(0)}m';
    } else {
      return '${(distanceAway / 1000).toStringAsFixed(1)}km';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.ideographic,
      children: [
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.arrivalInfo['ServiceNo'],
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w500),
              ),
              Text(
                'about ${calculateDistanceAway()} away',
                style: const TextStyle(
                    fontSize: 14, fontStyle: FontStyle.italic, color: AppColors.kindaGrey),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 3,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ArrivalInfo(
                eta: formatArrivalTime(widget.arrivalInfo['NextBus']['EstimatedArrival']),
                accessible: widget.arrivalInfo['NextBus']['Feature'] == "WAB",
                crowdLvl: decodeCrowdLvl(widget.arrivalInfo['NextBus']['Load']),
                busType: decodeBusType(widget.arrivalInfo['NextBus']['Type']),
              ),
              ArrivalInfo(
                eta: formatArrivalTime(widget.arrivalInfo['NextBus2']['EstimatedArrival']),
                accessible: widget.arrivalInfo['NextBus2']['Feature'] == "WAB",
                crowdLvl: decodeCrowdLvl(widget.arrivalInfo['NextBus2']['Load']),
                busType: decodeBusType(widget.arrivalInfo['NextBus2']['Type']),
              ),
              ArrivalInfo(
                eta: formatArrivalTime(widget.arrivalInfo['NextBus3']['EstimatedArrival']),
                accessible: widget.arrivalInfo['NextBus3']['Feature'] == "WAB",
                crowdLvl: decodeCrowdLvl(widget.arrivalInfo['NextBus3']['Load']),
                busType: decodeBusType(widget.arrivalInfo['NextBus3']['Type']),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class ArrivalInfo extends StatefulWidget {
  const ArrivalInfo(
      {Key? key,
      required this.eta,
      required this.accessible,
      required this.crowdLvl,
      required this.busType})
      : super(key: key);

  final String eta;
  final bool accessible;
  final CrowdLvl crowdLvl;
  final BusType busType;

  @override
  State<ArrivalInfo> createState() => _ArrivalInfoState();
}

class _ArrivalInfoState extends State<ArrivalInfo> {
  @override
  Widget build(BuildContext context) {
    return widget.eta != '-'
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 1.5),
                child: widget.accessible
                    ? const Icon(Icons.accessible_rounded, size: 16, color: AppColors.kindaGrey)
                    : const SizedBox(width: 16, height: 16),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    widget.eta,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w500,
                      color: (() {
                        switch (widget.crowdLvl) {
                          case CrowdLvl.SEA:
                            {
                              return AppColors.prettyGreen;
                            }

                          case CrowdLvl.SDA:
                            {
                              return AppColors.notReallyYellow;
                            }

                          case CrowdLvl.LSD:
                            {
                              return AppColors.sortaRed;
                            }
                          case CrowdLvl.NA:
                            {
                              return Colors.white;
                            }
                        }
                      })(),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 2.5, vertical: 1.0),
                    decoration: BoxDecoration(
                        border: Border.all(color: AppColors.kindaGrey),
                        borderRadius: const BorderRadius.all(Radius.circular(5))),
                    child: Text(
                      (() {
                        switch (widget.busType) {
                          case BusType.SD:
                            {
                              return "Single";
                            }

                          case BusType.DD:
                            {
                              return "Double";
                            }

                          case BusType.BD:
                            {
                              return "Bendy";
                            }
                          case BusType.NA:
                            {
                              return "Error";
                            }
                        }
                      })(),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.kindaGrey,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          )
        : const Center(
            child: Text(
            '  -  ',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.w500, color: Colors.white),
          ));
  }
}
