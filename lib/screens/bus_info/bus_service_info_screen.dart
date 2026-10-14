import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_skeleton_ui/flutter_skeleton_ui.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:measure_size/measure_size.dart';
import 'package:provider/provider.dart';
import 'package:transito/global/providers/common_provider.dart';
import 'package:transito/global/providers/quick_start_tour_provider.dart';
import 'package:transito/global/services/bus_arrival_service.dart';
import 'package:transito/global/services/transito_api_service.dart';
import 'package:transito/global/utils/bus_arrival_time.dart';
import 'package:transito/global/utils/unpack_polyline.dart';
import 'package:transito/models/api/lta/arrival_info.dart';
import 'package:transito/models/api/transito/bus_routes.dart';
import 'package:transito/models/api/transito/bus_services.dart';
import 'package:transito/models/api/transito/bus_stops.dart';
import 'package:transito/models/app/app_colors.dart';
import 'package:transito/models/enums/bus_operator_enum.dart';
import 'package:transito/widgets/bus_info/bus_route_map.dart';
import 'package:transito/widgets/bus_info/bus_routes_list.dart';
import 'package:transito/widgets/bus_info/bus_service_route_header.dart';
import 'package:transito/widgets/common/error_text.dart';

class BusServiceInfoScreen extends StatefulWidget {
  const BusServiceInfoScreen({
    super.key,
    required this.serviceNo,
    this.originStopCode,
    this.destinationStopCode,
    this.currentStopCode,
    this.busService,
    this.initialNextBus,
  });

  final String serviceNo;
  final String? originStopCode;
  final String? destinationStopCode;
  final String? currentStopCode;
  final BusService? busService;
  final IndivArrivalInfo? initialNextBus;

  @override
  State<BusServiceInfoScreen> createState() => _BusServiceInfoScreenState();
}

class _BusServiceInfoScreenState extends State<BusServiceInfoScreen> {
  final _drawer = DraggableScrollableController();
  final _map = BusRouteMapController();
  ScrollController? _routeScrollController;
  BusService? _service;
  List<List<LatLng>> _shapes = const [];
  List<ServiceInfo> _arrivalServices = const [];
  IndivArrivalInfo? _seededNextBus;
  DateTime? _lastArrivalUpdate;
  Timer? _arrivalTimer;
  int _arrivalFetchGeneration = 0;
  int _directionIndex = 0;
  int? _selectedStopIndex;
  int? _pendingScrollIndex;
  int? _lastScrollIndex;
  bool _loading = true;
  bool _loadFailed = false;
  int _requestGeneration = 0;
  double _headerHeight = 0;
  double _rowExtent = 72;
  double _actionsExtent = 0;

  /// How far the list shifts up when a selected row above the new selection collapses.
  double _pendingScrollCompensation = 0;

  /// Bumped by every reveal, direction change and user drag so stale reveal corrections give up.
  int _revealGeneration = 0;
  double _collapsedSheetHeight = 0.4;
  double _expandedSheetHeight = 1;
  bool _headerPinned = true;

  List<BusRouteInfo> get _routes {
    final routes = _service?.routes;
    return routes != null && _directionIndex < routes.length ? routes[_directionIndex] : const [];
  }

  List<LatLng> get _shape => _directionIndex < _shapes.length ? _shapes[_directionIndex] : const [];

  BusStop? get _currentStopOnActiveRoute {
    final code = widget.currentStopCode;
    if (code == null) return null;
    for (final stop in _routes) {
      if (stop.busStop.code == code) return stop.busStop;
    }
    return null;
  }

