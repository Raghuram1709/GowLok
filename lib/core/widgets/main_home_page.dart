import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../features/farm/farm_home_page.dart';
import '../../features/quickcheck/quick_check_page.dart';
import '../../features/profile/profile_page.dart';
import 'bottom_nav_bar.dart';
import 'top_app_bar.dart';
import 'settings_drawer.dart';
import 'global_nav_controller.dart';
import '../theme/app_theme.dart';
import '../locale/locale_controller.dart';
import '../locale/app_translations.dart';

class MainHomePage extends StatelessWidget {
  const MainHomePage({Key? key}) : super(key: key);

  void _onTap(int index) {
    GlobalNavController.selectedIndex.value = index;
  }

  Widget _buildHomeBody(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.all(GowlokSpacing.md),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.info_outline, size: 72),
            const SizedBox(height: GowlokSpacing.lg),
            Text(
              tr(context, 'welcome'),
              style: GowlokTextStyles.headline2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: GowlokSpacing.md),
            Text(
              tr(context, 'welcome_desc'),
              style: GowlokTextStyles.bodyMedium.copyWith(
                color: isDark ? GowlokColors.neutral300 : GowlokColors.neutral600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: GowlokSpacing.lg),
          ],
        ),
      ),
    );
  }

  String _titleForIndex(BuildContext context, int index) {
    switch (index) {
      case 0:
        return tr(context, 'app_name');
      case 1:
        return tr(context, 'farm');
      case 2:
        return tr(context, 'check');
      case 3:
        return tr(context, 'profile');
      default:
        return tr(context, 'app_name');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocaleController>(
      builder: (context, localeCtrl, _) {
        return Scaffold(
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(kToolbarHeight),
            child: ValueListenableBuilder<int>(
              valueListenable: GlobalNavController.selectedIndex,
              builder: (context, currentIndex, _) {
                return GowlokTopBar(
                  title: _titleForIndex(context, currentIndex),
                  showHamburger: currentIndex == 0,
                );
              },
            ),
          ),
          endDrawer: const SettingsDrawer(), // Always provided, gesture handles when to show. Or we can conditionally disable inside drawer.
          body: ValueListenableBuilder<int>(
            valueListenable: GlobalNavController.selectedIndex,
            builder: (context, currentIndex, _) {
              return Stack(
                children: [
                  IndexedStack(
                    index: currentIndex,
                    children: [
                      _buildHomeBody(context),
                      const FarmHomePage(),
                      const QuickCheckPage(),
                      const ProfilePage(),
                    ],
                  ),
                  Positioned(
                    bottom: GowlokSpacing.lg,
                    left: GowlokSpacing.lg,
                    right: GowlokSpacing.lg,
                    child: GlobalBottomNav(
                      currentIndex: currentIndex,
                      onTap: _onTap,
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
