import 'package:flutter/material.dart';
import 'package:transito/models/api/transito/bus_routes.dart';
import 'package:transito/models/app/app_colors.dart';
import 'package:transito/widgets/bus_info/bus_stop_card.dart';

class BusRoutesList extends StatelessWidget {
  const BusRoutesList({
    super.key,
    required this.routes,
    required this.controller,
  });

  final List<BusRouteInfo> routes;
  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.drawerBg,
      child: ListView.separated(
        shrinkWrap: true,
        controller: controller,
        padding: const EdgeInsets.only(bottom: 16),
        itemCount: routes.length,
        separatorBuilder: (context, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) => BusStopCard(
          busStopInfo: routes[index].busStop,
          routeMode: true,
          busSchedule: (firstBus: routes[index].firstBus, lastBus: routes[index].lastBus),
        ),
      ),
    );
  }
}
