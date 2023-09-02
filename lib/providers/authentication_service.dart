import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthenticationService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
      clientId: "341566460699-4pfme9l8rr9iqcq5im3bdqcn2iudbqjo.apps.googleusercontent.com");
  final CollectionReference _favourites = FirebaseFirestore.instance.collection('favourites');
  final CollectionReference _settings = FirebaseFirestore.instance.collection('settings');

  Future<void> addNewUser({required String userId}) async {
    _favourites
        .doc(userId)
        .set({
          'favouritesList': [],
        })
        .then(
          (_) => debugPrint('✔️ Created favourites for new user'),
        )
        .catchError(
          (error) => debugPrint('❌ Error creating favourites document in Firestore: $error'),
        );

    _settings
        .doc(userId)
        .set({
          'accentColour': '0xFF7E6BFF',
          'isETAminutes': true,
          'isNearbyGrid': true,
        })
        .then(
          (_) => debugPrint('✔️ Created settings for new user'),
        )
        .catchError(
          (error) => debugPrint('❌ Error creating settings document in Firestore: $error'),
        );
  }

  Future<String?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      final GoogleSignInAuthentication? googleAuth = await googleUser?.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth?.accessToken,
        idToken: googleAuth?.idToken,
      );
      UserCredential result = await _auth.signInWithCredential(credential);
      User? user = result.user;
      if (result.additionalUserInfo?.isNewUser ?? false) {
        await addNewUser(userId: user!.uid).then(
          (_) => debugPrint('✔️ Initialised user in Firestore'),
        );
      }
      debugPrint('✔️ Signed in with google');
      debugPrint('✔️ $user');
    } on FirebaseAuthException catch (e) {
      debugPrint("❌ Google Login failed with code: ${e.code}");
      debugPrint("❌ Google Login failed with message: ${e.message}");
      return e.code;
    }
    return null;
  }

  Future<String?> signInAnonymously() async {
    try {
      UserCredential result = await _auth.signInAnonymously();
      User? user = result.user;
      await user?.updateDisplayName("Guest");
      if (result.additionalUserInfo?.isNewUser ?? false) {
        await addNewUser(userId: user!.uid).then(
          (_) => debugPrint('✔️ Initialised user in Firestore'),
        );
      }
      debugPrint("✔️ Signed in anonymously");
    } on FirebaseAuthException catch (e) {
      debugPrint("❌ Anonymous Login failed with code: ${e.code}");
      debugPrint("❌ Anonymous Login failed with message: ${e.message}");
      return e.code;
    }
    return null;
  }

  Future<String?> registerUserWithEmail(String name, String email, String password) async {
    try {
      UserCredential result =
          await _auth.createUserWithEmailAndPassword(email: email, password: password);
      User? user = result.user;
      await user?.updateDisplayName(name);
      await user?.sendEmailVerification();
      await addNewUser(userId: user!.uid);
      // user?.reload();
    } on FirebaseAuthException catch (e) {
      debugPrint("❌ Registration failed with code: ${e.code}");
      debugPrint("❌ Registration failed with message: ${e.message}");
      return e.code;
    }
    return null;
  }

  Future<String?> loginUserWithEmail(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      debugPrint("❌ Login failed with code: ${e.code}");
      debugPrint("❌ Login failed with message: ${e.message}");
      return e.code;
    }
    return null;
  }

  Future<String?> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      debugPrint("❌ Reset password failed with code: ${e.code}");
      debugPrint("❌ Reset password failed with message: ${e.message}");
      return e.code;
    }
    return null;
  }

  Future<void> logout() async {
    if (_auth.currentUser!.providerData.map((e) => e.providerId).contains('password')) {
      await _auth.signOut();
    } else {
      await _auth.signOut();
      await _googleSignIn.signOut();
    }
  }

  Future<void> deleteAccount() async {
    String userID = _auth.currentUser!.uid;

    await _favourites.doc(userID).delete();
    await _settings.doc(userID).delete();
    await _auth.currentUser!.delete();
  }
}
