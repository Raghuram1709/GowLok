import 'package:flutter/material.dart';

/// Centralized ThemeController (ChangeNotifier)
/// - exposes ThemeMode (light, dark, system)
/// - notifies listeners on change
class ThemeController extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.system;

  ThemeController([ThemeMode? initial]) {
    _mode = initial ?? ThemeMode.system;
  }

  ThemeMode get themeMode => _mode;

  bool get isSystem => _mode == ThemeMode.system;
  bool get isLight => _mode == ThemeMode.light;
  bool get isDark => _mode == ThemeMode.dark;

  void setLight() {
    _mode = ThemeMode.light;
    notifyListeners();
  }

  void setDark() {
    _mode = ThemeMode.dark;
    notifyListeners();
  }

  void setSystem() {
    _mode = ThemeMode.system;
    notifyListeners();
  }
}

/// Simple InheritedNotifier provider so widgets can access the controller
class ThemeControllerProvider extends InheritedNotifier<ThemeController> {
  const ThemeControllerProvider({
    Key? key,
    required ThemeController controller,
    required Widget child,
  }) : super(key: key, notifier: controller, child: child);

  static ThemeController of(BuildContext context) {
    final provider = context.dependOnInheritedWidgetOfExactType<ThemeControllerProvider>();
    assert(provider != null, 'ThemeControllerProvider not found in widget tree');
    return provider!.notifier!;
  }
}
