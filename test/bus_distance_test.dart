import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:transito/global/utils/bus_distance.dart';
import 'package:transito/models/app/route_distance_index.dart';

const Distance _distance = Distance();

// A U-shaped road: A → B heads east, B → C north, C → D west, leaving D about 556 m north of A
final Map<String, LatLng> _stops = {
  'A': const LatLng(1.300, 103.800),
  'B': const LatLng(1.300, 103.805),
  'C': const LatLng(1.305, 103.805),
  'D': const LatLng(1.305, 103.800),
  'Z': const LatLng(1.400, 103.900),
};

double _metres(String from, String to) =>
    _distance.as(LengthUnit.Meter, _stops[from]!, _stops[to]!);

/// Builds a route whose cumulative distances follow the stop geometry exactly.
List<RouteStop> _route(List<String> codes) {
  double km = 0;
  return [
    for (int i = 0; i < codes.length; i++)
      RouteStop(codes[i], km += i == 0 ? 0 : _metres(codes[i - 1], codes[i]) / 1000),
  ];
}

LatLng _between(String from, String to, double progress) {
  final LatLng a = _stops[from]!;
  final LatLng b = _stops[to]!;
  return LatLng(
    a.latitude + (b.latitude - a.latitude) * progress,
    a.longitude + (b.longitude - a.longitude) * progress,
  );
}

RouteDistanceIndex _index(Map<String, List<List<RouteStop>>> services) =>
    RouteDistanceIndex(stops: _stops, services: services);

double? _away(
  RouteDistanceIndex? index, {
  required LatLng bus,
  required String stop,
  String serviceNo = '1',
  String? origin = 'A',
  int? visit = 1,
}) => busDistanceAway(
  busLocation: bus,
  busStopLocation: _stops[stop]!,
  serviceNo: serviceNo,
  busStopCode: stop,
  originCode: origin,
  visitNumber: visit,
  index: index,
);

