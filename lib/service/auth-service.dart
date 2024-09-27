import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String> reqistration({
    required String email,
    required String password,
    required String confirm,
  }) async {
    try {
      await _auth.createUserWithEmailAndPassword(email: email, password: password);
      return 'success';
    } catch (e) {
      return e.toString(); // Return error message
    }
  }

  Future<String> signin({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return 'success';
    } catch (e) {
      return e.toString(); // Return error message
    }
  }
}