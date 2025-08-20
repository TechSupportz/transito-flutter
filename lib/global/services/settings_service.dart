import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:transito/models/app/app_colors.dart';
import 'package:transito/models/enums/app_theme_mode_enum.dart';
import 'package:transito/models/user/user_settings.dart';

class SettingsService {
  final CollectionReference _settingsCollection = FirebaseFirestore.instance.collection('settings');

  Stream<UserSettings> streamSettings(String? userId) {
    if (userId != null) {
      return _settingsCollection.doc(userId).snapshots().map((snapshot) {
        if (snapshot.exists) {
          UserSettings userSettings = UserSettings.fromFirestore(snapshot);
          AppColors().updateLocalAccentColour(Color(int.parse(userSettings.accentColour)));

          return userSettings;
        } else {
          return UserSettings(
            accentColour: '0xFF7E6BFF',
            isETAminutes: true,
            isNearbyGrid: true,
            showNearbyDistance: true,
            themeMode: AppThemeMode.SYSTEM,
          );
        }
      });
    } else {
      return Stream.value(
        UserSettings(
          accentColour: '0xFF7E6BFF',
          isETAminutes: true,
          isNearbyGrid: true,
          showNearbyDistance: true,
          themeMode: AppThemeMode.SYSTEM,
        ),
      );
    }
  }

  Future<void> updateThemeMode({
    String? userId,
    required AppThemeMode newValue,
    required BuildContext context,
  }) async {
    if (userId != null) {
      _settingsCollection.doc(userId).update({
        'themeMode': newValue.name,
      }).then(
        (_) {
          AppColors().updateLocalBrightness(
            newValue == AppThemeMode.DARK
                ? Brightness.dark
                : newValue == AppThemeMode.LIGHT
                    ? Brightness.light
                    : context.mounted
                        ? MediaQuery.platformBrightnessOf(context)
                        : Brightness.dark,
          );
          debugPrint('✔️ Updated themeMode to $newValue');
        },
      ).catchError(
        (error) {
          debugPrint('❌ Error updating themeMode in Firestore: $error');
        },
      );
    }
  }

  Future<void> updateAccentColour({String? userId, required String newValue}) async {
    if (userId != null) {
      _settingsCollection.doc(userId).update({
        'accentColour': newValue,
      }).then(
        (_) {
          AppColors().updateLocalAccentColour(Color(int.parse(newValue)));
          debugPrint('✔️ Updated accentColour to $newValue');
        },
      ).catchError(
        (error) {
          debugPrint('❌ Error updating accentColour in Firestore: $error');
        },
      );
    }
  }

  Future<void> updateIsETAminutes({String? userId, required bool newValue}) async {
    if (userId != null) {
      _settingsCollection
          .doc(userId)
          .update({
            'isETAminutes': newValue,
          })
          .then(
            (_) => debugPrint('✔️ Updated isETAminutes to $newValue'),
          )
          .catchError(
            (error) => debugPrint('❌ Error updating isETAminutes in Firestore: $error'),
          );
    }
  }

  Future<void> updateIsNearbyGrid({String? userId, required bool newValue}) async {
    if (userId != null) {
      _settingsCollection
          .doc(userId)
          .update({
            'isNearbyGrid': newValue,
          })
          .then(
            (_) => debugPrint('✔️ Updated isNearbyGrid to $newValue'),
          )
          .catchError(
            (error) => debugPrint('❌ Error updating isNearbyGrid in Firestore: $error'),
          );
    }
  }

  Future<void> updateShowNearbyDistance({String? userId, required bool newValue}) async {
    if (userId != null) {
      _settingsCollection
          .doc(userId)
          .update({
            'showNearbyDistance': newValue,
          })
          .then(
            (_) => debugPrint('✔️ Updated showNearbyDistance to $newValue'),
          )
          .catchError(
            (error) => debugPrint('❌ Error updating showNearbyDistance in Firestore: $error'),
          );
    }
  }
}
