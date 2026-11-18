import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

/// A point on a Route Shape: its segment, fraction along that segment, distance along the shape,
/// and distance from the line, all in metres.
typedef ShapePosition = ({int segment, double t, double along, double offset});

/// Places a direction's stops along its Route Shape so a bus can be placed between them.
class RouteTimeline {
  RouteTimeline._(this.shape, this._distances, this.stopPositions);

  /// Matches [stops] onto [shape] in order, or returns null without a shape or stops.
  static RouteTimeline? fromShape(List<LatLng> shape, List<LatLng> stops) {
    if (shape.length < 2 || stops.isEmpty) return null;
    const distance = Distance();
    final distances = [0.0];
    for (var i = 0; i < shape.length - 1; i++) {
      distances.add(distances.last + distance.as(LengthUnit.Meter, shape[i], shape[i + 1]));
    }

    final positions = <ShapePosition>[];
    ShapePosition? previous;
    for (final stop in stops) {
      // Each stop is no earlier along the shape than the one before, even within one segment, so
      // stops on a road the route retraces keep their order and a loop's first stop matches the
      // start of the shape rather than its end.
      final candidates = [
        for (var i = previous?.segment ?? 0; i < shape.length - 1; i++)
          _project(stop, shape, distances, i, minT: i == previous?.segment ? previous!.t : 0),
      ];
      final nearest = candidates.map((c) => c.offset).reduce(math.min);
      // The earliest close match, so a later pass over the same road isn't chosen.
      final match = candidates.firstWhere((c) => c.offset <= nearest + 25);
      positions.add(match);
      previous = match;
    }
    return RouteTimeline._(shape, distances, positions);
  }

  final List<LatLng> shape;
  final List<double> _distances;

  /// Each stop's position along [shape], in route order.
  final List<ShapePosition> stopPositions;

  /// The index of the stop a bus at [bus] last passed on its way to the current stop, which the
  /// route reaches at each index in [visits]. [visitNumber] is LTA's 1-based visit, or null or 0
  /// when unknown.
  ///
  /// Returns null when the bus is departing from the route's first stop, as it has no stretch of
  /// route before it to be on.
  int? lastStopPassedBy({
    required List<int> visits,
    required int? visitNumber,
    required LatLng bus,
  }) {
    // Each visit to the current stop is reached through the stretch of route since the previous one
    final sections = [
      for (var v = 0; v < visits.length; v++)
        if (visits[v] > 0) (from: v == 0 ? 0 : visits[v - 1], to: visits[v]),
    ];
    if (sections.isEmpty) return null;

    ({int from, int to}) section;
    ShapePosition best;
    if (visitNumber != null && visitNumber >= 1 && visitNumber <= visits.length) {
      final target = visits[visitNumber - 1];
      // A known departure from the first stop, such as at a loop's terminal
      if (target == 0) return null;
      section = sections.firstWhere((section) => section.to == target);
      best = _nearestInSection(bus, section);
    } else {
      section = sections.first;
      best = _nearestInSection(bus, section);
      for (final candidate in sections.skip(1)) {
        final projection = _nearestInSection(bus, candidate);
        if (projection.offset < best.offset) {
          best = projection;
          section = candidate;
        }
      }
    }

    var lastPassed = section.from;
    for (var i = section.from + 1; i < section.to; i++) {
      if (stopPositions[i].along <= best.along) lastPassed = i;
    }
    return lastPassed;
  }

  /// The point nearest [point] on the stretch of shape from stop [section.from] to [section.to],
  /// from the start of the shape for the first stop.
  ShapePosition _nearestInSection(LatLng point, ({int from, int to}) section) {
    final start = section.from == 0 ? null : stopPositions[section.from];
    final end = stopPositions[section.to];
    final first = start?.segment ?? 0;
    ShapePosition? best;
    for (var i = first; i <= end.segment; i++) {
      final candidate = _project(
        point,
        shape,
        _distances,
        i,
        minT: i == first ? (start?.t ?? 0) : 0,
        maxT: i == end.segment ? end.t : 1,
      );
      if (best == null || candidate.offset < best.offset) best = candidate;
    }
    return best!;
  }

  /// Projects [point] onto segment [segment] of [shape], between fractions [minT] and [maxT] along
  /// it, measuring in metres.
  static ShapePosition _project(
    LatLng point,
    List<LatLng> shape,
    List<double> distances,
    int segment, {
    double minT = 0,
    double maxT = 1,
  }) {
    const metresPerDegreeLat = 110574.0;
    final metresPerDegreeLng = 111320.0 * math.cos(point.latitudeInRad);
    final start = shape[segment];
    final end = shape[segment + 1];
    final endX = (end.longitude - start.longitude) * metresPerDegreeLng;
    final endY = (end.latitude - start.latitude) * metresPerDegreeLat;
    final pointX = (point.longitude - start.longitude) * metresPerDegreeLng;
    final pointY = (point.latitude - start.latitude) * metresPerDegreeLat;
    final lengthSquared = endX * endX + endY * endY;
    final upper = math.max(minT, maxT);
    final t = lengthSquared == 0
        ? minT
        : ((pointX * endX + pointY * endY) / lengthSquared).clamp(minT, upper);
    final offsetX = pointX - t * endX;
    final offsetY = pointY - t * endY;
    return (
      segment: segment,
      t: t,
      along: distances[segment] + t * (distances[segment + 1] - distances[segment]),
      offset: math.sqrt(offsetX * offsetX + offsetY * offsetY),
    );
  }
}
