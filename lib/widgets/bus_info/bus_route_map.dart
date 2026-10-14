import 'dart:async';
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:transito/global/services/location_service.dart';
import 'package:transito/models/api/transito/bus_routes.dart';
import 'package:transito/models/app/app_colors.dart';
import 'package:transito/widgets/common/app_symbol.dart';

class BusRouteMapController extends ChangeNotifier {
  LatLng? _focus;
  LatLng? get focus => _focus;

  void focusStop(LatLng location) {
    _focus = location;
    notifyListeners();
  }

  void fitRoute() {
    _focus = null;
    notifyListeners();
  }
}

class BusRouteMap extends StatefulWidget {
  const BusRouteMap({
    super.key,
    required this.controller,
    required this.routes,
    required this.shape,
    required this.panelHeight,
    required this.topInset,
    required this.routeColor,
    required this.onStopTap,
    this.currentStopCode,
    this.selectedStopIndex,
  });

  final BusRouteMapController controller;
  final List<BusRouteInfo> routes;
  final List<LatLng> shape;

  /// Height of the sheet covering the bottom of the map.
  final double panelHeight;

  /// Height of the status bar and floating controls covering the top of the map.
  final double topInset;

  /// The route line colour. It ignores the app theme because OneMap tile colours do too.
  final Color routeColor;
  final ValueChanged<int> onStopTap;
  final String? currentStopCode;
  final int? selectedStopIndex;

  @override
  State<BusRouteMap> createState() => _BusRouteMapState();
}

