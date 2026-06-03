import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';

enum UserRole { admin, user, caregiver, hospital, pharmacy }

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? _currentUser;
  UserRole? _userRole;
  String _userName = '';
  bool _isLoading = true;

  User? get currentUser => _currentUser;
  UserRole? get userRole => _userRole;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;

  /// Display name fetched from Firestore /users/{uid}.name
  String get userName => _userName;

  AuthProvider() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(User? user) async {
    _currentUser = user;
    if (user != null) {
      await _fetchOrCreateUserRole(user);
    } else {
      _userRole = null;
      _userName = '';
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _fetchOrCreateUserRole(User user) async {
    try {
      final doc = await _db.collection('users').doc(user.uid).get();
      if (doc.exists) {
        _userRole = _parseRole(doc.data()?['role']);
        _userName = doc.data()?['name'] ?? user.email ?? '';
      } else if (user.email == 'admin@mail.com') {
        // Auto-assign admin role on first login
        await _db.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'name': 'Super Admin',
          'email': user.email,
          'role': 'admin',
          'createdAt': FieldValue.serverTimestamp(),
        });
        _userRole = UserRole.admin;
        _userName = 'Super Admin';
      } else {
        _userRole = UserRole.user;
        _userName = user.email ?? '';
      }
    } catch (e) {
      debugPrint('Error fetching role: $e');
      _userRole = UserRole.user;
      _userName = user.email ?? '';
    }
  }

  UserRole _parseRole(String? role) {
    switch (role) {
      case 'admin':     return UserRole.admin;
      case 'caregiver': return UserRole.caregiver;
      case 'hospital':  return UserRole.hospital;
      case 'pharmacy':  return UserRole.pharmacy;
      default:          return UserRole.user;
    }
  }

  /// Register regular user
  Future<String?> registerUser({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      await _db.collection('users').doc(cred.user!.uid).set(UserModel(
        uid: cred.user!.uid,
        name: name,
        email: email,
        role: 'user',
        createdAt: DateTime.now(),
      ).toMap());
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Registration failed';
    }
  }

  /// Register mitra (caregiver / hospital / pharmacy)
  Future<String?> registerMitra({
    required String name,
    required String email,
    required String password,
    required String role,
    Map<String, dynamic>? mitraProfile,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      final uid = cred.user!.uid;

      // Write user doc
      await _db.collection('users').doc(uid).set(UserModel(
        uid: uid,
        name: name,
        email: email,
        role: role,
        createdAt: DateTime.now(),
      ).toMap());

      // Write caregiver profile doc if role is caregiver
      if (role == 'caregiver' && mitraProfile != null) {
        await _db.collection('caregivers').doc(uid).set({
          'name': name,
          'photoUrl': '',
          'isAvailable': true,
          'rating': 0.0,
          'totalReviews': 0,
          ...mitraProfile,
        });
      }

      // Write pharmacy profile doc if role is pharmacy
      if (role == 'pharmacy') {
        await _db.collection('pharmacies').doc(uid).set({
          'name': name,
          'address': '',
          'area': '',
          'phone': '',
          'openHours': '08:00 - 21:00',
          'photoUrl': '',
          'isOpen': true,
          'rating': 0.0,
          'totalReviews': 0,
        });
      }
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Registration failed';
    }
  }

  Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Login failed';
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}
