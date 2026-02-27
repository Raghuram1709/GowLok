import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../router/app_router.dart';
import '../../features/auth/screens/login_screen.dart';
import 'auth_provider.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        if (!authProvider.isAuthenticated) {
          return const LoginScreen();
        }

        return const AppRouter();
      },
    );
  }
}