  LatLng? get _nextBusLocation {
    final stopCode = widget.currentStopCode;
    final service = _service;
    final updatedAt = _lastArrivalUpdate;
    if (stopCode == null || service == null || _currentStopOnActiveRoute == null) return null;
    if (updatedAt == null) return null;
    final now = DateTime.now();
    if (now.difference(updatedAt) > const Duration(seconds: 60)) return null;

    final allRoutes = service.routes ?? const [];
    // When the current stop appears in more than one direction (such as an interchange), match the
    // arrival's terminals so a departing bus isn't shown on the opposite direction.
    final sharedAcrossDirections =
        allRoutes.length > 1 &&
        allRoutes.where((route) => route.any((stop) => stop.busStop.code == stopCode)).length > 1;

    final sequences = <List<IndivArrivalInfo>>[
      for (final item in _arrivalServices)
        if (item.serviceNum == widget.serviceNo) [item.nextBus, item.nextBus2, item.nextBus3],
      if (_arrivalServices.isEmpty && _seededNextBus != null) [_seededNextBus!],
    ];

    for (final sequence in sequences) {
      for (final bus in sequence) {
        if (_hasDeparted(bus, now)) continue;
        if (sharedAcrossDirections) {
          final direction = _directionForArrival(
            service,
            originStopCode: bus.originCode,
            destinationStopCode: bus.destinationCode,
          );
          if (direction != null && direction != _directionIndex) continue;
        }
        // Once we've found the next bus for this direction, don't fall through to nextBus2 if its
        // live position is unavailable—that would mislabel a later bus as the next one.
        if (!bus.isMonitored) break;
        final lat = bus.latitude;
        final lng = bus.longitude;
        if (!lat.isFinite ||
            !lng.isFinite ||
            lat < 1.1 ||
            lat > 1.5 ||
            lng < 103.6 ||
            lng > 104.1) {
          break;
        }
        final matched = _matchToShape(LatLng(lat, lng), _shape);
        if (matched != null) return matched;
        break;
      }
    }
    return null;
  }

  bool _hasDeparted(IndivArrivalInfo bus, DateTime now) {
    final arrival = parseBusArrivalTime(bus.estimatedArrival);
    return arrival != null && now.difference(arrival) > const Duration(seconds: 30);
  }

  /// Snaps [point] onto [shape] when within 60m, or returns null when [point] is more than 150m
  /// from the route shape (such as a bus still finishing the opposite direction or in a depot).
  LatLng? _matchToShape(LatLng point, List<LatLng> shape) {
    if (shape.length < 2) return point;
    const metresPerDegreeLat = 110574.0;
    final metresPerDegreeLng = 111320.0 * math.cos(point.latitudeInRad);

    var bestDistanceSquared = double.infinity;
    var bestPoint = point;

    for (var i = 0; i < shape.length - 1; i++) {
      final start = shape[i];
      final end = shape[i + 1];
      final endX = (end.longitude - start.longitude) * metresPerDegreeLng;
      final endY = (end.latitude - start.latitude) * metresPerDegreeLat;
      final busX = (point.longitude - start.longitude) * metresPerDegreeLng;
      final busY = (point.latitude - start.latitude) * metresPerDegreeLat;

      final lengthSquared = endX * endX + endY * endY;
      final t = lengthSquared == 0
          ? 0.0
          : ((busX * endX + busY * endY) / lengthSquared).clamp(0.0, 1.0);
      final offsetX = busX - t * endX;
      final offsetY = busY - t * endY;
      final distSquared = offsetX * offsetX + offsetY * offsetY;
      if (distSquared < bestDistanceSquared) {
        bestDistanceSquared = distSquared;
        bestPoint = LatLng(
          start.latitude + (end.latitude - start.latitude) * t,
          start.longitude + (end.longitude - start.longitude) * t,
        );
      }
    }

    if (bestDistanceSquared > 150 * 150) return null;
    return bestDistanceSquared <= 60 * 60 ? bestPoint : point;
  }

  /// How far the sheet is between collapsed (0) and expanded (1).
  double get _sheetProgress {
    if (!_drawer.isAttached || _expandedSheetHeight <= _collapsedSheetHeight) return 0;
    return ((_drawer.size - _collapsedSheetHeight) / (_expandedSheetHeight - _collapsedSheetHeight))
        .clamp(0.0, 1.0);
  }

  bool get _isExpanded => _drawer.isAttached && _drawer.size >= _expandedSheetHeight - 0.02;

  @override
  void initState() {
    super.initState();
    _map.addListener(_onCameraRequest);
    _service = widget.busService;
    if (widget.initialNextBus case final nextBus?) {
      _seededNextBus = nextBus;
      _lastArrivalUpdate = DateTime.now();
    }
    if (_service != null) _directionIndex = _initialDirection(_service!);
    unawaited(_loadService());
  }

  int _initialDirection(BusService service) =>
      _directionForArrival(
        service,
        originStopCode: widget.originStopCode,
        destinationStopCode: widget.destinationStopCode,
      ) ??
      0;

