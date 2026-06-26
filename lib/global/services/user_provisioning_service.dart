import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:transito/models/enums/app_theme_mode_enum.dart';
import 'package:transito/models/user/user_settings.dart';

class UserProvisioningService {
  UserProvisioningService._internal();

  static final UserProvisioningService _instance = UserProvisioningService._internal();

  factory UserProvisioningService() => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _favourites => _firestore.collection('favourites');
  CollectionReference get _settings => _firestore.collection('settings');

  static const Map<String, dynamic> defaultFavouritesData = {
    'favouritesList': [],
  };

  static const Map<String, dynamic> defaultSettingsData = {
    'accentColour': '0xFF7E6BFF',
    'isETAminutes': true,
    'isNearbyGrid': true,
    'showNearbyDistance': true,
    'themeMode': 'SYSTEM',
  };

  static UserSettings defaultUserSettings() {
    return UserSettings(
      accentColour: defaultSettingsData['accentColour'] as String,
      isETAminutes: defaultSettingsData['isETAminutes'] as bool,
      isNearbyGrid: defaultSettingsData['isNearbyGrid'] as bool,
      showNearbyDistance: defaultSettingsData['showNearbyDistance'] as bool,
      themeMode: AppThemeMode.SYSTEM,
    );
  }

  Future<void> ensureUserProvisioned({required String userId}) async {
    await Future.wait([
      ensureFavouritesDocumentExists(userId),
      ensureSettingsDocumentExists(userId),
    ]);
  }

  Future<void> ensureFavouritesDocumentExists(String userId) async {
    final DocumentReference userFavouritesDocument = _favourites.doc(userId);
    final bool wasCreated = await _createIfMissing(
      document: userFavouritesDocument,
      data: defaultFavouritesData,
    );

    if (wasCreated) {
      debugPrint('✔️ Created missing favourites document for user $userId');
    }
  }

  Future<void> ensureSettingsDocumentExists(String userId) async {
    final DocumentReference userSettingsDocument = _settings.doc(userId);
    final bool wasCreated = await _createIfMissing(
      document: userSettingsDocument,
      data: defaultSettingsData,
    );

    if (wasCreated) {
      debugPrint('✔️ Created missing settings document for user $userId');
    }
  }

  Future<bool> _createIfMissing({
    required DocumentReference document,
    required Map<String, dynamic> data,
  }) async {
    bool wasCreated = false;

    await _firestore.runTransaction((transaction) async {
      final DocumentSnapshot snapshot = await transaction.get(document);
      if (snapshot.exists) {
        wasCreated = false;
        return;
      }

      transaction.set(document, data);
      wasCreated = true;
    });

    return wasCreated;
  }
}
