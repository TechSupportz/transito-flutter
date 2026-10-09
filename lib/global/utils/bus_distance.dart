import 'dart:math' as math;

import 'package:latlong2/latlong.dart';
import 'package:transito/models/app/route_distance_index.dart';

const Distance _distance = Distance();

/// Furthest a bus may sit from its route segment before the match is treated as unreliable.
const double _maxSegmentOffsetMetres = 250;

/// Segment matches this close to the best offset are considered equally plausible.
const double _ambiguousOffsetMetres = 40;

/// Plausible matches whose remaining distances differ by more than this are ambiguous.
const double _ambiguousRemainingMetres = 300;

/// Estimates how far a bus is from a bus stop in metres, or null when the bus position is unknown.
///
/// Follows the service route when [index] can place the bus on it confidently. Otherwise, and as a
/// lower bound because route distances are rounded, uses the straight-line distance.
double? busDistanceAway({
  required LatLng busLocation,
  required LatLng busStopLocation,
  required String serviceNo,
  required String busStopCode,
  String? originCode,
  int? visitNumber,
  RouteDistanceIndex? index,
}) {
  if (busLocation.latitude == 0 || busLocation.longitude == 0) return null;

  final double straightLine = _distance.as(LengthUnit.Meter, busLocation, busStopLocation);
  if (index == null || originCode == null || originCode.isEmpty) return straightLine;

  final double? alongRoute = routeDistanceAway(
    index: index,
    serviceNo: serviceNo,
    originCode: originCode,
    visitNumber: visitNumber,
    busStopCode: busStopCode,
    busLocation: busLocation,
  );

  return alongRoute == null ? straightLine : math.max(alongRoute, straightLine);
}

/// Distance in metres along the service route from [busLocation] to [busStopCode], or null when the
/// bus cannot be matched to the route with confidence. A null or non-positive [visitNumber] is
/// treated as unknown.
double? routeDistanceAway({
  required RouteDistanceIndex index,
  required String serviceNo,
  required String originCode,
  required int? visitNumber,
  required String busStopCode,
  required LatLng busLocation,
}) {
  final List<List<RouteStop>>? routes = index.services[serviceNo];
  // A bus bound for its own origin is departing; there is no route section to follow
  if (routes == null || busStopCode == originCode) return null;

  final List<_SegmentMatch> matches = [];
  for (final List<RouteStop> route in routes) {
    final int originIndex = route.indexWhere((stop) => stop.code == originCode);
    if (originIndex == -1) continue;

    for (final int targetIndex in _targetIndices(route, originIndex, busStopCode, visitNumber)) {
      for (int i = originIndex; i < targetIndex; i++) {
        final _SegmentMatch? match = _matchSegment(
          index,
          route[i],
          route[i + 1],
          route[targetIndex],
          busLocation,
        );
        if (match != null && match.offset <= _maxSegmentOffsetMetres) matches.add(match);
      }
    }
  }

  if (matches.isEmpty) return null;

  // Overlapping sections, such as both legs of a loop on one road, or an unknown visit to a repeated
  // stop, can place the bus at very different points of the route; prefer the straight-line
  // fallback to a confident wrong answer
  final _SegmentMatch best = matches.reduce((a, b) => a.offset <= b.offset ? a : b);
  final Iterable<double> plausibleRemaining = matches
      .where((match) => match.offset <= best.offset + _ambiguousOffsetMetres)
      .map((match) => match.remaining);
  final double spread = plausibleRemaining.reduce(math.max) - plausibleRemaining.reduce(math.min);
  if (spread > _ambiguousRemainingMetres || best.remaining < 0) return null;

  return best.remaining;
}

/// Formats [metres] as whole metres below 1 km, otherwise as kilometres to one decimal place.
String formatDistance(double metres) {
  if (metres < 1000) return '${metres.toStringAsFixed(0)}m';
  return '${(metres / 1000).toStringAsFixed(1)}km';
}

/// Indices of [busStopCode] after the route's origin: the [visitNumber]th occurrence, or every
/// occurrence when the visit is unknown.
List<int> _targetIndices(
  List<RouteStop> route,
  int originIndex,
  String busStopCode,
  int? visitNumber,
) {
  final List<int> occurrences = [
    for (int i = originIndex + 1; i < route.length; i++)
      if (route[i].code == busStopCode) i,
  ];
  // LTA sends a blank VisitNumber, parsed as 0, for some arrivals
  if (visitNumber == null || visitNumber < 1) return occurrences;
  return visitNumber <= occurrences.length ? [occurrences[visitNumber - 1]] : [];
}

class _SegmentMatch {
  const _SegmentMatch(this.offset, this.remaining);

  /// Metres between the bus and the closest point on the segment.
  final double offset;

  /// Metres along the route from that point to the target stop.
  final double remaining;
}

_SegmentMatch? _matchSegment(
  RouteDistanceIndex index,
  RouteStop from,
  RouteStop to,
  RouteStop target,
  LatLng busLocation,
) {
  final LatLng? start = index.stops[from.code];
  final LatLng? end = index.stops[to.code];
  if (start == null || end == null) return null;

  // An equirectangular projection is accurate to well under a metre over a stop-to-stop segment
  final double metresPerDegreeLat = 110574;
  final double metresPerDegreeLng = 111320 * math.cos(start.latitudeInRad);
  final double endX = (end.longitude - start.longitude) * metresPerDegreeLng;
  final double endY = (end.latitude - start.latitude) * metresPerDegreeLat;
  final double busX = (busLocation.longitude - start.longitude) * metresPerDegreeLng;
  final double busY = (busLocation.latitude - start.latitude) * metresPerDegreeLat;

  final double lengthSquared = endX * endX + endY * endY;
  final double progress = lengthSquared == 0
      ? 0
      : ((busX * endX + busY * endY) / lengthSquared).clamp(0, 1);
  final double offsetX = busX - progress * endX;
  final double offsetY = busY - progress * endY;

  final double busDistanceKm = from.distanceKm + progress * (to.distanceKm - from.distanceKm);
  return _SegmentMatch(
    math.sqrt(offsetX * offsetX + offsetY * offsetY),
    (target.distanceKm - busDistanceKm) * 1000,
  );
}