  /// Returns the direction index that [originStopCode] and [destinationStopCode] identify, or null
  /// when they don't disambiguate a direction (such as a short-working trip with mid-route stops).
  int? _directionForArrival(
    BusService service, {
    String? originStopCode,
    String? destinationStopCode,
  }) {
    if (service.isLoopService || service.isSingleRoute || service.interchanges.length < 2) return 0;
    final first = service.interchanges[0].code;
    final second = service.interchanges[1].code;
    if (originStopCode == second || destinationStopCode == first) return 1;
    if (originStopCode == first || destinationStopCode == second) return 0;

    final routes = service.routes;
    if (routes != null &&
        originStopCode != null &&
        originStopCode.isNotEmpty &&
        destinationStopCode != null &&
        destinationStopCode.isNotEmpty) {
      final matches = <int>[
        for (var i = 0; i < routes.length; i++)
          if (_hasOrderedStops(routes[i], originStopCode, destinationStopCode)) i,
      ];
      if (matches.length == 1) return matches.single;
    }
    return null;
  }

  bool _hasOrderedStops(List<BusRouteInfo> route, String fromCode, String toCode) {
    final fromIndex = route.indexWhere((stop) => stop.busStop.code == fromCode);
    if (fromIndex < 0) return false;
    final toIndex = route.lastIndexWhere((stop) => stop.busStop.code == toCode);
    return toIndex > fromIndex;
  }

  Future<void> _loadService() async {
    final generation = ++_requestGeneration;
    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    try {
      final service = await TransitoApiService().getBusService(
        widget.serviceNo,
        includeRoutes: true,
      );
      if (!mounted || generation != _requestGeneration) return;
      final shapes = [
        for (final polyline in service.routePolylines ?? <String?>[]) _decodeShape(polyline),
      ];
      setState(() {
        if (_service == null) _directionIndex = _initialDirection(service);
        if (_directionIndex >= (service.routes?.length ?? 0)) _directionIndex = 0;
        _service = service;
        _shapes = shapes;
        _loading = false;
        _selectedStopIndex = null;
        _queueOriginScroll();
      });
      _scheduleListScroll();
      _syncArrivalPolling(generation);
    } catch (error) {
      if (!mounted || generation != _requestGeneration) return;
      setState(() {
        _loading = false;
        _loadFailed = true;
      });
    }
  }

