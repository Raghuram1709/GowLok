import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/theme_controller.dart';
import '../theme/app_theme.dart';
import '../locale/locale_controller.dart';
import '../locale/app_translations.dart';

class SettingsDrawer extends StatelessWidget {
  const SettingsDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(GowlokSpacing.md),
              child: Text(
                tr(context, 'settings'),
                style: GowlokTextStyles.headline2,
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _ThemeSection(isDark: isDark),
                  const Divider(height: 1),
                  _LanguageSection(isDark: isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeSection extends StatelessWidget {
  final bool isDark;
  const _ThemeSection({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeController>(
      builder: (context, themeCtrl, _) {
        return ExpansionTile(
          leading: Icon(
            Icons.palette_outlined,
            color: isDark ? GowlokColors.neutral300 : GowlokColors.neutral700,
          ),
          title: Text(tr(context, 'theme')),
          children: [
            _themeOption(context, themeCtrl, ThemeMode.light, tr(context, 'light'), Icons.light_mode),
            _themeOption(context, themeCtrl, ThemeMode.dark, tr(context, 'dark'), Icons.dark_mode),
            _themeOption(context, themeCtrl, ThemeMode.system, tr(context, 'system'), Icons.settings_suggest),
          ],
        );
      },
    );
  }

  Widget _themeOption(
    BuildContext context,
    ThemeController ctrl,
    ThemeMode mode,
    String label,
    IconData icon,
  ) {
    final selected = ctrl.themeMode == mode;
    return ListTile(
      contentPadding: const EdgeInsets.only(left: 72, right: 16),
      leading: Icon(icon, size: 20),
      title: Text(label),
      trailing: selected
          ? const Icon(Icons.check_circle, color: GowlokColors.primary)
          : null,
      onTap: () {
        switch (mode) {
          case ThemeMode.light:
            ctrl.setLight();
            break;
          case ThemeMode.dark:
            ctrl.setDark();
            break;
          case ThemeMode.system:
            ctrl.setSystem();
            break;
        }
      },
    );
  }
}

class _LanguageSection extends StatelessWidget {
  final bool isDark;
  const _LanguageSection({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Consumer<LocaleController>(
      builder: (context, localeCtrl, _) {
        return ExpansionTile(
          leading: Icon(
            Icons.translate,
            color: isDark ? GowlokColors.neutral300 : GowlokColors.neutral700,
          ),
          title: Text(tr(context, 'language')),
          children: LocaleController.supportedLocales.map((locale) {
            final code = locale.languageCode;
            final name = LocaleController.languageNames[code] ?? code;
            final selected = localeCtrl.languageCode == code;
            return ListTile(
              contentPadding: const EdgeInsets.only(left: 72, right: 16),
              title: Text(name),
              trailing: selected
                  ? const Icon(Icons.check_circle, color: GowlokColors.primary)
                  : null,
              onTap: () => localeCtrl.setLocale(code),
            );
          }).toList(),
        );
      },
    );
  }
}
