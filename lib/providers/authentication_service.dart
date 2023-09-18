import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AuthenticationService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
      clientId: Platform.isIOS
          ? "341566460699-4pfme9l8rr9iqcq5im3bdqcn2iudbqjo.apps.googleusercontent.com"
          : null);
  final CollectionReference _favourites = FirebaseFirestore.instance.collection('favourites');
  final CollectionReference _settings = FirebaseFirestore.instance.collection('settings');

  List<String> get _userProviders =>
      _auth.currentUser?.providerData.map((e) => e.providerId).toList() ?? [];

// Used by all login methods to initialise user in Firestore on first login
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

// Google login
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

  // Apple login
  Future<String?> signInWithApple() async {
    try {
      final appleAuth = await SignInWithApple.getAppleIDCredential(scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ]);

      final credential = OAuthProvider('apple.com').credential(
        idToken: appleAuth.identityToken,
        accessToken: appleAuth.authorizationCode,
      );

      UserCredential result = await _auth.signInWithCredential(credential);
      User? user = result.user;
      await user?.updateDisplayName(appleAuth.givenName);
      await user?.updateEmail(appleAuth.email ?? '');
      if (result.additionalUserInfo?.isNewUser ?? false) {
        await addNewUser(userId: user!.uid).then(
          (_) => debugPrint('✔️ Initialised user in Firestore'),
        );
      }
      debugPrint('✔️ Signed in with apple');
      debugPrint('✔️ $user');
    } on FirebaseAuthException catch (e) {
      debugPrint("❌ Apple Login failed with code: ${e.code}");
      debugPrint("❌ Apple Login failed with message: ${e.message}");
      return e.code;
    }
    return null;
  }

// Guest login
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

// Email login and registration
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

  // Logout
  Future<void> logout() async {
    await _auth.signOut();

    if (_userProviders.contains('google.com')) {
      await _googleSignIn.signOut();
    }
  }

  // Delete account
  Future<void> deleteAccount() async {
    String userID = _auth.currentUser!.uid;

    await _favourites.doc(userID).delete();
    await _settings.doc(userID).delete();

    if (_userProviders.contains('google.com')) {
      await _googleSignIn.disconnect();
    }

    await _auth.currentUser!.delete();
  }
}