  void _syncArrivalPolling(int generation) {
    _arrivalTimer?.cancel();
    _arrivalTimer = null;
    if (_currentStopOnActiveRoute == null) return;
    unawaited(_fetchNextBus(generation));
    _arrivalTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (!mounted || ModalRoute.of(context)?.isCurrent == false) return;
      unawaited(_fetchNextBus(generation));
    });
  }

  Future<void> _fetchNextBus(int generation) async {
    final stop = _currentStopOnActiveRoute;
    final service = _service;
    if (stop == null || service == null) return;
    final fetchId = ++_arrivalFetchGeneration;

    final BusStopProviderSources? sources;
    if (service.operator == BusOperator.NUS) {
      final nusCode = stop.sources?.nus;
      if (nusCode == null || nusCode.isEmpty) return;
      sources = BusStopProviderSources(nus: nusCode);
    } else if (service.operator != BusOperator.NA) {
      final ltaCode = stop.sources?.lta;
      sources = BusStopProviderSources(
        lta: ltaCode != null && ltaCode.isNotEmpty ? ltaCode : stop.code,
      );
    } else {
      sources = stop.sources;
    }

    try {
      final info = await BusArrivalService().getBusArrival(stop.code, sources: sources);
      if (!mounted || generation != _requestGeneration || fetchId != _arrivalFetchGeneration) {
        return;
      }
      setState(() {
        _arrivalServices = info.services;
        _seededNextBus = null;
        _lastArrivalUpdate = DateTime.now();
      });
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Could not fetch next bus location for ${widget.serviceNo}: $error');
      }
      if (!mounted || generation != _requestGeneration || fetchId != _arrivalFetchGeneration) {
        return;
      }
      final updatedAt = _lastArrivalUpdate;
      if (updatedAt != null && DateTime.now().difference(updatedAt) > const Duration(seconds: 60)) {
        setState(() {
          _arrivalServices = const [];
          _seededNextBus = null;
          _lastArrivalUpdate = null;
        });
      }
    }
  }

  List<LatLng> _decodeShape(String? polyline) {
    if (polyline == null || polyline.isEmpty) return const [];
    try {
      final points = decodePolyline(polyline).unpackPolyline();
      if (points.length < 2 ||
          points.any(
            (point) =>
                !point.latitude.isFinite ||
                !point.longitude.isFinite ||
                point.latitude.abs() > 90 ||
                point.longitude.abs() > 180,
          )) {
        return const [];
      }
      return points;
    } catch (error) {
      // Geometry is optional. A bad shape must not prevent the stop list from loading.
      if (kDebugMode) debugPrint('Could not decode route shape for ${widget.serviceNo}: $error');
      return const [];
    }
  }

  void _queueOriginScroll() {
    final index = _routes.indexWhere((route) => route.busStop.code == widget.currentStopCode);
    _pendingScrollIndex = index < 0 ? 0 : index;
  }

  void _scheduleListScroll() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _pendingScrollIndex == null || _routeScrollController?.hasClients != true) {
        return;
      }
      final controller = _routeScrollController!;
      final index = _pendingScrollIndex!;
      _pendingScrollIndex = null;
      final compensation = _pendingScrollCompensation;
      _pendingScrollCompensation = 0;
      // Keep the visible rows still when the previous selection above collapsed this frame.
      if (compensation > 0) {
        controller.jumpTo(
          (controller.offset - compensation).clamp(0.0, controller.position.maxScrollExtent),
        );
      }
      _lastScrollIndex = index;
      final generation = ++_revealGeneration;
      unawaited(
        controller
            .animateTo(
              _listOffsetOf(index).clamp(0.0, controller.position.maxScrollExtent),
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeInOutCubicEmphasized,
            )
            .then((_) => _settleReveal(index, generation)),
      );
    });
  }

  /// Corrects the reveal once the sheet and the selected row have reached their final sizes,
  /// which the first animation can't know, e.g. selecting the last stop from an expanded sheet.
  /// Skipped if a newer reveal, a direction change, or a user drag has happened since.
  Future<void> _settleReveal(int index, int generation) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    final controller = _routeScrollController;
    if (!mounted || generation != _revealGeneration || controller?.hasClients != true) return;
    final target = _listOffsetOf(index).clamp(0.0, controller!.position.maxScrollExtent);
    if ((target - controller.offset).abs() <= 1) return;
    await controller.animateTo(
      target,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
    );
  }

  // Not a setState: only the next selection's scroll compensation reads it.
  void _onActionsExtentChanged(double extent) => _actionsExtent = extent;

  /// Scroll offset that puts unselected-height row [index] just below the header.
  /// A pinned header overlaps the list, so no header height is added in that case.
  double _listOffsetOf(int index) => index * _rowExtent + (_headerPinned ? 0 : _headerHeight);

  void _onRowExtentChanged(double extent) {
    if (!mounted || extent <= 0 || (extent - _rowExtent).abs() < 0.5) return;
    setState(() => _rowExtent = extent);
    // The first scroll can run before any row has been measured; retarget it.
    _pendingScrollIndex ??= _lastScrollIndex;
    if (_pendingScrollIndex != null) _scheduleListScroll();
  }

  void _selectStop(int index, {bool focusMap = false}) {
    final stop = _routes[index].busStop;
    // The previous selection collapses at once. Only the part of its actions already scrolled
    // past the top of the list shifts the visible rows, so compensate for just that part.
    final previous = _selectedStopIndex;
    final controller = _routeScrollController;
    if (previous != null && previous != index && controller?.hasClients == true) {
      final actionsTop = _listOffsetOf(previous) + _rowExtent;
      _pendingScrollCompensation = (controller!.offset - actionsTop).clamp(0.0, _actionsExtent);
    }
    setState(() {
      _selectedStopIndex = index;
      _pendingScrollIndex = index;
    });
    _scheduleListScroll();
    if (focusMap) _map.focusStop(LatLng(stop.latitude, stop.longitude));
  }

  /// Selecting a stop always shows it on the map; its row then offers the stop's actions.
  void _tapStopCard(BusStop stop, {int? index}) {
    if (_isExpanded) _animateSheet(_collapsedSheetHeight);
    final routeIndex = index ?? _routes.indexWhere((route) => route.busStop.code == stop.code);
    if (routeIndex >= 0) {
      _selectStop(routeIndex, focusMap: true);
    } else {
      setState(() => _selectedStopIndex = null);
      _map.focusStop(LatLng(stop.latitude, stop.longitude));
    }
  }

  void _switchDirection() {
    final routeCount = _service?.routes?.length ?? 0;
    if (routeCount < 2) return;
    _collapseForOverview();
    _revealGeneration++;
    _pendingScrollCompensation = 0;
    setState(() {
      _directionIndex = (_directionIndex + 1) % routeCount;
      _selectedStopIndex = null;
      _queueOriginScroll();
    });
    _scheduleListScroll();
    _syncArrivalPolling(_requestGeneration);
  }

  /// Camera targets are framed above the collapsed sheet, so an expanded sheet would cover them.
  void _collapseForOverview() {
    if (_isExpanded) _animateSheet(_collapsedSheetHeight);
  }

  void _onCameraRequest() {
    if (_map.focus == null) _collapseForOverview();
  }

  void _animateSheet(double size) {
    if (!_drawer.isAttached) return;
    unawaited(
      _drawer.animateTo(
        size,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubicEmphasized,
      ),
    );
  }

  @override
  void dispose() {
    _arrivalTimer?.cancel();
    _drawer.dispose();
    _map
      ..removeListener(_onCameraRequest)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = context.select<CommonProvider, bool>((provider) => provider.isTablet);
    final scheme = Theme.of(context).colorScheme;
    final padding = MediaQuery.paddingOf(context);
    // Status bar plus the row of floating controls; the expanded sheet stops below it.
    final topInset = padding.top + 8 + 48 + 8;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final height = math.max(1.0, constraints.maxHeight);
          _expandedSheetHeight = ((height - topInset) / height).clamp(0.5, 1.0);
          _headerPinned = _headerHeight <= _expandedSheetHeight * height / 2;
          _collapsedSheetHeight = math
              .max(0.6, (_headerHeight + _rowExtent + padding.bottom + 8) / height)
              .clamp(0.2, _expandedSheetHeight - 0.05);
          return Stack(
            key: QuickStartTargetScope.keyOf(context, QuickStartTarget.serviceInfoPage),
            children: [
              Positioned.fill(
                child: BusRouteMap(
                  controller: _map,
                  routes: _routes,
                  shape: _shape,
                  panelHeight: _collapsedSheetHeight * height,
                  topInset: topInset,
                  routeColor: _routeColor(context.watch<AppColors>()),
                  onStopTap: _selectStop,
                  selectedStopIndex: _selectedStopIndex,
                  currentStopCode: widget.currentStopCode,
                  busLocation: _nextBusLocation,
                ),
              ),
              Positioned(
                top: padding.top + 8,
                left: 16,
                child: IconButton.filledTonal(
                  key: QuickStartTargetScope.keyOf(context, QuickStartTarget.serviceInfoBack),
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                  style: IconButton.styleFrom(
                    backgroundColor: scheme.surfaceContainerHighest,
                    foregroundColor: scheme.onSurface,
                    elevation: 4,
                    minimumSize: const Size.square(48),
                  ),
                  onPressed: () {
                    QuickStartTargetScope.activate(context, QuickStartTarget.serviceInfoBack);
                    Navigator.of(context).maybePop();
                  },
                  icon: const BackButtonIcon(),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: isTablet ? 640 : double.infinity),
                  child: DraggableScrollableSheet(
                    controller: _drawer,
                    snap: true,
                    minChildSize: _collapsedSheetHeight,
                    initialChildSize: _collapsedSheetHeight,
                    maxChildSize: _expandedSheetHeight,
                    builder: (context, scrollController) {
                      _routeScrollController = scrollController;
                      // Dragging a pinned header always moves the sheet. Otherwise, once the list
                      // has scrolled to a stop, upward swipes would scroll it instead of expanding.
                      // An unpinned header must scroll away, so only its handle drags the sheet.
                      final header = GestureDetector(
                        onVerticalDragUpdate: _headerPinned ? _dragSheet : null,
                        onVerticalDragEnd: _headerPinned ? _settleSheet : null,
                        child: MeasureSize(
                          onChange: (size) {
                            if (mounted && (size.height - _headerHeight).abs() > 0.5) {
                              setState(() => _headerHeight = size.height);
                            }
                          },
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ColoredBox(
                                color: scheme.surfaceContainerLow,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    _buildHandle(),
                                    BusServiceRouteHeader(
                                      serviceNo: widget.serviceNo,
                                      service: _service,
                                      routes: _routes,
                                      directionIndex: _directionIndex,
                                      onStopTap: _tapStopCard,
                                      onSwitchDirection: (_service?.routes?.length ?? 0) > 1
                                          ? _switchDirection
                                          : null,
                                    ),
                                    Divider(
                                      height: 1,
                                      indent: 16,
                                      endIndent: 16,
                                      color: scheme.outlineVariant.withValues(alpha: 0.5),
                                    ),
                                  ],
                                ),
                              ),
                              // An inset divider marks where the header ends, and stops scrolling
                              // under it fade out rather than meeting a hard edge.
                              IgnorePointer(
                                child: Container(
                                  height: 16,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        scheme.surfaceContainerLow,
                                        scheme.surfaceContainerLow.withValues(alpha: 0),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                      return Material(
                        color: scheme.surfaceContainerLow,
                        elevation: 3,
                        shadowColor: scheme.shadow,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: NotificationListener<ScrollStartNotification>(
                          // A user drag takes over from any pending reveal correction.
                          onNotification: (notification) {
                            if (notification.dragDetails != null) _revealGeneration++;
                            return false;
                          },
                          child: CustomScrollView(
                            controller: scrollController,
                            slivers: [
                              // A header taller than half the expanded sheet would leave too little
                              // room for stops if pinned, e.g. with large text, so it scrolls instead.
                              if (_headerPinned)
                                PinnedHeaderSliver(child: header)
                              else
                                SliverToBoxAdapter(child: header),
                              SliverPadding(
                                padding: EdgeInsets.fromLTRB(8, 0, 8, padding.bottom + 16),
                                sliver: _buildStopList(),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHandle() => ListenableBuilder(
    listenable: _drawer,
    builder: (context, _) => Semantics(
      button: true,
      label: _isExpanded ? 'Collapse route details' : 'Expand route details',
      onTap: _toggleSheet,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        excludeFromSemantics: true,
        onTap: _toggleSheet,
        onVerticalDragUpdate: _dragSheet,
        onVerticalDragEnd: _settleSheet,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 19.5),
          child: Center(
            child: CustomPaint(
              size: const Size(30, 9),
              painter: _SheetHandlePainter(
                progress: _sheetProgress,
                color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  /// The operator's colour, or the service's own colour for NUS shuttles.
  Color _routeColor(AppColors colors) {
    final service = _service;
    if (service == null) return Theme.of(context).colorScheme.primary;
    return service.operator == BusOperator.NUS
        ? colors.getNUSServiceColor(service.serviceNo).$1
        : colors.getOperatorColor(service.operator).$1;
  }

  void _dragSheet(DragUpdateDetails details) {
    if (!_drawer.isAttached) return;
    _drawer.jumpTo(
      (_drawer.size - _drawer.pixelsToSize(details.primaryDelta ?? 0)).clamp(
        _collapsedSheetHeight,
        _expandedSheetHeight,
      ),
    );
  }

  void _settleSheet(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    final expand = velocity.abs() > 500
        ? velocity < 0
        : _drawer.size > (_collapsedSheetHeight + _expandedSheetHeight) / 2;
    _animateSheet(expand ? _expandedSheetHeight : _collapsedSheetHeight);
  }

  void _toggleSheet() => _animateSheet(_isExpanded ? _collapsedSheetHeight : _expandedSheetHeight);

  Widget _buildStopList() {
    if (_loading) {
      return SliverList.separated(
        itemCount: 8,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (_, _) => SkeletonLine(
          style: SkeletonLineStyle(height: 60, borderRadius: BorderRadius.circular(16)),
        ),
      );
    }
    if (_loadFailed || _routes.isEmpty) {
      return SliverToBoxAdapter(
        child: ErrorText(
          enableBackground: true,
          title: _service == null ? "Couldn't load service information" : "Couldn't load routes",
          action: TextButton(onPressed: _loadService, child: const Text('Retry')),
        ),
      );
    }
    return BusRoutesList(
      routes: _routes,
      currentStopCode: widget.currentStopCode,
      selectedStopIndex: _selectedStopIndex,
      onRowExtentChanged: _onRowExtentChanged,
      onActionsExtentChanged: _onActionsExtentChanged,
      onStopTap: (index) => _tapStopCard(_routes[index].busStop, index: index),
    );
  }
}

/// A chevron that points up while the sheet is collapsed and bends through a flat bar to point
/// down as it expands, hinting which way the sheet moves.
class _SheetHandlePainter extends CustomPainter {
  const _SheetHandlePainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 4.0;
    final bend = (size.height - stroke) / 2 * (1 - 2 * progress);
    final midY = size.height / 2;
    final path = Path()
      ..moveTo(stroke / 2, midY + bend)
      ..lineTo(size.width / 2, midY - bend)
      ..lineTo(size.width - stroke / 2, midY + bend);
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_SheetHandlePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
