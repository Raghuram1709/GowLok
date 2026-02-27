import 'package:flutter/material.dart';

class GowlokTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showHamburger;

  const GowlokTopBar({Key? key, required this.title, this.showHamburger = false}) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_none),
          onPressed: () {},
        ),
        if (showHamburger)
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {},
          ),
      ],
    );
  }
}
