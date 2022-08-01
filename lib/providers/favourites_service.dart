import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:transito/models/favourite.dart';

class FavouritesService {
  final CollectionReference _usersCollection = FirebaseFirestore.instance.collection('favourites');

  Stream<List<Favourite>> streamFavourites(String userId) {
    return _usersCollection
        .doc(userId)
        .snapshots()
        .map((snapshot) => FavouritesList.fromFirestore(snapshot).favouritesList);
  }

  Future<void> addFavourite(Favourite favourite, String userId) {
    return _usersCollection
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

  // I have no idea if this works, have fun future me!
  Future<void> removeFavourite(String busStopCode, String userId) {
    return _usersCollection
        .doc(userId)
        .update({
          'favouritesList': FieldValue.arrayRemove([busStopCode])
        })
        .then(
          (_) => debugPrint('✔️ Removed ${busStopCode} from favourites'),
        )
        .catchError(
          (error) => debugPrint('❌ Error removing favourite from Firestore: $error'),
        );
  }
}
