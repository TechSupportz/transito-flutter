import 'package:transito/models/api/lta/bus_stops.dart';
import 'package:transito/models/favourites/favourite.dart';

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
