import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthenticationService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<String?> registerUserWithEmail(String username, String email, String password) async {
    try {
      UserCredential result =
          await _auth.createUserWithEmailAndPassword(email: email, password: password);
      User? user = result.user;
      await user?.updateDisplayName(username);
    } on FirebaseAuthException catch (e) {
      debugPrint("Registration failed with code: ${e.code}");
      debugPrint("Registration failed with message: ${e.message}");
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
      debugPrint("Login failed with code: ${e.code}");
      debugPrint("Login failed with message: ${e.message}");
      return e.code;
    }
    return null;
  }

  Future<void> forgetPassword(email) {
    return _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> logout() {
    return _auth.signOut();
  }
}
