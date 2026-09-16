import 'dart:async';

import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:transito/global/services/location_service.dart';

class _LocationPlatform extends GeolocatorPlatform {
  final updates = StreamController<Position>.broadcast();
  final position = Position(
    longitude: 103.8,
    latitude: 1.3,
    timestamp: DateTime.now(),
    accuracy: 5,
    altitude: 0,
    altitudeAccuracy: 0,
    heading: 0,
    headingAccuracy: 0,
    speed: 0,
    speedAccuracy: 0,
  );

  @override
  Future<LocationPermission> checkPermission() async => LocationPermission.whileInUse;

  @override
  Future<bool> isLocationServiceEnabled() async => true;

  @override
  Future<Position> getCurrentPosition({LocationSettings? locationSettings}) async => position;

  @override
  Stream<Position> getPositionStream({LocationSettings? locationSettings}) => updates.stream;
}

void main() {
  test(
    'map marker receives the camera fix when it subscribes after camera initialization',
    () async {
      final original = GeolocatorPlatform.instance;
      final platform = _LocationPlatform();
      GeolocatorPlatform.instance = platform;
      final service = LocationService();
      final cameraSubscription = service.positionStream.listen((_) {});
      StreamSubscription<LocationMarkerPosition?>? markerSubscription;
      addTearDown(() async {
        await markerSubscription?.cancel();
        await cameraSubscription.cancel();
        await platform.updates.close();
        GeolocatorPlatform.instance = original;
      });

      final cameraPosition = await service.getCurrentPosition();
      await Future<void>.delayed(Duration.zero);
      final markers = <LocationMarkerPosition?>[];
      markerSubscription = const LocationMarkerDataStreamFactory()
          .fromGeolocatorPositionStream(stream: service.positionStream)
          .listen(markers.add);
      await Future<void>.delayed(Duration.zero);

      expect(markers, isNotEmpty, reason: 'A stationary user must not need another GPS event.');
      expect(markers.last?.latitude, cameraPosition!.latitude);
      expect(markers.last?.longitude, cameraPosition.longitude);
    },
  );
}
