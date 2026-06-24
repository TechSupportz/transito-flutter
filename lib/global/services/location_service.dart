import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  LocationService._internal();
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;

  Future<Position?>? _activePositionRequest;
  StreamController<Position?>? _positionController;
  StreamSubscription<Position>? _positionSubscription;
  final ValueNotifier<bool> _automaticRequestsSuppressed = ValueNotifier<bool>(false);

  ValueListenable<bool> get automaticRequestsSuppressed => _automaticRequestsSuppressed;

  Future<LocationPermission> checkPermission() {
    return Geolocator.checkPermission();
  }

  Future<LocationPermission> requestPermission() async {
    final permission = await Geolocator.requestPermission();
    _setAutomaticRequestsSuppressed(!_isPermissionGranted(permission));
    return permission;
  }

  Future<bool> hasLocationPermission() async {
    return _isPermissionGranted(await checkPermission());
  }

  Future<bool> openAppSettings() {
    return Geolocator.openAppSettings();
  }

  Stream<Position?> get positionStream {
    _positionController ??= StreamController<Position?>.broadcast(
      onListen: _startPositionStream,
      onCancel: _stopPositionStream,
    );

    return _positionController!.stream;
  }

  Future<bool> canUseLocation({bool userInitiated = false}) async {
    if (_automaticRequestsSuppressed.value && !userInitiated) {
      return false;
    }

    final permission = await checkPermission();
    if (!_isPermissionGranted(permission)) {
      _suppressAutomaticRequests();
      return false;
    }

    final isLocationServiceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!isLocationServiceEnabled) {
      _suppressAutomaticRequests();
      return false;
    }

    if (userInitiated) {
      _setAutomaticRequestsSuppressed(false);
    }

    return true;
  }

  Future<Position?> getCurrentPosition({bool userInitiated = false}) {
    if (_activePositionRequest != null) {
      return _activePositionRequest!;
    }

    final request = _getCurrentPosition(userInitiated: userInitiated);
    _activePositionRequest = request;

    request.whenComplete(() {
      if (_activePositionRequest == request) {
        _activePositionRequest = null;
      }
    });

    return request;
  }

  Future<Position?> _getCurrentPosition({required bool userInitiated}) async {
    final canUseLocation = await this.canUseLocation(userInitiated: userInitiated);
    if (!canUseLocation) {
      return null;
    }

    final shouldRestartPositionStream =
        Platform.isIOS &&
        _positionSubscription != null &&
        (_positionController?.hasListener ?? false);
    if (shouldRestartPositionStream) {
      await _stopPositionStream();
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
        ),
      );
      _positionController?.add(position);
      return position;
    } on LocationServiceDisabledException catch (error) {
      _suppressAutomaticRequests();
      debugPrint('Location service disabled: $error');
      return null;
    } on PermissionDeniedException catch (error) {
      _suppressAutomaticRequests();
      debugPrint('Location permission denied: $error');
      return null;
    } on TimeoutException catch (error) {
      _suppressAutomaticRequests();
      debugPrint('Location request timed out: $error');
      return null;
    } catch (error) {
      _suppressAutomaticRequests();
      debugPrint('Location request failed: $error');
      return null;
    } finally {
      if (shouldRestartPositionStream && !_automaticRequestsSuppressed.value) {
        unawaited(_startPositionStream());
      }
    }
  }

  Future<void> _startPositionStream() async {
    if (_positionSubscription != null) {
      return;
    }

    final canUseLocation = await this.canUseLocation();
    if (!canUseLocation) {
      _positionController?.add(null);
      return;
    }

    _positionSubscription =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.best,
            distanceFilter: 50,
          ),
        ).listen(
          (position) => _positionController?.add(position),
          onError: (Object error) {
            _suppressAutomaticRequests();
            debugPrint('Location stream failed: $error');
            _positionController?.add(null);
          },
        );
  }

  Future<void> _stopPositionStream() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  void _suppressAutomaticRequests() {
    _setAutomaticRequestsSuppressed(true);
    unawaited(_stopPositionStream());
  }

  void _setAutomaticRequestsSuppressed(bool value) {
    if (_automaticRequestsSuppressed.value == value) {
      return;
    }

    _automaticRequestsSuppressed.value = value;
  }

  bool _isPermissionGranted(LocationPermission permission) {
    return permission == LocationPermission.always || permission == LocationPermission.whileInUse;
  }
}
