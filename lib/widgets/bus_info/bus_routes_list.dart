import 'package:latlong2/latlong.dart';
import 'package:material_ui/material_ui.dart';
import 'package:measure_size/measure_size.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:transito/global/providers/search_provider.dart';
import 'package:transito/models/api/transito/bus_routes.dart';
import 'package:transito/models/app/app_colors.dart';
import 'package:transito/models/app/app_typography.dart';
import 'package:transito/screens/bus_info/bus_stop_info_screen.dart';
import 'package:transito/screens/bus_info/bus_timing_screen.dart';
import 'package:transito/widgets/bus_info/bus_stop_card.dart';
import 'package:transito/widgets/common/app_symbol.dart';

/// The ordered stops of one Service Route, drawn as a timeline.
///
/// Only the selected row grows, to show its actions; every other row has the same base extent, so
/// with no selection above it row `i` starts at `i * extent`. Names fade instead of wrapping to keep that true at
/// any text size.
class BusRoutesList extends StatelessWidget {
  const BusRoutesList({
    super.key,
    required this.routes,
    required this.onStopTap,
    this.currentStopCode,
    this.selectedStopIndex,
    this.busRowIndex,
    this.onRowExtentChanged,
    this.onActionsExtentChanged,
  });

  final List<BusRouteInfo> routes;
  final ValueChanged<int> onStopTap;
  final String? currentStopCode;
  final int? selectedStopIndex;

  /// The row the next bus is approaching, drawn on the rail just above that row's stop.
  final int? busRowIndex;
  final ValueChanged<double>? onRowExtentChanged;

  /// Height added to a row when it is selected and shows its actions.
  final ValueChanged<double>? onActionsExtentChanged;

  @override
  Widget build(BuildContext context) {
    return SliverList.builder(
      itemCount: routes.length,
      itemBuilder: (context, index) {
        return BusRouteStopRow(
          route: routes[index],
          isFirst: index == 0,
          isLast: index == routes.length - 1,
          isCurrent: routes[index].busStop.code == currentStopCode,
          isSelected: index == selectedStopIndex,
          busApproaching: index == busRowIndex,
          onTap: () => onStopTap(index),
          onBaseExtentChanged: onRowExtentChanged,
          onActionsExtentChanged: onActionsExtentChanged,
        );
      },
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
    this.busApproaching = false,
    this.onTap,
    this.onBaseExtentChanged,
    this.onActionsExtentChanged,
  });

  static const double railWidth = 48;

  final BusRouteInfo route;
  final bool isFirst;
  final bool isLast;
  final bool isCurrent;
  final bool isSelected;

  /// Whether the next bus is between the previous stop and this one.
  final bool busApproaching;
  final VoidCallback? onTap;

  // measure_size keeps the callback from a row's first build, so these must not capture per-build
  // state such as selection. The base part never changes size when the row is selected.
  final ValueChanged<double>? onBaseExtentChanged;
  final ValueChanged<double>? onActionsExtentChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final stop = route.busStop;
    final row = Semantics(
      selected: isSelected,
      child: Material(
        color: isSelected ? scheme.secondaryContainer : Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MeasureSize(
              onChange: (size) => onBaseExtentChanged?.call(size.height),
              // The selection fill acknowledges a tap; a ripple would stop short of the actions
              // that open below the row.
              child: InkWell(
                onTap: onTap,
                splashFactory: NoSplash.splashFactory,
                highlightColor: Colors.transparent,
                child: Stack(
                  children: [
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      width: railWidth,
                      child: _RouteRail(
                        isFirst: isFirst,
                        isLast: isLast,
                        isCurrent: isCurrent,
                        isSelected: isSelected,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(railWidth, 10, 16, 10),
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
                  ],
                ),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              // Collapse at once, so a previous selection doesn't shift the list while it scrolls
              // to the new one.
              reverseDuration: Duration.zero,
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: isSelected
                  ? Stack(
                      children: [
                        // The route continues past the selected stop beside its actions.
                        if (!isLast)
                          Positioned(
                            left: (railWidth - 4) / 2,
                            top: 0,
                            bottom: 0,
                            width: 4,
                            child: ColoredBox(color: scheme.primary),
                          ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(railWidth, 0, 12, 12),
                          // Fade and rise in while the row grows.
                          child: MeasureSize(
                            onChange: (size) => onActionsExtentChanged?.call(size.height + 12),
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0, end: 1),
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeOutCubic,
                              builder: (context, value, child) => Opacity(
                                opacity: value,
                                child: Transform.translate(
                                  offset: Offset(0, (1 - value) * 8),
                                  child: child,
                                ),
                              ),
                              child: _StopActions(route: route),
                            ),
                          ),
                        ),
                      ],
                    )
                  : const SizedBox(width: double.infinity),
            ),
          ],
        ),
      ),
    );
    if (!busApproaching) return row;
    // Rows paint in order, so overflowing upward draws the bus over the previous row's rail,
    // on the boundary between the two stops.
    return Stack(
      clipBehavior: Clip.none,
      children: [
        row,
        Positioned(
          top: -_RailBus.size / 2,
          left: (railWidth - _RailBus.size) / 2,
          child: const _RailBus(),
        ),
      ],
    );
  }
}

