import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:measure_size/measure_size.dart';
import 'package:flutter_skeleton_ui/flutter_skeleton_ui.dart';
import 'package:transito/models/api/transito/bus_routes.dart';
import 'package:transito/models/api/transito/bus_services.dart';
import 'package:transito/models/app/app_colors.dart';
import 'package:transito/models/secret.dart';
import 'package:transito/widgets/bus_info/bus_stop_card.dart';
import 'package:transito/widgets/common/error_text.dart';

class BusServiceInfoScreen extends StatefulWidget {
  const BusServiceInfoScreen({
    Key? key,
    required this.serviceNo,
    this.busService,
  }) : super(key: key);

  final String serviceNo;
  final BusService? busService;

  @override
  State<BusServiceInfoScreen> createState() => _BusServiceInfoScreenState();
}

class _BusServiceInfoScreenState extends State<BusServiceInfoScreen> {
  late Future<BusService> futureBusServiceInfo;
  late Future<List<List<BusRouteInfo>>> futureBusServiceRoutes;
  int _destinationIndex = 0;
  double sheetHeight = 0;

  Future<BusService> getBusService() async {
    final response = await http.get(Uri.parse('${Secret.API_URL}/bus-service/${widget.serviceNo}'));

    if (response.statusCode == 200) {
      debugPrint("Service info fetched");
      return BusServiceDetailsApiResponse.fromJson(json.decode(response.body)).data;
    } else {
      debugPrint("Error fetching bus service info");
      throw Exception("Error fetching bus service routes");
    }
  }

  Future<List<List<BusRouteInfo>>> getBusRoutes() async {
    final response = await http.get(Uri.parse(
        '${Secret.API_URL}/bus-service/${widget.serviceNo}?includeRoutes')); // NOTE - This should be replaced with an endpoint which just returns the routes

    if (response.statusCode == 200) {
      debugPrint("Service info fetched");
      return BusServiceDetailsApiResponse.fromJson(json.decode(response.body)).data.routes!;
    } else {
      debugPrint("Error fetching bus service info");
      throw Exception("Error fetching bus service routes");
    }
  }

