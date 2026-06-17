import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/firestore_service.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<bool> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

       
      await credential.user!.updateDisplayName(displayName.trim());

       
      final user = UserModel(
        uid: credential.user!.uid,
        email: email.trim(),
        displayName: displayName.trim(),
        role: 'student',  
        joinedClassIds: [],
        createdAt: DateTime.now(),
      );

      await _firestoreService.createUser(user);

      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapErrorCode(e.code);
      _setLoading(false);
      return false;
    }
  }

  Future<bool> login({required String email, required String password}) async {
    _setLoading(true);
    _clearError();

    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapErrorCode(e.code);
      _setLoading(false);
      return false;
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();  
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  String _mapErrorCode(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}
