import 'package:flutter/material.dart';
import '../../core/widgets/top_app_bar.dart';
import '../../core/theme/app_theme.dart';
import '../farm/farm_context.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final activeFarm = FarmContext.activeFarm;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: GowlokTopBar(title: 'GOWLOK'),
      body: Padding(
        padding: const EdgeInsets.all(GowlokSpacing.md),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (activeFarm != null) ...[
                Text(
                  'Active Farm',
                  style: GowlokTextStyles.headline2,
                ),
                const SizedBox(height: GowlokSpacing.sm),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(GowlokSpacing.md),
                    child: Text(
                      activeFarm.farmName,
                      style: GowlokTextStyles.headline3,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ] else ...[
                Icon(
                  Icons.agriculture,
                  size: 64,
                  color: isDark ? GowlokColors.neutral600 : GowlokColors.neutral400,
                ),
                const SizedBox(height: GowlokSpacing.lg),
                Text(
                  'Welcome to GOWLOK',
                  style: GowlokTextStyles.headline2,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: GowlokSpacing.md),
                Text(
                  'Select a farm to begin managing your cattle health',
                  style: GowlokTextStyles.bodyMedium.copyWith(
                    color: GowlokColors.neutral600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
