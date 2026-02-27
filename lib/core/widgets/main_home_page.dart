import 'package:flutter/material.dart';
import '../../features/farm/farm_shell.dart';
import '../../features/quickcheck/quick_check_page.dart';
import '../../features/profile/profile_page.dart';
import 'bottom_nav_bar.dart';
import 'top_app_bar.dart';
import '../theme/app_theme.dart';

class MainHomePage extends StatefulWidget {
  const MainHomePage({Key? key}) : super(key: key);

  @override
  State<MainHomePage> createState() => _MainHomePageState();
}

class _MainHomePageState extends State<MainHomePage> {
  int _selectedIndex = 0; // used only for visual feedback on the root

  void _onTap(int index) {
    // Home (0) is root content — do not push.
    if (index == 0) {
      setState(() => _selectedIndex = 0);
      return;
    }

    setState(() => _selectedIndex = index);

    Widget page;
    switch (index) {
      case 1:
        page = const FarmShell();
        break;
      case 2:
        page = const QuickCheckPage();
        break;
      case 3:
      default:
        page = const ProfilePage();
        break;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    ).then((_) {
      // restore highlight to Home (root) when returning
      if (mounted) setState(() => _selectedIndex = 0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: GowlokTopBar(title: 'GOWLOK', showHamburger: true),
      body: Padding(
        padding: const EdgeInsets.all(GowlokSpacing.md),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.info_outline,
                size: 72,
              ),
              const SizedBox(height: GowlokSpacing.lg),
              Text(
                'Welcome to GOWLOK',
                style: GowlokTextStyles.headline2,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: GowlokSpacing.md),
              Text(
                'Manage your farm, run quick checks and review your profile',
                style: GowlokTextStyles.bodyMedium.copyWith(
                  color: isDark ? GowlokColors.neutral300 : GowlokColors.neutral600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: GowlokSpacing.lg),
            ],
          ),
        ),
      ),
      bottomNavigationBar: GlobalBottomNav(currentIndex: _selectedIndex, onTap: _onTap),
    );
  }
}
