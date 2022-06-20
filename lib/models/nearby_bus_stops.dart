import 'package:transito/models/favourite.dart';

import 'bus_stops.dart';

class NearbyBusStops {
  BusStopInfo busStopInfo;
  double distanceFromUser;

  NearbyBusStops({
    required this.busStopInfo,
    required this.distanceFromUser,
  });
}

class NearbyFavourites {
  Favourite busStopInfo;
  double distanceFromUser;

  NearbyFavourites({
    required this.busStopInfo,
    required this.distanceFromUser,
  });
}
