import 'package:json_annotation/json_annotation.dart';
import 'package:transito/models/api/transito/bus_stops.dart';
import 'package:transito/models/favourites/favourite.dart';

part 'nearby_bus_stops.g.dart';

@JsonSerializable(explicitToJson: true, createToJson: false)
class NearbyBusStopsApiResponse {
  int count;
  List<NearbyBusStop> data;

  NearbyBusStopsApiResponse({
    required this.count,
    required this.data,
  });

  factory NearbyBusStopsApiResponse.fromJson(Map<String, dynamic> json) =>
      _$NearbyBusStopsApiResponseFromJson(json);
}

@JsonSerializable(explicitToJson: true, createToJson: false)
class NearbyBusStop {
  BusStopInfo busStop;
  int distanceAway;

  NearbyBusStop({
    required this.busStop,
    required this.distanceAway,
  });

  factory NearbyBusStop.fromJson(Map<String, dynamic> json) => _$NearbyBusStopFromJson(json);
}

class NearbyFavourites {
  Favourite busStopInfo;
  double distanceFromUser;

  NearbyFavourites({
    required this.busStopInfo,
    required this.distanceFromUser,
  });
}
