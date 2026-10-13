import 'package:material_ui/material_ui.dart';
import 'package:flutter_skeleton_ui/flutter_skeleton_ui.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:measure_size/measure_size.dart';
import 'package:provider/provider.dart';
import 'package:transito/global/providers/quick_start_tour_provider.dart';
import 'package:transito/global/services/transito_api_service.dart';
import 'package:transito/models/api/transito/bus_routes.dart';
import 'package:transito/models/api/transito/bus_services.dart';
import 'package:transito/models/app/app_colors.dart';
import 'package:transito/models/app/app_typography.dart';
import 'package:transito/widgets/bus_info/bus_routes_list.dart';
import 'package:transito/widgets/bus_info/bus_stop_card.dart';
import 'package:transito/widgets/common/app_symbol.dart';
import 'package:transito/widgets/common/error_text.dart';

class BusServiceInfoScreen extends StatefulWidget {
  const BusServiceInfoScreen({
    super.key,
    required this.serviceNo,
    this.originStopCode,
    this.destinationStopCode,
    this.currentStopCode,
    this.busService,
  });

  final String serviceNo;
  final String? originStopCode;
  final String? destinationStopCode;
  final String? currentStopCode;
  final BusService? busService;

  @override
  State<BusServiceInfoScreen> createState() => _BusServiceInfoScreenState();
}

class _BusServiceInfoScreenState extends State<BusServiceInfoScreen> {
  late Future<BusService> futureBusServiceInfo;
  late Future<List<List<BusRouteInfo>>> futureBusServiceRoutes;
  late ScrollController routeScrollController;

  static const double _expandedSheetHeight = 0.885;

  DraggableScrollableController drawerScrollController = DraggableScrollableController();
  int _destinationIndex = 0;
  bool initialisedDestinationIndex = false;
  double sheetHeight = 0;

  // The direction whose list has already been scrolled to the current stop
  int? _scrolledToStopIndex;

  double _lastSheetSize = 0;
  bool _sheetExpanding = false;

  void animateSheet(double size) {
    drawerScrollController.animateTo(
      size,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOutCubicEmphasized,
    );
  }

  /// Finishes a sheet movement that stopped between the collapsed and expanded sizes, in the
  /// direction it was last moving.
  void snapSheet() {
    if (!drawerScrollController.isAttached) return;
    final double size = drawerScrollController.size;
    if (size <= sheetHeight + 0.001 || size >= _expandedSheetHeight - 0.001) return;
    animateSheet(_sheetExpanding ? _expandedSheetHeight : sheetHeight);
  }

  Future<BusService> getBusService() async {
    final BusService service = await TransitoApiService().getBusService(widget.serviceNo);
    debugPrint("Service info fetched");
    return service;
  }

  Future<List<List<BusRouteInfo>>> getBusRoutes() async {
    final List<List<BusRouteInfo>> routes = await TransitoApiService().getBusRoutes(
      widget.serviceNo,
    );
    debugPrint("Service info fetched");
    return routes;
  }

  int getDestinationIndex(BusService busService) {
    if (widget.originStopCode == busService.interchanges[0].code) {
      return 0;
    }

    if (widget.originStopCode == busService.interchanges[1].code) {
      return 1;
    }

    if (widget.destinationStopCode == busService.interchanges[1].code) {
      return 0;
    }

    if (widget.destinationStopCode == busService.interchanges[0].code) {
      return 1;
    }

    return _destinationIndex;
  }

  @override
  void initState() {
    super.initState();
    futureBusServiceInfo = widget.busService != null
        ? Future.value(widget.busService)
        : getBusService();
    futureBusServiceRoutes = getBusRoutes();
  }

