import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthenticationService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

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
      debugPrint('Signed in with google');
      debugPrint('$user');
    } on FirebaseAuthException catch (e) {
      debugPrint("🛑 Google Login failed with code: ${e.code}");
      debugPrint("🛑 Google Login failed with message: ${e.message}");
      return e.code;
    }
  }

  Future<String?> registerUserWithEmail(String name, String email, String password) async {
    try {
      UserCredential result =
          await _auth.createUserWithEmailAndPassword(email: email, password: password);
      User? user = result.user;
      await user?.updateDisplayName(name);
      await user?.sendEmailVerification();
      // user?.reload();
    } on FirebaseAuthException catch (e) {
      debugPrint("🛑 Registration failed with code: ${e.code}");
      debugPrint("🛑 Registration failed with message: ${e.message}");
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
      debugPrint("🛑 Login failed with code: ${e.code}");
      debugPrint("🛑 Login failed with message: ${e.message}");
      return e.code;
    }
    return null;
  }

  Future<String?> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      debugPrint("🛑 Forget password failed with code: ${e.code}");
      debugPrint("🛑 Forget password failed with message: ${e.message}");
      return e.code;
    }
    return null;
  }

  Future<void> logout() async {
    // debugPrint("Logout");
    await _auth.signOut();
  }
}