/// The next bus on the route rail, inverted like its map pin so it stands apart from stop nodes.
class _RailBus extends StatelessWidget {
  const _RailBus();

  static const double size = 24;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return IgnorePointer(
      child: Semantics(
        label: 'Next bus',
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 300),
          curve: Curves.easeOutBack,
          builder: (context, value, child) => Transform.scale(scale: value, child: child),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: scheme.inverseSurface,
              shape: BoxShape.circle,
              border: Border.all(color: scheme.primary, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: AppSymbol(
              Symbols.directions_bus_rounded,
              fill: true,
              size: 14,
              color: scheme.onInverseSurface,
            ),
          ),
        ),
      ),
    );
  }
}

class _StopActions extends StatelessWidget {
  const _StopActions({required this.route});

  final BusRouteInfo route;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final stop = route.busStop;
    final location = LatLng(stop.latitude, stop.longitude);
    return Row(
      spacing: 8,
      children: [
        _ActionButton(
          icon: Symbols.departure_board_rounded,
          label: 'Timings',
          background: scheme.primary,
          foreground: scheme.onPrimary,
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              settings: const RouteSettings(name: 'BusTimingScreen'),
              builder: (_) => BusTimingScreen(
                code: stop.code,
                name: stop.name,
                address: stop.roadName,
                services: stop.services,
                sources: stop.sources,
                busStopLocation: location,
              ),
            ),
          ),
        ),
        _ActionButton(
          icon: Symbols.calendar_clock_rounded,
          label: 'Schedule',
          tooltip: 'First and last bus',
          background: scheme.surfaceContainerLow,
          foreground: scheme.onSurface,
          onPressed: () => showDialog(
            context: context,
            builder: (_) => BusScheduleDialog(
              busSchedule: (firstBus: route.firstBus, lastBus: route.lastBus),
            ),
          ),
        ),
        _ActionButton(
          icon: Symbols.info_rounded,
          label: 'Info',
          tooltip: 'Bus stop information',
          background: scheme.surfaceContainerLow,
          foreground: scheme.onSurface,
          onPressed: () {
            context.read<SearchProvider>().addRecentSearch(stop);
            Navigator.push(
              context,
              MaterialPageRoute(
                settings: const RouteSettings(name: 'BusStopInfoScreen'),
                builder: (_) => BusStopInfoScreen(
                  code: stop.code,
                  name: stop.name,
                  address: stop.roadName,
                  services: stop.services,
                  sources: stop.sources,
                  busStopLocation: location,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.background,
    required this.foreground,
    required this.onPressed,
    this.tooltip,
  });

  final IconData icon;
  final String label;
  final String? tooltip;
  final Color background;
  final Color foreground;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final button = Semantics(
      button: true,
      child: Material(
        color: background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Column(
              spacing: 2,
              children: [
                AppSymbol(icon, fill: true, size: 22, color: foreground),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    return Expanded(
      child: tooltip == null ? button : Tooltip(message: tooltip, child: button),
    );
  }
}

class _RouteRail extends StatelessWidget {
  const _RouteRail({
    required this.isFirst,
    required this.isLast,
    required this.isCurrent,
    required this.isSelected,
  });

  final bool isFirst;
  final bool isLast;
  final bool isCurrent;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.watch<AppColors>();
    // Node backgrounds blend into the row so the rail reads as one line.
    final rowColor = isSelected ? scheme.secondaryContainer : scheme.surfaceContainerLow;
    final Widget node;
    if (isFirst || isLast) {
      node = Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(color: rowColor, shape: BoxShape.circle),
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
          color: isCurrent ? scheme.primary : rowColor,
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