  @override
  void dispose() {
    drawerScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    AppColors appColors = context.read<AppColors>();

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        leading: BackButton(
          key: QuickStartTargetScope.keyOf(context, QuickStartTarget.serviceInfoBack),
          onPressed: () {
            QuickStartTargetScope.activate(context, QuickStartTarget.serviceInfoBack);
            Navigator.of(context).maybePop();
          },
        ),
        title: const Text('Bus Service Information'),
      ),
      body: Padding(
        key: QuickStartTargetScope.keyOf(context, QuickStartTarget.serviceInfoPage),
        padding: const EdgeInsets.only(top: 12.0, left: 12, right: 12),
        child: FutureBuilder(
          future: futureBusServiceInfo,
          builder: (context, snapshot) {
            Widget child = Column(
              key: const ValueKey(0),
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bus ${widget.serviceNo}',
                      overflow: TextOverflow.fade,
                      maxLines: 1,
                      softWrap: false,
                      style: AppTypography.screenHeading,
                    ),
                    SkeletonLine(
                      style: SkeletonLineStyle(
                        height: 25,
                        width: 64,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SkeletonLine(
                    style: SkeletonLineStyle(
                      height: double.maxFinite,
                      width: double.infinity,
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
              ],
            );

            if (snapshot.hasData || widget.busService != null) {
              final busService = snapshot.data as BusService;

              if (!initialisedDestinationIndex &&
                  !busService.isLoopService &&
                  !busService.isSingleRoute) {
                _destinationIndex = getDestinationIndex(busService);
              }

              initialisedDestinationIndex = true;

              child = Stack(
                key: const ValueKey(1),
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) => MeasureSize(
                      onChange: (Size size) {
                        double gapPercentage = MediaQuery.of(context).viewInsets.bottom > 0.0
                            ? 0.04
                            : 0.02;
                        double heightPercentage =
                            (1 - gapPercentage) - (size.height / constraints.maxHeight);
                        setState(() {
                          sheetHeight = heightPercentage;
                        });
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Bus ${widget.serviceNo}',
                                overflow: TextOverflow.fade,
                                maxLines: 1,
                                softWrap: false,
                                style: AppTypography.screenHeading,
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  color: appColors.getOperatorColor(busService.operator).$1,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  busService.operator.name,
                                  style: AppBusTypography.busInfoChipLabel.copyWith(
                                    color: appColors.getOperatorColor(busService.operator).$2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Fade the interchanges out as the sheet expands over them
                          ListenableBuilder(
                            listenable: drawerScrollController,
                            builder: (context, child) {
                              double opacity = 1;
                              if (drawerScrollController.isAttached && sheetHeight > 0) {
                                final double progress =
                                    (drawerScrollController.size - sheetHeight) /
                                    (_expandedSheetHeight - sheetHeight);
                                opacity = 1 - progress.clamp(0.0, 1.0);
                              }
                              return Opacity(opacity: opacity, child: child);
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Interchange${busService.isLoopService ? "" : "s"}",
                                  style: AppTypography.sectionTitle,
                                  textAlign: TextAlign.start,
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Flexible(
                                      child: Column(
                                        verticalDirection: _destinationIndex == 0
                                            ? VerticalDirection.down
                                            : VerticalDirection.up,
                                        children: [
                                          BusStopCard(
                                            busStopInfo: busService.interchanges[0],
                                            searchMode: true,
                                          ),
                                          if (!busService.isLoopService) ...[
                                            const SizedBox(height: 24),
                                            BusStopCard(
                                              busStopInfo: busService.interchanges[1],
                                              searchMode: true,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.max,
                                      children: [
                                        if (busService.isLoopService) ...[
                                          AppSymbol(
                                            Symbols.sync_rounded,
                                            color: appColors.notReallyYellow,
                                            size: 28,
                                          ),
                                        ] else ...[
                                          Padding(
                                            padding: const EdgeInsets.only(bottom: 20),
                                            child: AppSymbol(
                                              Symbols.trip_origin_rounded,
                                              color: appColors.prettyGreen,
                                              size: 28,
                                            ),
                                          ),
                                          if (busService.isSingleRoute) ...[
                                            AppSymbol(
                                              Symbols.south_rounded,
                                              color: Colors.white,
                                              size: 28,
                                            ),
                                          ] else ...[
                                            Ink(
                                              height: 40,
                                              width: 40,
                                              decoration: BoxDecoration(
                                                color: Theme.of(context).colorScheme.primary,
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: AnimatedRotation(
                                                turns: _destinationIndex == 0 ? 0 : -0.5,
                                                duration: const Duration(milliseconds: 200),
                                                child: IconButton(
                                                  padding: EdgeInsets.zero,
                                                  iconSize: 30,
                                                  splashRadius: 20,
                                                  enableFeedback: true,
                                                  icon: AppSymbol(
                                                    Symbols.swap_vert_rounded,
                                                    color: Theme.of(context).colorScheme.onPrimary,
                                                    opticalSize: 30,
                                                  ),
                                                  onPressed: () {
                                                    setState(
                                                      () => _destinationIndex =
                                                          (_destinationIndex + 1) % 2,
                                                    );
                                                  },
                                                ),
                                              ),
                                            ),
                                          ],
                                          Padding(
                                            padding: const EdgeInsets.only(top: 20),
                                            child: AppSymbol(
                                              Symbols.distance_rounded,
                                              color: appColors.sortaRed,
                                              fill: true,
                                              size: 28,
                                            ),
                                          ),
                                        ],
                                      ],
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
                  AnimatedOpacity(
                    opacity: sheetHeight == 0 ? 0 : 1,
                    duration: const Duration(milliseconds: 350),
                    // The sheet's own snapping ends a fling with no velocity, so the list never
                    // carries momentum after the sheet expands. Snap manually once it settles.
                    child: NotificationListener<DraggableScrollableNotification>(
                      onNotification: (notification) {
                        _sheetExpanding = notification.extent > _lastSheetSize;
                        _lastSheetSize = notification.extent;
                        return false;
                      },
                      child: NotificationListener<ScrollEndNotification>(
                        onNotification: (_) {
                          snapSheet();
                          return false;
                        },
                        child: DraggableScrollableSheet(
                          controller: drawerScrollController,
                          expand: true,
                          minChildSize: sheetHeight,
                          maxChildSize: _expandedSheetHeight,
                          initialChildSize: sheetHeight,
                          builder: (context, scrollController) {
                            return Container(
                              clipBehavior: Clip.antiAlias,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surfaceContainerLow,
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(24),
                                  topRight: Radius.circular(24),
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // The sheet only resizes from the list once it is scrolled to the
                                  // top, so the handle drags the sheet directly
                                  GestureDetector(
                                    onVerticalDragUpdate: (details) {
                                      drawerScrollController.jumpTo(
                                        (drawerScrollController.size -
                                                drawerScrollController.pixelsToSize(
                                                  details.primaryDelta!,
                                                ))
                                            .clamp(sheetHeight, _expandedSheetHeight),
                                      );
                                    },
                                    onVerticalDragEnd: (details) {
                                      final double velocity = details.primaryVelocity ?? 0;
                                      final bool expand = velocity.abs() > 500
                                          ? velocity < 0
                                          : drawerScrollController.size >
                                                (sheetHeight + _expandedSheetHeight) / 2;
                                      animateSheet(expand ? _expandedSheetHeight : sheetHeight);
                                    },
                                    child: InkWell(
                                      onTap: () => animateSheet(
                                        drawerScrollController.size < _expandedSheetHeight
                                            ? _expandedSheetHeight
                                            : sheetHeight,
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: FractionallySizedBox(
                                          widthFactor: 0.2,
                                          child: Container(
                                            height: 6,
                                            decoration: BoxDecoration(
                                              color:
                                                  Theme.of(
                                                    context,
                                                  ).colorScheme.onSurfaceVariant.withValues(
                                                    alpha: 0.15,
                                                  ),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: FutureBuilder(
                                      future: futureBusServiceRoutes,
                                      builder: (context, snapshot) {
                                        Widget routeResults = const CircularProgressIndicator(
                                          strokeWidth: 3,
                                        );

                                        if (snapshot.hasData) {
                                          final routes = snapshot.data!;
                                          int currentStopIndex = 0;

                                          if (widget.currentStopCode != null) {
                                            int busStopIndex = routes[_destinationIndex].indexWhere(
                                              (route) =>
                                                  route.busStop.code == widget.currentStopCode,
                                            );

                                            if (busStopIndex != -1) {
                                              currentStopIndex = busStopIndex;
                                            }
                                          }

                                          routeResults = AnimatedSwitcher(
                                            transitionBuilder: (child, animation) =>
                                                SlideTransition(
                                                  position: Tween<Offset>(
                                                    begin: const Offset(0, 2),
                                                    end: Offset.zero,
                                                  ).animate(animation),
                                                  transformHitTests: false,
                                                  textDirection: TextDirection.ltr,
                                                  child: child,
                                                ),
                                            switchInCurve: Curves.easeInOutCubicEmphasized,
                                            switchOutCurve: Curves.easeInOutCubicEmphasized,
                                            duration: const Duration(milliseconds: 350),
                                            child: _destinationIndex == 0
                                                ? BusRoutesList(
                                                    key: const ValueKey(0),
                                                    routes: routes[0],
                                                    controller: scrollController,
                                                    currentStopCode: widget.currentStopCode,
                                                  )
                                                : BusRoutesList(
                                                    key: const ValueKey(1),
                                                    routes: routes[1],
                                                    controller: scrollController,
                                                    currentStopCode: widget.currentStopCode,
                                                  ),
                                          );

                                          // Scroll once per direction, not on every rebuild, so a
                                          // rebuild never pulls the list away from where the user is
                                          if (_scrolledToStopIndex != _destinationIndex) {
                                            _scrolledToStopIndex = _destinationIndex;
                                            WidgetsBinding.instance.addPostFrameCallback((_) {
                                              if (!scrollController.hasClients) return;
                                              scrollController.animateTo(
                                                currentStopIndex * 88.0,
                                                duration: const Duration(seconds: 1),
                                                curve: Curves.easeInOutCubicEmphasized,
                                              );
                                            });
                                          }
                                        } else if (snapshot.hasError) {
                                          return const ErrorText(
                                            title: "Couldn't load routes",
                                          );
                                        }

                                        return Skeleton(
                                          isLoading:
                                              snapshot.connectionState == ConnectionState.waiting,
                                          skeleton: SkeletonListView(
                                            padding: EdgeInsets.zero,
                                            itemBuilder: (context, _) => SkeletonLine(
                                              style: SkeletonLineStyle(
                                                height: 70,
                                                borderRadius: BorderRadius.circular(12),
                                                padding: const EdgeInsets.only(bottom: 12),
                                              ),
                                            ),
                                          ),
                                          child: routeResults,
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              );
            } else if (snapshot.hasError) {
              child = const ErrorText(
                title: "Couldn't load service information",
              );
            }

            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              child: child,
            );
          },
        ),
      ),
    );
  }
}
