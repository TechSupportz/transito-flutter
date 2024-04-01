import 'package:flutter/material.dart';
import 'package:transito/models/api/transito/bus_services.dart';
import 'package:transito/models/app/app_colors.dart';
import 'package:transito/widgets/bus_info/basic_bus_stop_card.dart';

class BusServiceInfoScreen extends StatelessWidget {
  const BusServiceInfoScreen({
    Key? key,
    required this.busService,
  }) : super(key: key);

  final BusService busService;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bus Service Info'),
      ),
      body: Padding(
        padding: const EdgeInsets.only(left: 12.0, right: 12.0, top: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bus ${busService.serviceNo}',
                  overflow: TextOverflow.fade,
                  maxLines: 1,
                  softWrap: false,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 1),
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                      color: AppColors.getOperatorColor(busService.operator),
                      borderRadius: BorderRadius.circular(5)),
                  child: Text(busService.operator.name,
                      style: const TextStyle(fontWeight: FontWeight.w500)),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  "Interchange${busService.isLoopService ? "" : "s"}",
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                BasicBusStopCard(busStop: busService.interchanges[0]),
                if (!busService.isLoopService) ...[
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Icon(Icons.swap_vert_rounded, size: 30, color: AppColors.kindaGrey),
                  ),
                  BasicBusStopCard(busStop: busService.interchanges[1]),
                ]
              ],
            ),
          ],
        ),
      ),
    );
  }
}
