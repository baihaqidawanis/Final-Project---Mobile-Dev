import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/notification_service.dart';
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
    _init();
  }

  Future<void> _init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedRole = prefs.getString('cached_user_role');
      final cachedName = prefs.getString('cached_user_name');
      if (cachedRole != null) {
        _userRole = _parseRole(cachedRole);
      }
      if (cachedName != null) {
        _userName = cachedName;
      }
    } catch (e) {
      debugPrint('Error loading cached role: $e');
    }
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(User? user) async {
    _currentUser = user;
    if (user != null) {
      await _fetchOrCreateUserRole(user);
      // Save FCM token so this user can receive push notifications
      await NotificationService().saveTokenToFirestore(user.uid);
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
      final prefs = await SharedPreferences.getInstance();
      if (doc.exists) {
        final roleStr = doc.data()?['role'];
        _userRole = _parseRole(roleStr);
        _userName = doc.data()?['name'] ?? user.email ?? '';
        await prefs.setString('cached_user_role', roleStr ?? 'user');
        await prefs.setString('cached_user_name', _userName);
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
        await prefs.setString('cached_user_role', 'admin');
        await prefs.setString('cached_user_name', 'Super Admin');
      } else {
        _userRole = UserRole.user;
        _userName = user.email ?? '';
        await prefs.setString('cached_user_role', 'user');
        await prefs.setString('cached_user_name', _userName);
      }
    } catch (e) {
      debugPrint('Error fetching role: $e');
      if (_userRole == null) {
        _userRole = UserRole.user;
        _userName = user.email ?? '';
      }
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
    // Remove FCM token so user stops receiving notifications after logout
    final uid = _currentUser?.uid ?? '';
    await NotificationService().deleteToken(uid);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('cached_user_role');
      await prefs.remove('cached_user_name');
    } catch (e) {
      debugPrint('Error clearing cache: $e');
    }
    await _auth.signOut();
  }
}
