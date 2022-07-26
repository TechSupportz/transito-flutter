import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthenticationService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CollectionReference _users = FirebaseFirestore.instance.collection('users');

  Future<void> addNewUser({required String userId}) {
    return _users
        .doc(userId)
        .set({
          'id': userId,
          'favourites': [],
        })
        .then(
          (_) => debugPrint('✔️ Added new user to Firestore'),
        )
        .catchError(
          (error) => debugPrint('❌ Error adding new user to Firestore: $error'),
        );
  }

  Future<String?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
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
      debugPrint("❌ Forget password failed with code: ${e.code}");
      debugPrint("❌ Forget password failed with message: ${e.message}");
      return e.code;
    }
    return null;
  }

  Future<void> logout() async {
    // debugPrint("Logout");
    await _auth.signOut();
  }
}
