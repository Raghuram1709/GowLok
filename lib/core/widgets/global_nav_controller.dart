import 'package:flutter/material.dart';

/// Manages the global bottom nav tab index.
/// Sub-pages call switchTo() to pop back to root and change tab.
class GlobalNavController {
  GlobalNavController._();

  static final selectedIndex = ValueNotifier<int>(0);

  /// Pop all routes to root, then switch to the given tab index.
  static void switchTo(BuildContext context, int index) {
    selectedIndex.value = index;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}
