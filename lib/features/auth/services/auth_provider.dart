import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/notification_service.dart';

enum UserRole { admin, user, caregiver, hospital, pharmacy }

class AuthProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  User? _currentUser;
  UserRole? _userRole;
  String _userName = '';
  bool _isLoading = true;

  User? get currentUser => _currentUser;
  UserRole? get userRole => _userRole;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;

  /// Display name fetched from public.profiles.name
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
    _supabase.auth.onAuthStateChange.listen((data) {
      _onAuthStateChanged(data.session?.user);
    });
  }

  Future<void> _onAuthStateChanged(User? user) async {
    _currentUser = user;
    if (user != null) {
      await _fetchOrCreateUserRole(user);
      // Save FCM token so this user can receive push notifications
      await NotificationService().saveTokenToFirestore(user.id);
    } else {
      _userRole = null;
      _userName = '';
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _fetchOrCreateUserRole(User user) async {
    try {
      final data = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      final prefs = await SharedPreferences.getInstance();
      if (data != null) {
        final roleStr = data['role'] as String?;
        _userRole = _parseRole(roleStr);
        _userName = data['name'] as String? ?? user.email ?? '';
        await prefs.setString('cached_user_role', roleStr ?? 'user');
        await prefs.setString('cached_user_name', _userName);
      } else if (user.email == 'admin@mail.com') {
        // Auto-assign admin role on first login
        final adminData = {
          'id': user.id,
          'name': 'Super Admin',
          'email': user.email ?? 'admin@mail.com',
          'role': 'admin',
        };
        await _supabase.from('profiles').upsert(adminData);
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
      await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'name': name,
          'role': 'user',
        },
      );
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
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
      final res = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'name': name,
          'role': role,
        },
      );
      final uid = res.user?.id;
      if (uid == null) {
        return 'Registration failed: User ID not generated';
      }

      // Write caregiver profile if role is caregiver
      if (role == 'caregiver' && mitraProfile != null) {
        await _supabase.from('caregivers').insert({
          'id': uid,
          'name': name,
          'photo_url': '',
          'is_available': true,
          'rating': 0.0,
          'total_reviews': 0,
          'skills': mitraProfile['skills'] ?? '',
          'description': mitraProfile['description'] ?? '',
        });
      }

      // Write pharmacy profile if role is pharmacy
      if (role == 'pharmacy') {
        await _supabase.from('pharmacies').insert({
          'id': uid,
          'name': name,
          'address': '',
          'area': '',
          'phone': '',
          'open_hours': '08:00 - 21:00',
          'photo_url': '',
          'is_open': true,
          'rating': 0.0,
          'total_reviews': 0,
        });
      }
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      await _supabase.auth.signInWithPassword(email: email, password: password);
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> logout() async {
    final uid = _currentUser?.id ?? '';
    await NotificationService().deleteToken(uid);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('cached_user_role');
      await prefs.remove('cached_user_name');
    } catch (e) {
      debugPrint('Error clearing cache: $e');
    }
    await _supabase.auth.signOut();
  }
}
