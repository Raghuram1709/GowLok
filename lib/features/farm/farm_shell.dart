import 'package:flutter/material.dart';

import '../../core/widgets/top_app_bar.dart';
import '../../core/theme/app_theme.dart';
import 'farm_home_page.dart';
import 'passbook_page.dart';

class FarmShell extends StatefulWidget {
  const FarmShell({Key? key}) : super(key: key);

  @override
  State<FarmShell> createState() => _FarmShellState();
}

class _FarmShellState extends State<FarmShell> {
  int _localIndex = 0;

  void _onLocalTap(int idx) {
    setState(() {
      _localIndex = idx;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Widget body = _localIndex == 0 ? const FarmHomePage() : const PassbookPage();

    return Scaffold(
      appBar: GowlokTopBar(title: "Farm"),
      body: body,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _localIndex,
        onTap: _onLocalTap,
        backgroundColor: Theme.of(context).bottomNavigationBarTheme.backgroundColor ?? Theme.of(context).cardColor,
        selectedItemColor: GowlokColors.primary,
        unselectedItemColor: GowlokColors.neutral600,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Passbook'),
        ],
      ),
    );
  }
}
