import 'package:cloud_firestore/cloud_firestore.dart';

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
}
