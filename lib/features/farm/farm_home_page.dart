import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'pages/cattle_list_page.dart';

class FarmHomePage extends StatelessWidget {
  const FarmHomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(GowlokSpacing.md),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Farm Management',
              style: GowlokTextStyles.headline2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: GowlokSpacing.lg),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CattleListPage(),
                  ),
                );
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: GowlokSpacing.md,
                  vertical: GowlokSpacing.sm,
                ),
                child: Text('View Cattle'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
