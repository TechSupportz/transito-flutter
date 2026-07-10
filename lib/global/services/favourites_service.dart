import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:transito/global/services/user_provisioning_service.dart';
import 'package:transito/models/favourites/favourite.dart';

class FavouritesService {
  final CollectionReference _favouritesCollection = FirebaseFirestore.instance.collection(
    'favourites',
  );
  final UserProvisioningService _userProvisioningService = UserProvisioningService();

  Stream<List<Favourite>> streamFavourites(String? userId) {
    if (userId != null) {
      return _favouritesCollection.doc(userId).snapshots().asyncMap((snapshot) async {
        if (snapshot.exists) {
          return FavouritesList.fromFirestore(snapshot).favouritesList;
        } else {
          await _userProvisioningService.ensureFavouritesDocumentExists(userId);
          return [];
        }
      });
    } else {
      return Stream.value([]);
    }
  }

  Future<List<Favourite>> getFavourites(String userId) async {
    await _userProvisioningService.ensureFavouritesDocumentExists(userId);
    return _favouritesCollection.doc(userId).get().then((snapshot) {
      if (snapshot.exists) {
        return FavouritesList.fromFirestore(snapshot).favouritesList;
      } else {
        return [];
      }
    });
  }

  Future<Map<String?, List<String?>>> getFavouriteServicesByBusStopCode(
    String userId,
    String busStopCode,
  ) async {
    final Favourite? favourite = await getFavouriteByBusStopCode(userId, busStopCode);
    if (favourite == null) {
      throw StateError('$busStopCode was not found in favourites');
    }

    Map<String?, List<String?>> initialSelectedChildren = {
      'Bus Services': favourite.services,
    };

    return initialSelectedChildren;
  }

  Future<void> addFavourite(Favourite favourite, String userId) async {
    await _userProvisioningService.ensureFavouritesDocumentExists(userId);
    final List<Favourite> favourites = await getFavourites(userId);
    if (favourites.any((element) => element.busStopCode == favourite.busStopCode)) {
      debugPrint('✔️ ${favourite.busStopCode} is already in favourites');
      return;
    }

    await _favouritesCollection
        .doc(userId)
        .update({
          'favouritesList': FieldValue.arrayUnion([favourite.toJson()]),
        })
        .then(
          (_) => debugPrint('✔️ Added ${favourite.busStopCode} to favourites'),
        )
        .catchError(
          (error) => debugPrint('❌ Error adding favourite to Firestore: $error'),
        );
  }

  Future<void> removeFavourite(Favourite favourite, String userId) {
    return removeFavouriteByBusStopCode(favourite.busStopCode, userId);
  }

  Future<void> removeFavouriteByBusStopCode(String busStopCode, String userId) async {
    await _userProvisioningService.ensureFavouritesDocumentExists(userId);
    final DocumentSnapshot snapshot = await _favouritesCollection.doc(userId).get();
    if (!snapshot.exists) return;

    final List<Favourite> favouritesList = FavouritesList.fromFirestore(snapshot).favouritesList;
    favouritesList.removeWhere((element) => element.busStopCode == busStopCode);

    await _favouritesCollection
        .doc(userId)
        .update({
          'favouritesList': favouritesList.map((element) => element.toJson()).toList(),
        })
        .then(
          (_) => debugPrint('✔️ Removed $busStopCode from favourites'),
        )
        .catchError(
          (error) => debugPrint('❌ Error removing favourite from Firestore: $error'),
        );
  }

  Future<void> reorderFavourites(List<Favourite> favourites, String userId) async {
    await _userProvisioningService.ensureFavouritesDocumentExists(userId);
    if (favourites.isNotEmpty) {
      await _favouritesCollection
          .doc(userId)
          .update({'favouritesList': favourites.map((favourite) => favourite.toJson()).toList()})
          .then(
            (_) => debugPrint(
              '✔️ Reordered favourites list to ${favourites.map((favourite) => favourite.busStopCode).toList()}',
            ),
          )
          .catchError(
            (error) => debugPrint('❌ Error reordering favourite from Firestore: $error'),
          );
    } else {
      debugPrint('✔️ No changes were made to favourites order');
    }
  }

  Future<void> updateFavourite(Favourite favourite, String userId) async {
    await _userProvisioningService.ensureFavouritesDocumentExists(userId);
    final DocumentSnapshot snapshot = await _favouritesCollection.doc(userId).get();
    if (!snapshot.exists) return;

    final List<Favourite> favouritesList = FavouritesList.fromFirestore(snapshot).favouritesList;
    final int favouriteIndex = favouritesList.indexWhere(
      (element) => element.busStopCode == favourite.busStopCode,
    );

    if (favouriteIndex == -1) {
      debugPrint('❌ ${favourite.busStopCode} was not found in favourites');
      return;
    }

    favouritesList[favouriteIndex] = favourite;

    await _favouritesCollection
        .doc(userId)
        .update({
          'favouritesList': favouritesList.map((element) => element.toJson()).toList(),
        })
        .then(
          (_) => debugPrint('✔️ Updated ${favourite.busStopCode}\'s favourites'),
        )
        .catchError(
          (error) => debugPrint('❌ Error updating favourite in Firestore: $error'),
        );
  }

  Future<Favourite?> getFavouriteByBusStopCode(String userId, String busStopCode) async {
    final List<Favourite> favouritesList = await getFavourites(userId);
    for (final Favourite favourite in favouritesList) {
      if (favourite.busStopCode == busStopCode) return favourite;
    }

    return null;
  }

  Future<bool> isAddedToFavourites(String busStopCode, String userId) async {
    return await getFavouriteByBusStopCode(userId, busStopCode) != null;
  }
}
