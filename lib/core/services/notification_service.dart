import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Top-level handler for background/terminated FCM messages.
/// MUST be a top-level function (not a class method).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('[FCM] Background message: ${message.notification?.title}');
}

// ═══════════════════════════════════════════════════════════════════════════
//  SERVICE ACCOUNT CREDENTIALS
//  How to get these:
//  1. Firebase Console → Project Settings → Service Accounts
//  2. Click "Generate new private key" → Download JSON
//  3. Copy the values below from that JSON file
// ═══════════════════════════════════════════════════════════════════════════
const String _serviceAccountEmail =
    'firebase-adminsdk-fbsvc@final-project-mobile-dev-1c1c4.iam.gserviceaccount.com';

const String _serviceAccountPrivateKey = '''-----BEGIN PRIVATE KEY-----
MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQCtzElCwQlc1qYT
lFFfBk4MZabxIfCOkUnVrxjaXeF8vvX5FJ0o8ervifggxjC1MEYFCWsynHTwL6VC
pvErC0TqdVr3nPKxCUQCPIH2i7fpUQUCQIyQ02IdT+G7ccvJSVrTKwQH05tq/61T
CoYbOZXEXGvKDCLPtDNtHDcMyEmO4zeQQ3eIW3INyaaNQ2m7RWId3JzVZIizGt9W
QkuO2NFHzUm35lBtbUJ3KYsLf8w4POhBXBBu5pixoVYf+XA5PQSBbLorJYt/pAG/
cR47qHAZyxOFST4FdPkz/iaWiMP4CqD/gZuK9kx+0SrIQH/ixNrvDDVGwzetKAby
LXCC/hBxAgMBAAECggEAHARzxvwhi0LbMQrW90+n4127xOGoywLm+Tip9AHwaNDM
DGRjVYdyTT1br8Tjc0Id94/mJRmNzG6R4KXS+RJvALD8gjBd+2Y3/XhNpzYs5sL1
4MARKQO6rGkFRdd5d7CIoMQteSmGw4AGK/3lUpw85ZPUmJTOQ9eT9sH2qevb19nL
MWdcnHdKPaahaLmXzexSq9nqbvEMTEKkJRWYhfdX8KbaWquZ78k6GYoKMQtxglZg
38ORJqyE3MngKiZx5PjR8jd859aq2PKYsxFsuyAp/eb9Q7dY5WaHVOT3E3Ee3k2p
lPdXofxzM5TD2lb+fKM57YoGhUHoV8HJM51vaLLrdQKBgQDd/w84q8iQMwCUwpHM
9OgOkb3lqRtArJ6ZJbZ1d2b/tyAImzkiGCcUIKufW3g8qgVHZDNjGHGvgZirUN6t
aB5C4fne0udvaQj+rp4o4gR2ePAetCzexv2HfsWhUYiNKCv7OL31foVMfK8HdCHk
PvKRfH3UBJ7hGgIGGhMRtCXMbwKBgQDIa0TqhJHAIGdxCPeghKWqYwjHlK+N7JWD
VLq1Xb3n9GRkSF2wUqEGjmndK9WVR4OcjB6yLZZJw8a8Zml8fRHkRa/LcPfxylcH
Sj+XMxd0/IuxXXERkNE58TWdFCV/fpxIIf7g+GaA5Fq07gnMO15mml5mtBb47igi
+dErBfAhHwKBgQCHZh2+jufRK4pbMSEERQuUd0e/X5kDpUVGWz4h/yWPKf4bwbDj
HqAXIqYKmBuJxJlbpb3B3xLX3M9lDfoDAdITMQjZ4wDNbt7Rl2dXwCLAr5qk33fO
mMfhcGzRq40Bq1LH8x/JL9XVhOasQSS6tbn1Cl0kh3zwBpDdb+HZlmrHeQKBgAvq
3QE4+tW614vQJbFk0dkM5IPBoqLE06soiaWpOlaloKaZ6wBGGY8jPsZJCf1DcF8J
sfWUYmBmhNXFHTaq1TqGrkphoEy/ZGdpkdhy0E1Diybz0Hpj6x0P68k4XnZzV+Wu
J9LG0omNiptBoFGFojplqYFf6hHJT5es1TRCuSGvAoGAbfpvtBP6FspfS4FCUL2V
BJ9nxxU7WJR1iwG4SDMjMDeVrlBof6ZDSKaRSz3SpCFRq2i6+TkXgvlW44HyyqGf
gJIrD0p+YEC4ffoZ0rdP6j1zAC+vLWfalq3spmXPEPORZIbFoLdbTM3CYhIIBe+t
B6ica8BhfRFA2md7foVTz1A=
-----END PRIVATE KEY-----''';
// e.g. '-----BEGIN RSA PRIVATE KEY-----\nMIIE...\n-----END RSA PRIVATE KEY-----\n'

const String _projectId = 'final-project-mobile-dev-1c1c4';

