import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/auth/auth_service.dart';
import 'core/auth/auth_provider.dart';
import 'core/auth/auth_gate.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';

class GowlokApp extends StatelessWidget {
  const GowlokApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authService = AuthService(Supabase.instance.client);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(authService)..initialize(),
        ),
        // controller that drives the application's theme mode
        ChangeNotifierProvider(
          create: (_) => ThemeController(),
        ),
      ],
      child: Consumer<ThemeController>(
        builder: (context, themeCtrl, _) {
          return MaterialApp(
            title: 'GOWLOK',
            debugShowCheckedModeBanner: false,
            theme: GowlokTheme.lightTheme(),
            darkTheme: GowlokTheme.darkTheme(),
            themeMode: themeCtrl.themeMode,
            home: const AuthGate(),
          );
        },
      ),
    );
  }
}
