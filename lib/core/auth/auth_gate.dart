import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../router/app_router.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/farm/farm_context.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  Future<FarmContext?>? _activeFarmFuture;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = Supabase.instance.client.auth.currentSession;
        
        Widget currentWidget;
        if (session == null) {
          // Clear farm context on logout and reset the future
          FarmContext.activeFarm = null;
          _activeFarmFuture = null;
          currentWidget = const LoginScreen(key: ValueKey('login'));
        } else {
          // Initialize the future exactly once when authenticated
          _activeFarmFuture ??= FarmContext.resolveActiveFarm();

          // Resolve the active farm before showing the app
          currentWidget = FutureBuilder<FarmContext?>(
            key: const ValueKey('future_builder'),
            future: _activeFarmFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  key: ValueKey('loading'),
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              return const AppRouter(key: ValueKey('app_router'));
            },
          );
        }

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: currentWidget,
        );
      },
    );
  }
}