class _BusRouteMapState extends State<BusRouteMap> with TickerProviderStateMixin {
  late final AnimatedMapController _map = AnimatedMapController(vsync: this);
  bool _ready = false;
  bool _awayFromOverview = false;
  bool _placed = false;
  late final Stream<LocationMarkerPosition?> _positionStream =
      const LocationMarkerDataStreamFactory().fromGeolocatorPositionStream(
        stream: LocationService().positionStream,
      );
  double _rotation = 0;
  bool _showStopIcons = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_applyCameraRequest);
  }

  @override
  void didUpdateWidget(BusRouteMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_applyCameraRequest);
      widget.controller.addListener(_applyCameraRequest);
    }
    if (oldWidget.routes != widget.routes || oldWidget.shape != widget.shape) {
      _scheduleFit();
    } else if ((oldWidget.panelHeight - widget.panelHeight).abs() > 1 && !_awayFromOverview) {
      _scheduleFit();
    }
  }

  void _scheduleFit() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _ready) _fitRoute();
    });
  }

  static const double _homeZoom = 16;

  /// The originating stop when it is on this route, otherwise the route's starting terminal.
  /// A whole-route overview is too cluttered on OneMap tiles to be a useful starting point.
  LatLng? get _homePoint {
    if (widget.routes.isEmpty) return null;
    final stop = widget.routes
        .firstWhere(
          (route) => route.busStop.code == widget.currentStopCode,
          orElse: () => widget.routes.first,
        )
        .busStop;
    return LatLng(stop.latitude, stop.longitude);
  }

  Offset get _visibleAreaOffset => Offset(0, (widget.topInset - widget.panelHeight) / 2);

  /// The north-up camera centre that shows [point] in the middle of the area between the floating
  /// controls and the sheet. flutter_map_animations drops `offset` whenever rotation also changes,
  /// so the offset is applied here instead.
  LatLng _centreShowing(LatLng point, double zoom) {
    final crs = _map.mapController.camera.crs;
    return crs.offsetToLatLng(crs.latLngToOffset(point, zoom) - _visibleAreaOffset, zoom);
  }

  void _animateCameraTo(LatLng point, double zoom) {
    unawaited(_map.animateTo(dest: _centreShowing(point, zoom), zoom: zoom, rotation: 0));
  }

  void _fitRoute() {
    final home = _homePoint;
    if (!_ready || home == null) return;
    setState(() => _awayFromOverview = false);
    if (!_placed) {
      // Jump the first time so the screen never opens on a zoomed-out flash of the island.
      _placed = true;
      _map.mapController.move(_centreShowing(home, _homeZoom), _homeZoom);
      return;
    }
    _animateCameraTo(home, _homeZoom);
  }

  void _applyCameraRequest() {
    if (!_ready) return;
    final focus = widget.controller.focus;
    if (focus == null) {
      _fitRoute();
    } else {
      setState(() => _awayFromOverview = true);
      _animateCameraTo(focus, 17.5);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_applyCameraRequest);
    _map.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.watch<AppColors>();
    final scheme = Theme.of(context).colorScheme;
    final stops = <String, int>{};
    for (var i = 0; i < widget.routes.length; i++) {
      stops.putIfAbsent(widget.routes[i].busStop.code, () => i);
    }
    // Operator colours are mostly deep shades that sink into the Night tiles, while pale ones such
    // as GAS yellow blend into the Default tiles' yellow main roads.
    final lineColor = colors.brightness == Brightness.dark
        ? Color.lerp(widget.routeColor, Colors.white, 0.3)!
        : widget.routeColor.computeLuminance() > 0.4
        ? Color.lerp(widget.routeColor, Colors.black, 0.3)!
        : widget.routeColor;
    final selectedCode = widget.selectedStopIndex == null
        ? null
        : widget.routes[widget.selectedStopIndex!].busStop.code;
    return Stack(
      children: [
        FlutterMap(
          mapController: _map.mapController,
          options: MapOptions(
            initialCenter: widget.routes.isEmpty
                ? const LatLng(1.3521, 103.8198)
                : LatLng(
                    widget.routes.first.busStop.latitude,
                    widget.routes.first.busStop.longitude,
                  ),
            initialZoom: 12,
            minZoom: 10,
            maxZoom: 19,
            backgroundColor: scheme.surfaceContainer,
            onMapReady: () {
              _ready = true;
              _scheduleFit();
            },
            onPositionChanged: (camera, hasGesture) {
              final showIcons = camera.zoom >= 16;
              if ((hasGesture && !_awayFromOverview) ||
                  (_rotation - camera.rotation).abs() > 0.1 ||
                  showIcons != _showStopIcons) {
                setState(() {
                  if (hasGesture) _awayFromOverview = true;
                  _rotation = camera.rotation;
                  _showStopIcons = showIcons;
                });
              }
            },
          ),
          children: [
            TileLayer(
              urlTemplate:
                  "https://www.onemap.gov.sg/maps/tiles/${colors.brightness == Brightness.dark ? 'Night_HD' : 'Default_HD'}/{z}/{x}/{y}.png",
              fallbackUrl:
                  "https://www.onemap.gov.sg/maps/tiles/${colors.brightness == Brightness.dark ? 'Night' : 'Default'}/{z}/{x}/{y}.png",
              userAgentPackageName: 'com.tnitish.transito',
              errorImage: const AssetImage('assets/images/mapError.png'),
            ),
            if (widget.shape.length > 1)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: widget.shape,
                    color: lineColor,
                    strokeWidth: 5,
                  ),
                ],
              ),
            CurrentLocationLayer(
              positionStream: _positionStream,
              style: const LocationMarkerStyle(),
            ),
            MarkerLayer(
              rotate: true,
              markers: [
                for (final entry in stops.entries)
                  Marker(
                    key: ValueKey(entry.key),
                    point: LatLng(
                      widget.routes[entry.value].busStop.latitude,
                      widget.routes[entry.value].busStop.longitude,
                    ),
                    width: 48,
                    height: 48,
                    child: Semantics(
                      button: true,
                      selected: entry.key == selectedCode,
                      label: '${widget.routes[entry.value].busStop.name}, ${entry.key}',
                      child: Tooltip(
                        message: widget.routes[entry.value].busStop.name,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () => widget.onStopTap(entry.value),
                            child: Center(
                              child: _StopMarker(
                                isFirst: entry.value == 0,
                                isLast: entry.key == widget.routes.last.busStop.code,
                                isCurrent: entry.key == widget.currentStopCode,
                                isSelected: entry.key == selectedCode,
                                showIcon: _showStopIcons,
                                lineColor: lineColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        if (_awayFromOverview && widget.routes.isNotEmpty)
          Positioned(
            top: widget.topInset - 56,
            right: 16,
            child: IconButton.filledTonal(
              tooltip: 'Reset map north-up',
              onPressed: widget.controller.fitRoute,
              style: IconButton.styleFrom(
                backgroundColor: scheme.surfaceContainerHighest,
                elevation: 4,
              ),
              iconSize: 48,
              icon: Transform.rotate(
                angle: _rotation * math.pi / 180,
                child: RotatedBox(
                  quarterTurns: colors.brightness == Brightness.light ? 2 : 0,
                  child: SvgPicture.asset(
                    'assets/icons/ui/compass_point.svg',
                    colorFilter: ColorFilter.mode(scheme.tertiary, BlendMode.modulate),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _StopMarker extends StatelessWidget {
  const _StopMarker({
    required this.isFirst,
    required this.isLast,
    required this.isCurrent,
    required this.isSelected,
    required this.showIcon,
    required this.lineColor,
  });

  final bool isFirst;
  final bool isLast;
  final bool isCurrent;
  final bool isSelected;
  final bool showIcon;
  final Color lineColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.watch<AppColors>();
    final isTerminal = isFirst || isLast;
    final size = isSelected
        ? 40.0
        : isCurrent || isTerminal || showIcon
        ? 28.0
        : 12.0;
    // Whichever of white or black has the higher WCAG contrast ratio against the fill.
    final luminance = lineColor.computeLuminance();
    final onLine = 1.05 / (luminance + 0.05) >= (luminance + 0.05) / 0.05
        ? Colors.white
        : Colors.black;

    // Ordinary stops sit on the line like stations on a transit map; filled markers stand out.
    final (Color fill, Color ring, Color icon, IconData symbol) = switch (this) {
      _ when isCurrent => (lineColor, Colors.white, onLine, Symbols.directions_bus_rounded),
      // Terminals keep their start/end colours when selected, matching the header and timeline.
      _ when isFirst => (
        colors.prettyGreen,
        Colors.white,
        Colors.black,
        Symbols.trip_origin_rounded,
      ),
      _ when isLast => (colors.sortaRed, Colors.white, Colors.black, Symbols.distance_rounded),
      _ when isSelected => (lineColor, Colors.white, onLine, Symbols.directions_bus_rounded),
      _ => (Colors.white, lineColor, lineColor, Symbols.directions_bus_rounded),
    };

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: fill,
        // One shape with a varying radius, so the decoration can animate between marker styles.
        borderRadius: BorderRadius.circular(isCurrent ? size / 4 : size / 2),
        border: Border.all(color: ring, width: size > 12 ? 2.5 : 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: isSelected ? 8 : 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: size > 12 ? AppSymbol(symbol, fill: true, size: size * 0.6, color: icon) : null,
    );
  }
}
