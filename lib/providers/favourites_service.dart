import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:transito/models/favourite.dart';

class FavouritesService {
  final CollectionReference _favouritesCollection =
      FirebaseFirestore.instance.collection('favourites');

  Stream<List<Favourite>> streamFavourites(String userId) {
    return _favouritesCollection
        .doc(userId)
        .snapshots()
        .map((snapshot) => FavouritesList.fromFirestore(snapshot).favouritesList);
  }

  Future<List<Favourite>> getFavourites(String userId) async {
    return _favouritesCollection.doc(userId).get().then((snapshot) {
      if (snapshot.exists) {
        return FavouritesList.fromFirestore(snapshot).favouritesList;
      } else {
        return [];
      }
    });
  }

  Future<Map<String?, List<String?>>> getFavouriteServicesByBusStopCode(
      String userId, String busStopCode) async {
    var _favouritesList =
        FavouritesList.fromFirestore(await _favouritesCollection.doc(userId).get()).favouritesList;

    List<String?> favouriteServices =
        _favouritesList.firstWhere((element) => element.busStopCode == busStopCode).services;

    Map<String?, List<String?>> initialSelectedChildren = {
      'Bus Services':
          _favouritesList.firstWhere((element) => element.busStopCode == busStopCode).services,
    };

    return initialSelectedChildren;
  }

  Future<void> addFavourite(Favourite favourite, String userId) {
    return _favouritesCollection
        .doc(userId)
        .update({
          'favouritesList': FieldValue.arrayUnion([favourite.toJson()])
        })
        .then(
          (_) => debugPrint('✔️ Added ${favourite.busStopCode} to favourites'),
        )
        .catchError(
          (error) => debugPrint('❌ Error adding favourite to Firestore: $error'),
        );
  }

  Future<void> removeFavourite(Favourite favourite, String userId) {
    return _favouritesCollection
        .doc(userId)
        .update({
          'favouritesList': FieldValue.arrayRemove([favourite.toJson()])
        })
        .then(
          (_) => debugPrint('✔️ Removed ${favourite.busStopCode} from favourites'),
        )
        .catchError(
          (error) => debugPrint('❌ Error removing favourite from Firestore: $error'),
        );
  }

  Future<void> reorderFavourites(List<Favourite> favourites, String userId) async {
    if (favourites.isNotEmpty) {
      _favouritesCollection
          .doc(userId)
          .update({'favouritesList': favourites.map((favourite) => favourite.toJson()).toList()})
          .then(
            (_) => debugPrint(
                '✔️ Reordered favourites list to ${favourites.map((favourite) => favourite.busStopCode).toList()}'),
          )
          .catchError(
            (error) => debugPrint('❌ Error reordering favourite from Firestore: $error'),
          );
    } else {
      debugPrint('✔️ No changes were made to favourites order');
    }
  }

  Future<void> updateFavourite(Favourite favourite, String userId) async {
    _favouritesCollection.doc(userId).get().then(
      (snapshot) {
        if (snapshot.exists) {
          List<Favourite> _favouritesList = FavouritesList.fromFirestore(snapshot).favouritesList;
          _favouritesList[_favouritesList
              .indexWhere((element) => element.busStopCode == favourite.busStopCode)] = favourite;

          _favouritesCollection
              .doc(userId)
              .update(
                  {'favouritesList': _favouritesList.map((element) => element.toJson()).toList()})
              .then(
                (_) => debugPrint('✔️ Updated ${favourite.busStopCode}\'s favourites'),
              )
              .catchError(
                (error) => debugPrint('❌ Error updating favourite in Firestore: $error'),
              );
          ;
        }
      },
    );
  }

  Future<bool> isAddedToFavourites(String busStopCode, String userId) async {
    final favouritesList = await _favouritesCollection
        .doc(userId)
        .get()
        .then((snapshot) => FavouritesList.fromFirestore(snapshot).favouritesList);

    return favouritesList.any((favourite) => favourite.busStopCode == busStopCode);
  }
}
