import 'package:transito/models/api/transito/bus_services.dart';

List<String> getBusStopServiceNumbers(List<BusStopServiceDetailed> services) {
  return services.map((service) => service.serviceNo).toSet().toList();
}
