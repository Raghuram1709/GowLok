import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class PassbookPage extends StatelessWidget {
  const PassbookPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(GowlokSpacing.md),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt,
              size: 64,
              color: isDark ? GowlokColors.neutral600 : GowlokColors.neutral400,
            ),
            const SizedBox(height: GowlokSpacing.md),
            Text(
              'Passbook',
              style: GowlokTextStyles.headline2,
            ),
            const SizedBox(height: GowlokSpacing.sm),
            Text(
              'Milk records & expenses coming soon',
              style: GowlokTextStyles.bodyMedium.copyWith(
                color: GowlokColors.neutral600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
