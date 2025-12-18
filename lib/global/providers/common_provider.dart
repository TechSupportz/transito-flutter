import 'dart:io';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:native_glass_navbar/liquid_glass_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CommonProvider extends ChangeNotifier {
  SharedPreferences? prefs;

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

  bool _isUserCenter = true;
  bool get isUserCenter => _isUserCenter;
  void setIsUserCenter(bool value) {
    if (_isUserCenter == value) return;
    _isUserCenter = value;
    notifyListeners();
  }

  bool _supportsLiquidGlass = false;
  bool get supportsLiquidGlass => _supportsLiquidGlass;
  void checkSupportsLiquidGlass() async {
    if (!Platform.isIOS) {
      _supportsLiquidGlass = false;
      return;
    }

    prefs ??= await SharedPreferences.getInstance();
    bool? localSupportsLiquidGlass = prefs?.getBool('supportsLiquidGlass');

    if (localSupportsLiquidGlass == true) {
      _supportsLiquidGlass = true;
      notifyListeners();
      return;
    }

    if (!_supportsLiquidGlass) {
      bool isSupported = await LiquidGlassHelper.isLiquidGlassSupported();

      if (isSupported) {
        _supportsLiquidGlass = true;
        prefs?.setBool('supportsLiquidGlass', true);
        notifyListeners();
      } else if (_supportsLiquidGlass == true && !isSupported) {
        _supportsLiquidGlass = false;
        prefs?.setBool('supportsLiquidGlass', false);
        notifyListeners();
      }

      return;
    }
  }
}
