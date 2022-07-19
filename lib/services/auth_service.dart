import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final auth = FirebaseAuth.instance;

  Future<User?> registerUserWithEmail(String username, String email, String password) async {
    try {
      UserCredential result =
          await auth.createUserWithEmailAndPassword(email: email, password: password);
      User? user = result.user;
      await user?.updateDisplayName(username);
      return user;
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  Future<UserCredential> login(String email, String password) {
    return auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> forgetPassword(email) {
    return auth.sendPasswordResetEmail(email: email);
  }

  Stream<User?> get user {
    return auth.authStateChanges();
  }

  Future<void> logout() {
    return auth.signOut();
  }
}
