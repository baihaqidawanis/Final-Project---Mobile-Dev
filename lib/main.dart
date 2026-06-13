import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_theme.dart';
import 'core/services/notification_service.dart';
import 'features/auth/services/auth_provider.dart';
import 'features/home/screens/home_screen.dart';
import 'features/admin/screens/admin_dashboard_screen.dart';
import 'features/dashboard/screens/role_router_scaffold.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Crashlytics
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  // Register FCM background handler BEFORE runApp
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Initialize FCM (request permission, setup handlers)
  await NotificationService().initialize();

  runApp(const HealinkApp());
}

class HealinkApp extends StatelessWidget {
  const HealinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        title: 'Healink',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const AppGate(),
      ),
    );
  }
}

class AppGate extends StatelessWidget {
  const AppGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Not logged in → show HomeScreen as guest
    if (!auth.isLoggedIn) return const HomeScreen();

    // Logged in → route by role
    switch (auth.userRole) {
      case UserRole.admin:
        return const AdminDashboardScreen();
      case UserRole.user:
        return const HomeScreen();
      case UserRole.caregiver:
      case UserRole.hospital:
      case UserRole.pharmacy:
        return RoleRouterScaffold(userRole: auth.userRole!);
      default:
        return const HomeScreen();
    }
  }
}