// ─────────────────────────────────────────────────────────────────────────

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String? _cachedAccessToken;
  DateTime? _tokenExpiry;

  // ── Init ──────────────────────────────────────────────────────────────────

  /// Initialize FCM: request permission, register handlers, return token.
  Future<String?> initialize() async {
    // 1. Request permission (iOS + Android 13+)
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('[FCM] Permission denied');
      return null;
    }

    // 2. Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // 3. Handle notification tap when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // 4. Handle notification tap when app was terminated
    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpenedApp(initialMessage);
    }

    // 5. Get and log token
    final token = await _fcm.getToken();
    debugPrint('[FCM] Token: $token');

    // 6. Listen for token refresh
    _fcm.onTokenRefresh.listen((newToken) {
      debugPrint('[FCM] Token refreshed: $newToken');
    });

    return token;
  }

  // ── Token Management ──────────────────────────────────────────────────────

  /// Save FCM token to Firestore so others can send notifications to this user.
  Future<void> saveTokenToFirestore(String uid) async {
    if (uid.isEmpty) return;
    try {
      final token = await _fcm.getToken();
      if (token == null) return;
      await _db.collection('users').doc(uid).update({
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('[FCM] Token saved to Firestore for uid: $uid');
    } catch (e) {
      debugPrint('[FCM] Failed to save token: $e');
    }
  }

  /// Delete FCM token on logout (stop receiving notifications).
  ///
  /// NOTE: Token is intentionally kept so multiple accounts on the same
  /// physical device can all receive notifications during testing.
  /// All accounts logged in on this device share the same FCM token,
  /// so swapping accounts does not break notification delivery.
  Future<void> deleteToken(String uid) async {
    debugPrint('[FCM] Logout — FCM token retained for cross-account testing');
  }

  // ── Send Notification (FCM HTTP V1 API) ───────────────────────────────────

  /// Send a push notification to a specific user by their UID.
  /// Uses FCM HTTP V1 API with service account JWT authentication.
  Future<void> sendNotificationToUser({
    required String targetUid,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    if (_serviceAccountEmail == 'YOUR_SERVICE_ACCOUNT_EMAIL_HERE') {
      debugPrint('[FCM] ⚠️ Service account not configured — notification skipped.');
      debugPrint('[FCM]     To demo notifications, send from Firebase Console:');
      debugPrint('[FCM]     Messaging → New Campaign → Test on device');
      return;
    }

    try {
      // 1. Get target FCM token from Firestore
      final doc = await _db.collection('users').doc(targetUid).get();
      final fcmToken = doc.data()?['fcmToken'] as String?;

      if (fcmToken == null || fcmToken.isEmpty) {
        debugPrint('[FCM] Target user $targetUid has no FCM token');
        return;
      }

      // 2. Get OAuth2 access token via service account JWT
      final accessToken = await _getAccessToken();
      if (accessToken == null) {
        debugPrint('[FCM] Failed to obtain access token');
        return;
      }

      // 3. Send via FCM HTTP V1 API
      final endpoint =
          'https://fcm.googleapis.com/v1/projects/$_projectId/messages:send';

      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          'message': {
            'token': fcmToken,
            'notification': {
              'title': title,
              'body': body,
            },
            'android': {
              'priority': 'high',
              'notification': {
                'channel_id': 'healink_bookings',
                'sound': 'default',
              },
            },
            'data': data ?? {},
          },
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('[FCM] ✅ Notification sent to $targetUid');
      } else {
        debugPrint('[FCM] ❌ Failed: ${response.statusCode} — ${response.body}');
      }
    } catch (e) {
      debugPrint('[FCM] Error sending notification: $e');
    }
  }

  // ── OAuth2 via Service Account JWT ────────────────────────────────────────

  /// Generate a short-lived OAuth2 access token using the service account.
  /// Tokens are cached for up to 50 minutes (Google tokens last 60 min).
  Future<String?> _getAccessToken() async {
    // Return cached token if still valid
    if (_cachedAccessToken != null &&
        _tokenExpiry != null &&
        DateTime.now().isBefore(_tokenExpiry!)) {
      return _cachedAccessToken;
    }

    try {
      final now = DateTime.now();
      final expiry = now.add(const Duration(minutes: 60));

      // Create JWT claim set
      final jwt = JWT(
        {
          'iss': _serviceAccountEmail,
          'sub': _serviceAccountEmail,
          'aud': 'https://oauth2.googleapis.com/token',
          'iat': (now.millisecondsSinceEpoch / 1000).floor(),
          'exp': (expiry.millisecondsSinceEpoch / 1000).floor(),
          'scope': 'https://www.googleapis.com/auth/firebase.messaging',
        },
      );

      // Sign with RSA private key
      final privateKey = RSAPrivateKey(_serviceAccountPrivateKey.trim());
      final token = jwt.sign(privateKey, algorithm: JWTAlgorithm.RS256);

      // Exchange JWT for access token
      final response = await http.post(
        Uri.parse('https://oauth2.googleapis.com/token'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'grant_type': 'urn:ietf:params:oauth:grant-type:jwt-bearer',
          'assertion': token,
        },
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        _cachedAccessToken = json['access_token'] as String?;
        // Cache for 50 minutes (token lasts 60)
        _tokenExpiry = now.add(const Duration(minutes: 50));
        return _cachedAccessToken;
      } else {
        debugPrint('[FCM] OAuth2 error: ${response.statusCode} — ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('[FCM] JWT signing error: $e');
      return null;
    }
  }

  // ── Private Handlers ──────────────────────────────────────────────────────

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('[FCM] Foreground: ${message.notification?.title}');
    // Firestore real-time streams automatically update the UI when a booking
    // changes status, so no additional action needed for foreground messages.
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('[FCM] Opened from notification: ${message.data}');
    // Could navigate to dashboard based on message.data['type']
  }
}
