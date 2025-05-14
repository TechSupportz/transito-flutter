import 'package:flutter/material.dart';
import 'package:smooth_highlight/smooth_highlight.dart';
import 'package:transito/models/api/transito/bus_routes.dart';
import 'package:transito/models/app/app_colors.dart';
import 'package:transito/widgets/bus_info/bus_stop_card.dart';

class BusRoutesList extends StatelessWidget {
  const BusRoutesList({
    super.key,
    required this.routes,
    required this.controller,
    this.currentStopCode,
  });

  final List<BusRouteInfo> routes;
  final ScrollController controller;
  final String? currentStopCode;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.drawerBg(context),
      child: ListView.separated(
          shrinkWrap: true,
          controller: controller,
          padding: const EdgeInsets.only(bottom: 16),
          itemCount: routes.length,
          separatorBuilder: (context, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            if (currentStopCode != null && routes[index].busStop.code == currentStopCode) {
              return Stack(children: [
                BusStopCard(
                  busStopInfo: routes[index].busStop,
                  routeMode: true,
                  busSchedule: (firstBus: routes[index].firstBus, lastBus: routes[index].lastBus),
                ),
                IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: SmoothHighlight(
                      useInitialHighLight: true,
                      color: AppColors.accentColour.withOpacity(0.2),
                      child: Container(
                        height: 70.0,
                      ),
                    ),
                  ),
                ),
              ]);
            }

            return BusStopCard(
              busStopInfo: routes[index].busStop,
              routeMode: true,
              busSchedule: (firstBus: routes[index].firstBus, lastBus: routes[index].lastBus),
            );
          }),
    );
  }
}
