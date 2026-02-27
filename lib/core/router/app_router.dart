import 'package:flutter/material.dart';
import '../widgets/main_home_page.dart';

class AppRouter extends StatelessWidget {
  const AppRouter({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // MainHomePage is the root of the app. It manages the BottomNavigationBar
    // and pushes feature pages using Navigator.push so back behavior is handled
    // naturally by Flutter.
    return const MainHomePage();
  }
}
