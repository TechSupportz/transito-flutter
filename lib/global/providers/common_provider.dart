import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class CommonProvider extends ChangeNotifier {
  final bool isTablet =
      MediaQueryData.fromView(WidgetsBinding.instance.platformDispatcher.views.single)
              .size
              .shortestSide >
          600;

  LatLng? _initialMapPinLocation;

  LatLng? get initialMapPinLocation => _initialMapPinLocation;

  void setInitialMapPinLocation(LatLng? location) {
    _initialMapPinLocation = location;
    notifyListeners();
  }
}
