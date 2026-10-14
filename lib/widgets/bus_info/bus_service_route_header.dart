import 'package:material_ui/material_ui.dart';
import 'package:flutter_skeleton_ui/flutter_skeleton_ui.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:transito/models/api/transito/bus_routes.dart';
import 'package:transito/models/api/transito/bus_services.dart';
import 'package:transito/models/api/transito/bus_stops.dart';
import 'package:transito/models/app/app_colors.dart';
import 'package:transito/models/app/app_typography.dart';
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
  });

  final String serviceNo;
  final BusService? service;

  /// The selected Service Route, empty until it loads.
  final List<BusRouteInfo> routes;
  final int directionIndex;
  final ValueChanged<BusStop> onStopTap;
  final VoidCallback? onSwitchDirection;

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
    final hasSwitch = showDestination && onSwitchDirection != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            spacing: 12,
            children: [
              // Fades rather than overflowing at large text sizes.
              Flexible(
                child: Row(
                  spacing: 8,
                  children: [
                    // NUS shuttles carry their service colour, as on the timings screen.
                    if (busService?.operator == .NUS)
                      Container(
                        width: 4,
                        height: 32,
                        decoration: BoxDecoration(
                          color: colors.getNUSServiceColor(serviceNo).$1,
                          borderRadius: const BorderRadius.all(Radius.circular(2)),
                        ),
                      ),
                    Flexible(
                      child: Text(
                        serviceNo,
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.fade,
                        style: AppTypography.screenHeading,
                      ),
                    ),
                  ],
                ),
              ),
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
              style: SkeletonLineStyle(height: 112, borderRadius: BorderRadius.circular(20)),
            )
          else
            // One grouped card of stop-card style terminal rows, each led by its origin or
            // destination icon, with the direction switch on the right.
            Material(
              color: scheme.surfaceContainer,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              clipBehavior: Clip.antiAlias,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 8, 4),
                child: Row(
                  spacing: 8,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _TerminalRow(
                            stop: from,
                            label: showDestination ? 'From' : 'Starts and ends at',
                            icon: showDestination
                                ? Symbols.trip_origin_rounded
                                : Symbols.sync_rounded,
                            iconColor: showDestination
                                ? colors.prettyGreen
                                : colors.notReallyYellow,
                            onTap: () => onStopTap(from!),
                          ),
                          if (showDestination) ...[
                            const SizedBox(height: 6),
                            // A small arrow under the origin icon reads as "from → to"; the
                            // divider starts after it, level with the stop names.
                            SizedBox(
                              height: 9,
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 44,
                                    child: OverflowBox(
                                      maxHeight: 20,
                                      child: AppSymbol(
                                        Symbols.south_rounded,
                                        size: 18,
                                        color: scheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Divider(
                                      height: 9,
                                      thickness: 1,
                                      indent: 4,
                                      endIndent: 8,
                                      color: scheme.outlineVariant.withValues(alpha: 0.5),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _TerminalRow(
                              stop: to,
                              label: 'To',
                              icon: Symbols.distance_rounded,
                              iconColor: colors.sortaRed,
                              onTap: () => onStopTap(to!),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (hasSwitch)
                      IconButton.filled(
                        tooltip: 'Switch route direction',
                        onPressed: onSwitchDirection,
                        icon: AnimatedRotation(
                          turns: directionIndex == 0 ? 0 : -0.5,
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOutCubicEmphasized,
                          child: const AppSymbol(Symbols.swap_vert_rounded, size: 30),
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// An interchange laid out like [BusStopCard] content, led by its origin or destination icon.
class _TerminalRow extends StatelessWidget {
  const _TerminalRow({
    required this.stop,
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  final BusStop stop;

  /// Spoken role of the terminal, e.g. "From"; the leading icon shows it visually.
  final String label;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: label,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              spacing: 12,
              children: [
                AppSymbol(icon, fill: true, size: 28, color: iconColor),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 4,
                    children: [
                      Text(
                        stop.name,
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.fade,
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w500,
                          color: scheme.onSurface,
                        ),
                      ),
                      Row(
                        spacing: 8,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                            decoration: BoxDecoration(
                              color: scheme.primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              stop.code,
                              style: AppBusTypography.busInfoChipLabel.copyWith(
                                color: scheme.onPrimary,
                              ),
                            ),
                          ),
                          Flexible(
                            child: Text(
                              stop.roadName,
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.fade,
                              style: TextStyle(
                                color: scheme.onSurfaceVariant,
                                fontStyle: FontStyle.italic,
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
          ),
        ),
      ),
    );
  }
}
