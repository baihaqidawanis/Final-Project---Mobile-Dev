import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_theme.dart';
import 'features/auth/services/auth_provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/dashboard/screens/role_router_scaffold.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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

/// AppGate: decides whether to show Login or the Role Router
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

    if (auth.currentUser == null) {
      return const LoginScreen();
    }

    return RoleRouterScaffold(userRole: auth.userRole!);
  }
}