void main() {
  final RouteDistanceIndex uShape = _index({
    '1': [
      _route(['A', 'B', 'C', 'D']),
      _route(['D', 'C', 'B', 'A']),
    ],
  });

  group('busDistanceAway', () {
    test('returns null when the bus position is missing', () {
      expect(_away(uShape, bus: const LatLng(0, 103.8), stop: 'D'), isNull);
      expect(_away(uShape, bus: const LatLng(1.3, 0), stop: 'D'), isNull);
    });

    test('uses the straight line without route data', () {
      final LatLng bus = _between('A', 'B', 0.5);
      final double straight = _distance.as(LengthUnit.Meter, bus, _stops['D']!);

      expect(_away(null, bus: bus, stop: 'D'), closeTo(straight, 0.01));
      expect(_away(uShape, bus: bus, stop: 'D', serviceNo: 'missing'), closeTo(straight, 0.01));
      expect(_away(uShape, bus: bus, stop: 'D', origin: null), closeTo(straight, 0.01));
      expect(_away(uShape, bus: bus, stop: 'D', origin: 'Z'), closeTo(straight, 0.01));
    });

    test('follows the route instead of measuring across the U', () {
      final LatLng bus = _between('A', 'B', 0.5);
      final double expected = _metres('A', 'B') / 2 + _metres('B', 'C') + _metres('C', 'D');

      final double? away = _away(uShape, bus: bus, stop: 'D');

      expect(away, closeTo(expected, 5));
      expect(away, greaterThan(_distance.as(LengthUnit.Meter, bus, _stops['D']!) * 2));
    });

    test('selects the direction from the arrival origin', () {
      final LatLng bus = _between('D', 'C', 0.5);
      final double expected = _metres('D', 'C') / 2 + _metres('C', 'B');

      expect(_away(uShape, bus: bus, stop: 'B', origin: 'D'), closeTo(expected, 5));
    });

    test('matches a short-working trip that starts mid-route', () {
      final LatLng bus = _between('B', 'C', 0.25);
      final double expected = _metres('B', 'C') * 0.75 + _metres('C', 'D');

      expect(_away(uShape, bus: bus, stop: 'D', origin: 'B'), closeTo(expected, 5));
    });

    test('uses the visit number to pick a repeated stop on a loop', () {
      final RouteDistanceIndex loop = _index({
        '1': [
          _route(['A', 'B', 'C', 'D', 'B', 'A']),
        ],
      });
      final LatLng bus = _between('A', 'B', 0.5);
      final double toFirstVisit = _metres('A', 'B') / 2;
      final double toSecondVisit =
          toFirstVisit + _metres('B', 'C') + _metres('C', 'D') + _metres('D', 'B');

      expect(_away(loop, bus: bus, stop: 'B', visit: 1), closeTo(toFirstVisit, 5));
      expect(_away(loop, bus: bus, stop: 'B', visit: 2), closeTo(toSecondVisit, 5));
    });

    test('considers every visit when the visit number is unknown', () {
      final RouteDistanceIndex loop = _index({
        '1': [
          _route(['A', 'B', 'C', 'D', 'B', 'A']),
        ],
      });
      final LatLng beforeFirstVisit = _between('A', 'B', 0.5);
      final LatLng pastFirstVisit = _between('C', 'D', 0.5);

      // LTA sends a blank VisitNumber, parsed as 0, for some arrivals; NUS never sends a real one
      for (final int? visit in [0, null]) {
        expect(
          _away(loop, bus: beforeFirstVisit, stop: 'B', visit: visit),
          closeTo(_distance.as(LengthUnit.Meter, beforeFirstVisit, _stops['B']!), 0.01),
        );
        expect(
          _away(loop, bus: pastFirstVisit, stop: 'B', visit: visit),
          closeTo(_metres('C', 'D') / 2 + _metres('D', 'B'), 5),
        );
      }
    });

    test('falls back when a bus departs from its origin', () {
      final RouteDistanceIndex loop = _index({
        '1': [
          _route(['A', 'B', 'C', 'D', 'A']),
        ],
      });
      final LatLng bus = _between('A', 'B', 0.1);

      expect(
        _away(loop, bus: bus, stop: 'A'),
        closeTo(_distance.as(LengthUnit.Meter, bus, _stops['A']!), 0.01),
      );
    });

    test('falls back when overlapping route sections make the match ambiguous', () {
      // B → C is driven in both directions before the second visit to B
      final RouteDistanceIndex outAndBack = _index({
        '1': [
          _route(['A', 'B', 'C', 'B', 'A']),
        ],
      });
      final LatLng bus = _between('B', 'C', 0.5);

      expect(
        _away(outAndBack, bus: bus, stop: 'B', visit: 2),
        closeTo(_distance.as(LengthUnit.Meter, bus, _stops['B']!), 0.01),
      );
    });

    test('falls back when the spread of plausible matches is too wide', () {
      // Three service variants run along parallel roads about 11 m apart; each pair of neighbouring
      // matches disagrees by only 200 m, but the outermost two disagree by 400 m
      final Map<String, LatLng> stops = {
        'O': const LatLng(1.300, 103.790),
        'T': const LatLng(1.300, 103.815),
        for (final (String lane, double lat) in [('P', 1.300), ('Q', 1.3001), ('R', 1.3002)]) ...{
          '${lane}1': LatLng(lat, 103.800),
          '${lane}2': LatLng(lat, 103.805),
        },
      };
      List<RouteStop> variant(String lane, double startKm) => [
        const RouteStop('O', 0),
        RouteStop('${lane}1', startKm),
        RouteStop('${lane}2', startKm + 0.556),
        const RouteStop('T', 5),
      ];
      final RouteDistanceIndex index = RouteDistanceIndex(
        stops: stops,
        services: {
          '1': [variant('P', 1.972), variant('Q', 2.172), variant('R', 2.372)],
        },
      );

      expect(
        routeDistanceAway(
          index: index,
          serviceNo: '1',
          originCode: 'O',
          visitNumber: 1,
          busStopCode: 'T',
          busLocation: const LatLng(1.3001, 103.8025),
        ),
        isNull,
      );
    });

    test('ignores segments beyond the offset limit when checking for ambiguity', () {
      final Map<String, LatLng> stops = {
        'O': const LatLng(1.300, 103.790),
        'T': const LatLng(1.300, 103.815),
        'N1': const LatLng(1.30207, 103.800), // about 230 m north of the bus
        'N2': const LatLng(1.30207, 103.805),
        'S1': const LatLng(1.29766, 103.800), // about 260 m south of the bus
        'S2': const LatLng(1.29766, 103.805),
      };
      final RouteDistanceIndex index = RouteDistanceIndex(
        stops: stops,
        services: {
          '1': [
            const [
              RouteStop('O', 0),
              RouteStop('N1', 1),
              RouteStop('N2', 1.556),
              RouteStop('T', 3),
            ],
            const [
              RouteStop('O', 0),
              RouteStop('S1', 1),
              RouteStop('S2', 1.556),
              RouteStop('T', 5),
            ],
          ],
        },
      );

      expect(
        routeDistanceAway(
          index: index,
          serviceNo: '1',
          originCode: 'O',
          visitNumber: 1,
          busStopCode: 'T',
          busLocation: const LatLng(1.300, 103.8025),
        ),
        closeTo(1722, 5),
      );
    });

    test('falls back when the bus is far from the route', () {
      final LatLng bus = _between('A', 'Z', 0.5);

      expect(
        _away(uShape, bus: bus, stop: 'D'),
        closeTo(_distance.as(LengthUnit.Meter, bus, _stops['D']!), 0.01),
      );
    });

    test('never reports less than the straight line for a bus just past the stop', () {
      final LatLng bus = _between('B', 'C', 0.05);
      final double straight = _distance.as(LengthUnit.Meter, bus, _stops['B']!);

      expect(_away(uShape, bus: bus, stop: 'B'), closeTo(straight, 0.01));
    });

    test('never reports less than the straight line when route distances are rounded down', () {
      final RouteDistanceIndex rounded = _index({
        '1': [
          [
            const RouteStop('A', 0),
            const RouteStop('B', 0.1),
            const RouteStop('C', 0.2),
          ],
        ],
      });
      final LatLng bus = _between('A', 'B', 0.5);

      expect(
        _away(rounded, bus: bus, stop: 'C'),
        closeTo(_distance.as(LengthUnit.Meter, bus, _stops['C']!), 0.01),
      );
    });

    test('falls back when route distances decrease', () {
      final RouteDistanceIndex broken = _index({
        '1': [
          [
            const RouteStop('A', 5),
            const RouteStop('B', 6),
            const RouteStop('C', 1),
          ],
        ],
      });
      final LatLng bus = _between('A', 'B', 0.5);

      expect(
        _away(broken, bus: bus, stop: 'C'),
        closeTo(_distance.as(LengthUnit.Meter, bus, _stops['C']!), 0.01),
      );
    });
  });

  test('formatDistance switches to kilometres at 1 km', () {
    expect(formatDistance(999.4), '999m');
    expect(formatDistance(1000), '1.0km');
    expect(formatDistance(2345), '2.3km');
  });

  group('RouteDistanceIndex.fromJson', () {
    test('parses the compact wire format', () {
      final RouteDistanceIndex index = RouteDistanceIndex.fromJson({
        'schemaVersion': 1,
        'stops': {
          '01012': [1.296848, 103.852536],
          '01013': [1.297, 103.85],
        },
        'services': {
          '2': [
            [
              ['01012', 0],
              ['01013', 0.6],
            ],
          ],
        },
      });

      expect(index.stops['01012'], const LatLng(1.296848, 103.852536));
      expect(index.services['2']!.single.map((stop) => stop.code), ['01012', '01013']);
      expect(index.services['2']!.single.last.distanceKm, 0.6);
    });

    test('rejects an unknown schema version', () {
      expect(
        () => RouteDistanceIndex.fromJson({'schemaVersion': 2, 'stops': {}, 'services': {}}),
        throwsFormatException,
      );
    });
  });
}
