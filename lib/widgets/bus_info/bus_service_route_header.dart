import 'package:material_ui/material_ui.dart';
import 'package:flutter_skeleton_ui/flutter_skeleton_ui.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:transito/models/api/transito/bus_routes.dart';
import 'package:transito/models/api/transito/bus_services.dart';
import 'package:transito/models/api/transito/bus_stops.dart';
import 'package:transito/models/app/app_colors.dart';
import 'package:transito/models/app/app_typography.dart';
import 'package:transito/widgets/bus_info/bus_stop_card.dart';
import 'package:transito/widgets/common/app_symbol.dart';

/// The service summary pinned above the stop list in both sheet positions.
class BusServiceRouteHeader extends StatelessWidget {
  const BusServiceRouteHeader({
    super.key,
    required this.serviceNo,
    required this.service,
    required this.routes,
    required this.directionIndex,
    required this.onStopTap,
    required this.onSwitchDirection,
    this.selectedStopCode,
  });

  final String serviceNo;
  final BusService? service;

  /// The selected Service Route, empty until it loads.
  final List<BusRouteInfo> routes;
  final int directionIndex;
  final ValueChanged<BusStop> onStopTap;
  final VoidCallback? onSwitchDirection;
  final String? selectedStopCode;

  @override
  Widget build(BuildContext context) {
    final colors = context.watch<AppColors>();
    final scheme = Theme.of(context).colorScheme;
    final busService = service;
    final isLoop = busService?.isLoopService == true;

    BusStop? from;
    BusStop? to;
    if (routes.isNotEmpty) {
      from = routes.first.busStop;
      to = routes.last.busStop;
    } else if (busService != null && busService.interchanges.isNotEmpty) {
      final interchanges = directionIndex == 0
          ? busService.interchanges
          : busService.interchanges.reversed.toList();
      from = interchanges.first;
      to = interchanges.last;
    }
    final showDestination = !isLoop && to != null && to.code != from?.code;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('Bus $serviceNo', style: AppTypography.screenHeading),
              if (busService != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  decoration: BoxDecoration(
                    color: colors.getOperatorColor(busService.operator).$1,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    busService.operator.name,
                    style: AppBusTypography.busInfoChipLabel.copyWith(
                      color: colors.getOperatorColor(busService.operator).$2,
                    ),
                  ),
                )
              else
                SkeletonLine(
                  style: SkeletonLineStyle(
                    height: 25,
                    width: 64,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
            ],
          ),
          if (from == null)
            SkeletonLine(
              style: SkeletonLineStyle(height: 140, borderRadius: BorderRadius.circular(12)),
            )
          else
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 12,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 12,
                      children: [
                        _terminalCard(from),
                        if (showDestination) _terminalCard(to),
                      ],
                    ),
                  ),
                  if (isLoop || !showDestination)
                    Center(
                      child: AppSymbol(
                        Symbols.sync_rounded,
                        color: colors.notReallyYellow,
                        size: 28,
                      ),
                    )
                  else
                    Column(
                      children: [
                        Expanded(
                          child: Center(
                            child: AppSymbol(
                              Symbols.trip_origin_rounded,
                              color: colors.prettyGreen,
                              size: 28,
                            ),
                          ),
                        ),
                        if (onSwitchDirection == null)
                          AppSymbol(Symbols.south_rounded, color: scheme.onSurface, size: 28)
                        else
                          IconButton.filled(
                            tooltip: 'Switch route direction',
                            style: IconButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: onSwitchDirection,
                            icon: AnimatedRotation(
                              turns: directionIndex == 0 ? 0 : -0.5,
                              duration: const Duration(milliseconds: 200),
                              child: const AppSymbol(Symbols.swap_vert_rounded, size: 30),
                            ),
                          ),
                        Expanded(
                          child: Center(
                            child: AppSymbol(
                              Symbols.distance_rounded,
                              color: colors.sortaRed,
                              fill: true,
                              size: 28,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _terminalCard(BusStop stop) => BusStopCard(
    busStopInfo: stop,
    routeMode: true,
    isHighlighted: stop.code == selectedStopCode,
    onTap: () => onStopTap(stop),
  );
}
