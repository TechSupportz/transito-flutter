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

  bool _isUserCenter = false;
  bool get isUserCenter => _isUserCenter;
  void setIsUserCenter(bool value) {
    if (_isUserCenter == value) return;
    _isUserCenter = value;
    notifyListeners();
  }
}
