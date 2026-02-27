import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gowlok/core/auth/auth_provider.dart';
import 'package:gowlok/core/widgets/top_app_bar.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_controller.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GowlokTopBar(title: 'Profile'),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(GowlokSpacing.md),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'User Profile',
                style: GowlokTextStyles.headline2,
              ),
              const SizedBox(height: GowlokSpacing.lg),
              // theme chooser
              Consumer<ThemeController>(
                builder: (context, themeCtrl, _) {
                  String modeLabel;
                  switch (themeCtrl.themeMode) {
                    case ThemeMode.light:
                      modeLabel = 'Light';
                      break;
                    case ThemeMode.dark:
                      modeLabel = 'Dark';
                      break;
                    case ThemeMode.system:
                    default:
                      modeLabel = 'System';
                      break;
                  }
                  return ListTile(
                    title: const Text('App theme'),
                    subtitle: Text(modeLabel),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showThemeDialog(context, themeCtrl),
                  );
                },
              ),
              const SizedBox(height: GowlokSpacing.lg),
              ElevatedButton(
                onPressed: () async {
                  final authProvider = context.read<AuthProvider>();
                  await authProvider.signOut();
                  // AuthGate will automatically route to LoginScreen when auth state changes
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: GowlokSpacing.md,
                    vertical: GowlokSpacing.sm,
                  ),
                  child: Text('Logout'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showThemeDialog(BuildContext context, ThemeController ctrl) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text('Select theme'),
          children: [
            SimpleDialogOption(
              onPressed: () {
                ctrl.setLight();
                Navigator.pop(context);
              },
              child: const Text('Light'),
            ),
            SimpleDialogOption(
              onPressed: () {
                ctrl.setDark();
                Navigator.pop(context);
              },
              child: const Text('Dark'),
            ),
            SimpleDialogOption(
              onPressed: () {
                ctrl.setSystem();
                Navigator.pop(context);
              },
              child: const Text('System'),
            ),
          ],
        );
      },
    );
  }
}
