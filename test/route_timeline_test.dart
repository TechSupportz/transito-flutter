import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:transito/global/utils/route_timeline.dart';

LatLng _between(LatLng a, LatLng b, double progress) => LatLng(
  a.latitude + (b.latitude - a.latitude) * progress,
  a.longitude + (b.longitude - a.longitude) * progress,
);

void main() {
  group('loop service at its terminal', () {
    // A square loop: A → B east, B → C north, C → D west, D → A south
    const a = LatLng(1.30, 103.80);
    const b = LatLng(1.30, 103.81);
    const c = LatLng(1.31, 103.81);
    const d = LatLng(1.31, 103.80);
    final timeline = RouteTimeline.fromShape([a, b, c, d, a], [a, b, c, d, a])!;
    // The current stop is the terminal, the route's first and last stop
    const visits = [0, 4];

    test('matches a loop\'s first stop to the start of the shape', () {
      expect(timeline.stopPositions.first.along, 0);
      expect(timeline.stopPositions.last.along, greaterThan(timeline.stopPositions[3].along));
    });

    test('hides a known departure from the first stop', () {
      expect(timeline.lastStopPassedBy(visits: visits, visitNumber: 1, bus: a), isNull);
      expect(
        timeline.lastStopPassedBy(visits: visits, visitNumber: 1, bus: _between(a, b, 0.1)),
        isNull,
      );
    });

    test('places a bus returning to the terminal on the stretch before it', () {
      expect(
        timeline.lastStopPassedBy(visits: visits, visitNumber: 2, bus: _between(c, d, 0.5)),
        2,
      );
    });

    test('places a bus of unknown visit on the nearest stretch', () {
      for (final visitNumber in [null, 0, 3]) {
        expect(
          timeline.lastStopPassedBy(
            visits: visits,
            visitNumber: visitNumber,
            bus: _between(b, c, 0.5),
          ),
          1,
        );
      }
    });
  });

  group('out-and-back route visiting a stop twice', () {
    // Stops A, X, E, X, A along one road; X sits midway between A and E
    const a = LatLng(1.30, 103.80);
    const e = LatLng(1.30, 103.81);
    final x = _between(a, e, 0.5);
    final timeline = RouteTimeline.fromShape([a, e, a], [a, x, e, x, a])!;
    const visits = [1, 3];

    test('uses the stretch LTA numbers', () {
      expect(
        timeline.lastStopPassedBy(visits: visits, visitNumber: 1, bus: _between(a, e, 0.25)),
        0,
      );
      expect(
        timeline.lastStopPassedBy(visits: visits, visitNumber: 2, bus: _between(a, e, 0.75)),
        1,
      );
    });

    test('ignores geometry outside a visit\'s stretch when the visit is unknown', () {
      // Past X towards E, the bus is on the stretch to X's second visit, although the first
      // stretch's segment continues under it
      expect(
        timeline.lastStopPassedBy(visits: visits, visitNumber: null, bus: _between(a, e, 0.75)),
        1,
      );
    });
  });

  test('has no stretch for a current stop that is only the first stop', () {
    const a = LatLng(1.30, 103.80);
    const b = LatLng(1.30, 103.81);
    final timeline = RouteTimeline.fromShape([a, b], [a, b])!;
    expect(timeline.lastStopPassedBy(visits: [0], visitNumber: null, bus: a), isNull);
  });

  test('needs a shape and stops', () {
    expect(RouteTimeline.fromShape(const [LatLng(1.3, 103.8)], const [LatLng(1.3, 103.8)]), isNull);
    expect(
      RouteTimeline.fromShape(const [LatLng(1.3, 103.8), LatLng(1.3, 103.81)], const []),
      isNull,
    );
  });
}
