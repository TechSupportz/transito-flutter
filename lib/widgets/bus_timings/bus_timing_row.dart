import 'package:flutter/material.dart';
import 'package:jiffy/jiffy.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:transito/models/api/lta/arrival_info.dart';
import 'package:transito/models/app/app_colors.dart';
import 'package:transito/models/enums/bus_type_enum.dart';
import 'package:transito/models/enums/crowd_lvl_enum.dart';
import 'package:transito/screens/bus_info/bus_service_info_screen.dart';

class BusTimingRow extends StatefulWidget {
  const BusTimingRow({
    super.key,
    required this.busStopCode,
    required this.serviceInfo,
    required this.userLatLng,
    required this.isETAminutes,
  });

  final String busStopCode;
  final ServiceInfo serviceInfo;
  final LatLng userLatLng; // user's current latitude and longitude
  final bool isETAminutes; // whether to display ETA in minutes or exact time

  @override
  State<BusTimingRow> createState() => _BusTimingRowState();
}

class _BusTimingRowState extends State<BusTimingRow> {
  final Distance distance = const Distance();

  // formats the arrival time into minutes or exact time depending on user's settings
  String formatArrivalTime(String? arrivalTime) {
    if (!widget.isETAminutes) {
      if (arrivalTime != null && arrivalTime != '') {
        String formattedArrivalTime = Jiffy.parse(arrivalTime.split("+")[0]).Hm;
        return formattedArrivalTime;
      } else {
        return '-';
      }
    } else {
      if (arrivalTime != null && arrivalTime != '') {
        num minutesToArrival = Jiffy.parse(arrivalTime.split("+")[0])
            .diff(
              Jiffy.now(),
              unit: Unit.minute,
              asFloat: false,
            ) // NOTE - for some reason asFloat: false is how you return a decimal (https://github.com/jama5262/jiffy/blob/master/doc/README.md#difference)
            .floor();
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

  Future<void> goToBusServiceInfoScreen() async {
    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BusServiceInfoScreen(
          serviceNo: widget.serviceInfo.serviceNum,
          originStopCode: widget.serviceInfo.nextBus.originCode,
          currentStopCode: widget.busStopCode,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.ideographic,
      children: [
        Expanded(
          flex: 3,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: goToBusServiceInfoScreen,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 4.0),
                  child: Text(
                    widget.serviceInfo.serviceNum,
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w500),
                  ),
                ),
                Text(
                  '~ ${calculateDistanceAway()} away',
                  style: TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
        const Expanded(
          flex: 1,
          child: SizedBox(),
        ),
        Expanded(
          flex: 6,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ArrivalCard(
                eta: formatArrivalTime(widget.serviceInfo.nextBus.estimatedArrival),
                accessible: widget.serviceInfo.nextBus.isAccessible,
                isMonitored: widget.serviceInfo.nextBus.isMonitored,
                crowdLvl: widget.serviceInfo.nextBus.crowdLvl,
                busType: widget.serviceInfo.nextBus.busType,
                isETAminutes: widget.isETAminutes,
              ),
              ArrivalCard(
                eta: formatArrivalTime(widget.serviceInfo.nextBus2.estimatedArrival),
                accessible: widget.serviceInfo.nextBus2.isAccessible,
                isMonitored: widget.serviceInfo.nextBus2.isMonitored,
                crowdLvl: widget.serviceInfo.nextBus2.crowdLvl,
                busType: widget.serviceInfo.nextBus2.busType,
                isETAminutes: widget.isETAminutes,
              ),
              ArrivalCard(
                eta: formatArrivalTime(widget.serviceInfo.nextBus3.estimatedArrival),
                accessible: widget.serviceInfo.nextBus3.isAccessible,
                isMonitored: widget.serviceInfo.nextBus3.isMonitored,
                crowdLvl: widget.serviceInfo.nextBus3.crowdLvl,
                busType: widget.serviceInfo.nextBus3.busType,
                isETAminutes: widget.isETAminutes,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class ArrivalCard extends StatefulWidget {
  const ArrivalCard({
    super.key,
    required this.eta,
    required this.accessible,
    required this.isMonitored,
    required this.crowdLvl,
    required this.busType,
    required this.isETAminutes,
  });

  final String eta;
  final bool accessible;
  final bool isMonitored;
  final CrowdLvl crowdLvl;
  final BusType busType;
  final bool isETAminutes;

  @override
  State<ArrivalCard> createState() => _ArrivalCardState();
}

class _ArrivalCardState extends State<ArrivalCard> {
  @override
  Widget build(BuildContext context) {
    AppColors appColors = context.read<AppColors>();
    return widget.eta != '-'
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // displays accessibility icon if bus is accessible
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 1.5),
                child: widget.accessible
                    ? Icon(Icons.accessible_rounded,
                        size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant)
                    : const SizedBox(width: 16, height: 16),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // changes colour based on crowd level
                  Text(
                    widget.eta,
                    style: TextStyle(
                      fontSize: widget.isETAminutes ? 30 : 18,
                      fontWeight: FontWeight.w500,
                      fontStyle: widget.isMonitored ? FontStyle.normal : FontStyle.italic,
                      color: (() {
                        switch (widget.crowdLvl) {
                          case CrowdLvl.SEA:
                            return appColors.prettyGreen;
                          case CrowdLvl.SDA:
                            return appColors.notReallyYellow;
                          case CrowdLvl.LSD:
                            return appColors.sortaRed;
                          case CrowdLvl.NA:
                            return Theme.of(context).colorScheme.onSurface;
                        }
                      })(),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 2.5, vertical: 1.0),
                    decoration: BoxDecoration(
                        border: Border.all(color: Theme.of(context).colorScheme.onSurfaceVariant),
                        borderRadius: const BorderRadius.all(Radius.circular(5))),
                    // displays different text based on bus type
                    child: Text(
                      (() {
                        switch (widget.busType) {
                          case BusType.SD:
                            return "Single";
                          case BusType.DD:
                            return "Double";
                          case BusType.BD:
                            return "Bendy";
                          case BusType.NA:
                            return "Error";
                        }
                      })(),
                      style: TextStyle(
                        fontSize: widget.isETAminutes ? 11.5 : 10,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          )
        // if there is no bus arrival time available it displays '-'
        : Center(
            child: Text(
            '    -  ',
            style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
          ));
  }
}