  @override
  void initState() {
    super.initState();
    futureBusServiceInfo =
        widget.busService != null ? Future.value(widget.busService) : getBusService();
    futureBusServiceRoutes = getBusRoutes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('Bus Service Information'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
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
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SkeletonLine(
                      style: SkeletonLineStyle(
                          height: 25, width: 64, borderRadius: BorderRadius.circular(5)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                    child: SkeletonLine(
                  style: SkeletonLineStyle(
                    height: double.maxFinite,
                    width: double.infinity,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ))
              ],
            );

            if (snapshot.hasData || widget.busService != null) {
              final busService = snapshot.data as BusService;

              child = Stack(
                key: const ValueKey(1),
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) => MeasureSize(
                      onChange: (Size size) {
                        double gapPercentage =
                            MediaQuery.of(context).viewInsets.bottom > 0.0 ? 0.04 : 0.02;
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
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                    color: AppColors.getOperatorColor(busService.operator),
                                    borderRadius: BorderRadius.circular(5)),
                                child: Text(busService.operator.name,
                                    style: const TextStyle(fontWeight: FontWeight.w500)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Interchange${busService.isLoopService ? "" : "s"}",
                                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w600),
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
                                        ]
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.max,
                                      children: [
                                        if (busService.isLoopService) ...[
                                          Transform.rotate(
                                            angle: 45,
                                            child: const Icon(
                                              Icons.loop_rounded,
                                              color: AppColors.notReallyYellow,
                                              size: 28,
                                            ),
                                          ),
                                        ] else ...[
                                          const Padding(
                                            padding: EdgeInsets.only(bottom: 20),
                                            child: Icon(
                                              Icons.radio_button_unchecked_rounded,
                                              color: AppColors.prettyGreen,
                                              size: 28,
                                            ),
                                          ),
                                          if (busService.isSingleRoute) ...[
                                            const RotatedBox(
                                              quarterTurns: 1,
                                              child: Icon(
                                                Icons.arrow_right_alt_rounded,
                                                color: Colors.white,
                                                size: 28,
                                              ),
                                            ),
                                          ] else ...[
                                            Ink(
                                              height: 40,
                                              width: 40,
                                              decoration: BoxDecoration(
                                                color: AppColors.accentColour,
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: AnimatedRotation(
                                                turns: _destinationIndex == 0 ? 0 : -0.5,
                                                duration: const Duration(milliseconds: 175),
                                                child: IconButton(
                                                  padding: EdgeInsets.zero,
                                                  iconSize: 30,
                                                  splashRadius: 20,
                                                  enableFeedback: true,
                                                  icon: const Icon(
                                                    Icons.swap_vert_rounded,
                                                    color: Colors.white,
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
                                          const Padding(
                                            padding: EdgeInsets.only(top: 20),
                                            child: Icon(
                                              Icons.place_rounded,
                                              color: AppColors.sortaRed,
                                              size: 28,
                                            ),
                                          ),
                                        ],
                                      ])
                                ],
                              )
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  AnimatedOpacity(
                    opacity: sheetHeight == 0 ? 0 : 1,
                    duration: const Duration(milliseconds: 350),
                    child: DraggableScrollableSheet(
                      expand: true,
                      minChildSize: sheetHeight,
                      maxChildSize: 0.885,
                      initialChildSize: sheetHeight,
                      snap: true,
                      snapSizes: [
                        sheetHeight,
                        0.885,
                      ],
                      builder: (context, scrollController) {
                        return Container(
                          decoration: BoxDecoration(
                            color: AppColors.drawerBg,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
                          child: FutureBuilder(
                            future: futureBusServiceRoutes,
                            builder: (context, snapshot) {
                              Widget routeResults = CircularProgressIndicator(strokeWidth: 3);

                              if (snapshot.hasData) {
                                final routes = snapshot.data!;

                                routeResults = AnimatedSwitcher(
                                  transitionBuilder: (child, animation) => SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(0, 1),
                                      end: Offset.zero,
                                    ).animate(animation),
                                    child: child,
                                  ),
                                  switchInCurve: Curves.easeInOut,
                                  switchOutCurve: Curves.easeInOut,
                                  duration: const Duration(milliseconds: 275),
                                  child: _destinationIndex == 0
                                      ? ListView.separated(
                                          key: const ValueKey(0),
                                          padding: const EdgeInsets.only(bottom: 16),
                                          controller: scrollController,
                                          itemCount: routes[0].length,
                                          separatorBuilder: (context, _) =>
                                              const SizedBox(height: 12),
                                          itemBuilder: (context, index) => BusStopCard(
                                            busStopInfo: routes[0][index].busStop,
                                            routeMode: true,
                                            busSchedule: (
                                              firstBus: routes[0][index].firstBus,
                                              lastBus: routes[0][index].lastBus
                                            ),
                                          ),
                                        )
                                      : ListView.separated(
                                          key: const ValueKey(1),
                                          padding: const EdgeInsets.only(bottom: 16),
                                          controller: scrollController,
                                          itemCount: routes[1].length,
                                          separatorBuilder: (context, _) =>
                                              const SizedBox(height: 12),
                                          itemBuilder: (context, index) => BusStopCard(
                                            busStopInfo: routes[1][index].busStop,
                                            routeMode: true,
                                            busSchedule: (
                                              firstBus: routes[0][index].firstBus,
                                              lastBus: routes[0][index].lastBus
                                            ),
                                          ),
                                        ),
                                );
                              } else if (snapshot.hasError) {
                                return const ErrorText();
                              }

                              return Skeleton(
                                  isLoading: snapshot.connectionState == ConnectionState.waiting,
                                  skeleton: SkeletonListView(
                                    padding: EdgeInsets.zero,
                                    itemBuilder: (context, _) => SkeletonLine(
                                      style: SkeletonLineStyle(
                                        height: 70,
                                        borderRadius: BorderRadius.circular(10),
                                        padding: const EdgeInsets.only(bottom: 12),
                                      ),
                                    ),
                                  ),
                                  child: routeResults);
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            } else if (snapshot.hasError) {
              child = const ErrorText();
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
