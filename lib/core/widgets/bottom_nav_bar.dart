import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class GlobalBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const GlobalBottomNav({Key? key, required this.currentIndex, required this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? GowlokColors.neutral800 : Colors.white;

    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      backgroundColor: bg,
      elevation: 8,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: GowlokColors.primary,
      unselectedItemColor: GowlokColors.neutral600,
      showUnselectedLabels: true,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.agriculture), label: 'Farm'),
        BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Check'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
    );
  }
}
