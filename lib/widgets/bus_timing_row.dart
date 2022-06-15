import 'package:flutter/material.dart';
import 'package:jiffy/jiffy.dart';
import 'package:latlong2/latlong.dart';
import 'package:transito/models/app_colors.dart';
import 'package:transito/models/enums/bus_type_enum.dart';
import 'package:transito/models/enums/crowd_lvl_enum.dart';
import '../models/arrival_info.dart';
// import '../models/enums/crowd_lvl_enum.dart';
// import '../models/enums/bus_type_enum.dart';

class BusTimingRow extends StatefulWidget {
  const BusTimingRow({Key? key, required this.serviceInfo, required this.userLatLng})
      : super(key: key);

  final ServiceInfo serviceInfo;
  final LatLng userLatLng; // user's current latitude and longitude

  @override
  State<BusTimingRow> createState() => _BusTimingRowState();
}

class _BusTimingRowState extends State<BusTimingRow> {
  final Distance distance = new Distance();

  String formatArrivalTime(arrivalTime) {
    if (arrivalTime != '') {
      num minutesToArrival = Jiffy(arrivalTime).diff(Jiffy().format(), Units.MINUTE);
      if (minutesToArrival < -1) {
        return "left";
      } else if (minutesToArrival <= 1) {
        return "arr";
      } else {
        return minutesToArrival.toString();
      }
    } else {
      return '-';
    }
  }

  // computes and returns the distance between user and bus either in meters or kilometers
  String calculateDistanceAway() {
    if (widget.serviceInfo.nextBus.latitude == 0 || widget.serviceInfo.nextBus.longitude == 0) {
      return '???';
    } else {
      double distanceAway = distance.as(
          LengthUnit.Meter,
          LatLng(
            widget.serviceInfo.nextBus.latitude,
            widget.serviceInfo.nextBus.longitude,
          ),
          widget.userLatLng);
      if (distanceAway < 1000) {
        return '${(distanceAway).toStringAsFixed(0)}m';
      } else {
        return '${(distanceAway / 1000).toStringAsFixed(1)}km';
      }
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
                widget.serviceInfo.serviceNum,
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
              ArrivalCard(
                eta: formatArrivalTime(widget.serviceInfo.nextBus.estimatedArrival),
                accessible: widget.serviceInfo.nextBus.isAccessible,
                crowdLvl: widget.serviceInfo.nextBus.crowdLvl,
                busType: widget.serviceInfo.nextBus.busType,
              ),
              ArrivalCard(
                eta: formatArrivalTime(widget.serviceInfo.nextBus2.estimatedArrival),
                accessible: widget.serviceInfo.nextBus2.isAccessible,
                crowdLvl: widget.serviceInfo.nextBus2.crowdLvl,
                busType: widget.serviceInfo.nextBus2.busType,
              ),
              ArrivalCard(
                eta: formatArrivalTime(widget.serviceInfo.nextBus3.estimatedArrival),
                accessible: widget.serviceInfo.nextBus3.isAccessible,
                crowdLvl: widget.serviceInfo.nextBus3.crowdLvl,
                busType: widget.serviceInfo.nextBus3.busType,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class ArrivalCard extends StatefulWidget {
  const ArrivalCard(
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
  State<ArrivalCard> createState() => _ArrivalCardState();
}

class _ArrivalCardState extends State<ArrivalCard> {
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
                        fontSize: 11.5,
                        color: AppColors.kindaGrey,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          )
        : const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0),
            child: Center(
                child: Text(
              '-',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.w500, color: Colors.white),
            )),
          );
  }
}
