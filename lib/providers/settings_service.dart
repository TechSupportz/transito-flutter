import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/user_settings.dart';

class SettingsService {
  final CollectionReference _settingsCollection = FirebaseFirestore.instance.collection('settings');

  Stream<UserSettings> streamSettings(String? userId) {
    if (userId != null) {
      return _settingsCollection.doc(userId).snapshots().map((snapshot) {
        if (snapshot.exists) {
          return UserSettings.fromFirestore(snapshot);
        } else {
          return UserSettings(
            accentColour: '0xFF7E6BFF',
            isETAminutes: true,
            isNearbyGrid: true,
          );
        }
      });
    } else {
      return Stream.value(
        UserSettings(
          accentColour: '0xFF7E6BFF',
          isETAminutes: true,
          isNearbyGrid: true,
        ),
      );
    }
  }

  Future<void> updateAccentColour({String? userId, required String newValue}) async {
    if (userId != null) {
      _settingsCollection
          .doc(userId)
          .update({
            'accentColour': newValue,
          })
          .then(
            (_) => debugPrint('✔️ Updated accentColour to $newValue'),
          )
          .catchError(
            (error) => debugPrint('❌ Error updating accentColour in Firestore: $error'),
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
}
