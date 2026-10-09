import 'package:latlong2/latlong.dart';

/// A stop within a service route and its cumulative distance from the route's origin.
class RouteStop {
  const RouteStop(this.code, this.distanceKm);

  final String code;
  final double distanceKm;
}

/// Compact route data published by transito-server to Firebase Storage.
///
/// The wire format is a deliberately terse array encoding, so it is parsed by hand rather than
/// through `json_serializable`.
class RouteDistanceIndex {
  const RouteDistanceIndex({required this.stops, required this.services});

  static const int schemaVersion = 1;

  final Map<String, LatLng> stops;

  /// Service number to its routes, each an ordered list of stops.
  final Map<String, List<List<RouteStop>>> services;

  factory RouteDistanceIndex.fromJson(Map<String, dynamic> json) {
    if (json['schemaVersion'] != schemaVersion) {
      throw FormatException('Unsupported route distance index schema: ${json['schemaVersion']}');
    }

    final Map<String, LatLng> stops = (json['stops'] as Map<String, dynamic>).map((code, value) {
      final List<dynamic> coordinates = value as List<dynamic>;
      return MapEntry(
        code,
        LatLng((coordinates[0] as num).toDouble(), (coordinates[1] as num).toDouble()),
      );
    });

    final Map<String, List<List<RouteStop>>> services = (json['services'] as Map<String, dynamic>)
        .map((serviceNo, value) {
          final List<List<RouteStop>> routes = (value as List<dynamic>).map((route) {
            return (route as List<dynamic>).map((stop) {
              final List<dynamic> entry = stop as List<dynamic>;
              return RouteStop(entry[0] as String, (entry[1] as num).toDouble());
            }).toList();
          }).toList();
          return MapEntry(serviceNo, routes);
        });

    return RouteDistanceIndex(stops: stops, services: services);
  }
}
