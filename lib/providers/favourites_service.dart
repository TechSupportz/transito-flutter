import 'package:cloud_firestore/cloud_firestore.dart';

class FavouritesService {
  final CollectionReference _usersCollection = FirebaseFirestore.instance.collection('users');
}
