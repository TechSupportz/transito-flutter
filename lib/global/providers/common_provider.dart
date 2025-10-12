import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
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

    if (Platform.isIOS && !_supportsLiquidGlass) {
      final deviceInfo = await DeviceInfoPlugin().iosInfo;
      int? majorSystemVersion = int.tryParse(deviceInfo.systemVersion.split(".")[0]);

      if (majorSystemVersion != null && majorSystemVersion >= 26) {
        _supportsLiquidGlass = true;
        notifyListeners();
      } else if (_supportsLiquidGlass == true) {
        _supportsLiquidGlass = false;
        notifyListeners();
      }

      return;
    }
  }
}
