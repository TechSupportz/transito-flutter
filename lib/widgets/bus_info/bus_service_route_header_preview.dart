import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:transito/models/api/transito/bus_services.dart';
import 'package:transito/models/api/transito/bus_stops.dart';
import 'package:transito/models/app/app_colors.dart';
import 'package:transito/models/enums/bus_operator_enum.dart';
import 'package:transito/widgets/bus_info/bus_service_route_header.dart';

@Preview(name: 'Route panel - light', group: 'Bus Service', size: Size(390, 260))
Widget routePanelLightPreview() => _preview(Brightness.light);

@Preview(name: 'Route panel - dark', group: 'Bus Service', size: Size(390, 260))
Widget routePanelDarkPreview() => _preview(Brightness.dark);

@Preview(name: 'Loop route panel', group: 'Bus Service', size: Size(390, 200))
Widget routePanelLoopPreview() => _preview(Brightness.light, loop: true);

Widget _preview(Brightness brightness, {bool loop = false}) {
  final stops = [
    BusStop(
      code: '75009',
      name: 'Tampines Int',
      roadName: 'Tampines Ctrl 1',
      latitude: 1.35407552367477,
      longitude: 103.94339098473914,
      services: ['10'],
    ),
    BusStop(
      code: '16009',
      name: 'Kent Ridge Ter',
      roadName: 'Clementi Rd',
      latitude: 1.294,
      longitude: 103.769,
      services: ['10'],
    ),
  ];
  final service = BusService(
    serviceNo: loop ? '119' : '10',
    operator: BusOperator.SBST,
    isLoopService: loop,
    isSingleRoute: loop,
    interchanges: loop
        ? [
            BusStop(
              code: '65009',
              name: 'Punggol Int',
              roadName: 'Punggol Pl',
              latitude: 1.40370629859822,
              longitude: 103.90224337575333,
              services: ['119'],
            ),
          ]
        : stops,
  );
  var direction = 0;
  return ChangeNotifierProvider(
    create: (_) => AppColors()..updateLocalColorScheme(AppColors.veryPurple, brightness),
    child: MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.veryPurple, brightness: brightness),
        fontFamily: 'DMSans',
      ),
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: StatefulBuilder(
            builder: (context, setState) => BusServiceRouteHeader(
              serviceNo: service.serviceNo,
              service: service,
              routes: const [],
              directionIndex: direction,
              onStopTap: (_) {},
              onSwitchDirection: loop
                  ? null
                  : () => setState(() => direction = (direction + 1) % 2),
            ),
          ),
        ),
      ),
    ),
  );
}
