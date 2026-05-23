import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';

enum UserRole { family, caregiver, hospital, pharmacy }

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _currentUser;
  UserRole? _userRole;
  bool _isLoading = true;

  User? get currentUser => _currentUser;
  UserRole? get userRole => _userRole;
  bool get isLoading => _isLoading;

  AuthProvider() {
    // Listen to auth state changes on startup
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(User? user) async {
    _currentUser = user;
    if (user != null) {
      await _fetchUserRole(user.uid);
    } else {
      _userRole = null;
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _fetchUserRole(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        final roleStr = doc.data()?['role'] as String?;
        _userRole = _parseRole(roleStr);
      }
    } catch (e) {
      debugPrint('Error fetching user role: $e');
    }
  }

  UserRole _parseRole(String? role) {
    switch (role) {
      case 'caregiver':
        return UserRole.caregiver;
      case 'hospital':
        return UserRole.hospital;
      case 'pharmacy':
        return UserRole.pharmacy;
      default:
        return UserRole.family;
    }
  }

  /// Register a new user and write their role to Firestore
  Future<String?> register({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = credential.user!.uid;

      // Write user document to Firestore
      await _firestore.collection('users').doc(uid).set(UserModel(
        uid: uid,
        name: name,
        email: email,
        role: role,
        createdAt: DateTime.now(),
      ).toMap());

      return null; // null = success
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Registration failed';
    }
  }

  /// Login with email & password
  Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null; // null = success
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Login failed';
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}
