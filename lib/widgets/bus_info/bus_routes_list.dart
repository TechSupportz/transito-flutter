import 'package:material_ui/material_ui.dart';
import 'package:measure_size/measure_size.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:transito/models/api/transito/bus_routes.dart';
import 'package:transito/models/app/app_colors.dart';
import 'package:transito/models/app/app_typography.dart';
import 'package:transito/widgets/bus_info/bus_stop_card.dart';
import 'package:transito/widgets/common/app_symbol.dart';

/// The ordered stops of one Service Route, drawn as a timeline.
///
/// Every row shares the prototype row's extent, so row `i` starts at `i * extent` within the
/// list. Names fade instead of wrapping to keep that true at any text size.
class BusRoutesList extends StatelessWidget {
  const BusRoutesList({
    super.key,
    required this.routes,
    required this.onStopTap,
    this.currentStopCode,
    this.selectedStopIndex,
    this.onRowExtentChanged,
  });

  final List<BusRouteInfo> routes;
  final ValueChanged<int> onStopTap;
  final String? currentStopCode;
  final int? selectedStopIndex;
  final ValueChanged<double>? onRowExtentChanged;

  @override
  Widget build(BuildContext context) {
    return SliverPrototypeExtentList.builder(
      prototypeItem: BusRouteStopRow(route: routes.first, isFirst: true, isLast: true),
      itemCount: routes.length,
      itemBuilder: (context, index) => MeasureSize(
        onChange: (size) => onRowExtentChanged?.call(size.height),
        child: BusRouteStopRow(
          route: routes[index],
          isFirst: index == 0,
          isLast: index == routes.length - 1,
          isCurrent: routes[index].busStop.code == currentStopCode,
          isSelected: index == selectedStopIndex,
          onTap: () => onStopTap(index),
        ),
      ),
    );
  }
}

class BusRouteStopRow extends StatelessWidget {
  const BusRouteStopRow({
    super.key,
    required this.route,
    required this.isFirst,
    required this.isLast,
    this.isCurrent = false,
    this.isSelected = false,
    this.onTap,
  });

  static const double railWidth = 48;

  final BusRouteInfo route;
  final bool isFirst;
  final bool isLast;
  final bool isCurrent;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final stop = route.busStop;
    return Semantics(
      selected: isSelected,
      child: Material(
        color: isSelected ? scheme.secondaryContainer : Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            children: [
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: railWidth,
                child: _RouteRail(isFirst: isFirst, isLast: isLast, isCurrent: isCurrent),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(railWidth, 10, 4, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        spacing: 4,
                        children: [
                          Text(
                            stop.name,
                            maxLines: 1,
                            softWrap: false,
                            overflow: TextOverflow.fade,
                            style: AppTypography.bodyLarge.copyWith(
                              fontWeight: isCurrent || isFirst || isLast
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected ? scheme.onSecondaryContainer : scheme.onSurface,
                            ),
                          ),
                          Row(
                            spacing: 8,
                            children: [
                              Flexible(
                                child: _Tag(
                                  label: stop.code,
                                  background: scheme.primary,
                                  foreground: scheme.onPrimary,
                                ),
                              ),
                              if (isCurrent)
                                Flexible(
                                  child: _Tag(
                                    label: 'Your stop',
                                    background: scheme.primaryContainer,
                                    foreground: scheme.onPrimaryContainer,
                                  ),
                                ),
                              Flexible(
                                child: Text(
                                  stop.roadName,
                                  maxLines: 1,
                                  softWrap: false,
                                  overflow: TextOverflow.fade,
                                  style: AppTypography.caption.copyWith(
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
                    IconButton(
                      tooltip: 'First and last bus',
                      color: scheme.onSurfaceVariant,
                      onPressed: () => showDialog(
                        context: context,
                        builder: (_) => BusScheduleDialog(
                          busSchedule: (firstBus: route.firstBus, lastBus: route.lastBus),
                        ),
                      ),
                      icon: const AppSymbol(Symbols.calendar_clock_rounded),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RouteRail extends StatelessWidget {
  const _RouteRail({required this.isFirst, required this.isLast, required this.isCurrent});

  final bool isFirst;
  final bool isLast;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.watch<AppColors>();
    final Widget node;
    if (isFirst || isLast) {
      node = Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(color: scheme.surfaceContainerLow, shape: BoxShape.circle),
        child: AppSymbol(
          isFirst ? Symbols.trip_origin_rounded : Symbols.distance_rounded,
          fill: true,
          size: 22,
          color: isFirst ? colors.prettyGreen : colors.sortaRed,
        ),
      );
    } else {
      node = Container(
        width: isCurrent ? 18 : 12,
        height: isCurrent ? 18 : 12,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isCurrent ? scheme.primary : scheme.surfaceContainerLow,
          border: Border.all(
            color: isCurrent ? scheme.primaryContainer : scheme.primary,
            width: isCurrent ? 3 : 2.5,
          ),
        ),
      );
    }
    return Stack(
      alignment: Alignment.center,
      children: [
        Column(
          children: [
            Expanded(
              child: Container(width: 4, color: isFirst ? Colors.transparent : scheme.primary),
            ),
            Expanded(
              child: Container(width: 4, color: isLast ? Colors.transparent : scheme.primary),
            ),
          ],
        ),
        node,
      ],
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.background, required this.foreground});

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(6)),
      child: Text(
        label,
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.ellipsis,
        style: AppBusTypography.busInfoChipLabel.copyWith(fontSize: 12, color: foreground),
      ),
    );
  }
}
