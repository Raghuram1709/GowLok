import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'farm_context.dart';
import 'services/cattle_service.dart';
import 'pages/individual_farm_page.dart';
import 'pages/farm_registration_page.dart';

class FarmHomePage extends StatefulWidget {
  const FarmHomePage({Key? key}) : super(key: key);

  @override
  State<FarmHomePage> createState() => _FarmHomePageState();
}

class _FarmHomePageState extends State<FarmHomePage> {
  late Future<List<FarmContext>> _farmsFuture;

  @override
  void initState() {
    super.initState();
    _farmsFuture = FarmContext.getAllFarms();
  }

  void _refresh() {
    setState(() => _farmsFuture = FarmContext.getAllFarms());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FutureBuilder<List<FarmContext>>(
      future: _farmsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final farms = snapshot.data ?? [];

        return RefreshIndicator(
          onRefresh: () async {
            _refresh();
            await _farmsFuture;
          },
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(GowlokSpacing.md),
            itemCount: farms.length + 1, // +1 for Add Farm card
            itemBuilder: (context, index) {
              // Last item = Add Farm card
              if (index == farms.length) {
                return _AddFarmCard(
                  isDark: isDark,
                  onFarmCreated: _refresh,
                );
              }
              final farm = farms[index];
              return _FarmCard(farm: farm, isDark: isDark);
            },
          ),
        );
      },
    );
  }
}

class _FarmCard extends StatelessWidget {
  final FarmContext farm;
  final bool isDark;

  const _FarmCard({required this.farm, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: GowlokSpacing.md),
      child: GestureDetector(
        onTap: () {
          FarmContext.activeFarm = farm;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => IndividualFarmPage(farm: farm),
            ),
          );
        },
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(GowlokSpacing.md),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: GowlokColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(GowlokTheme.cardRadius),
                  ),
                  child: const Icon(
                    Icons.agriculture,
                    color: GowlokColors.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: GowlokSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        farm.farmName,
                        style: GowlokTextStyles.headline3,
                      ),
                      const SizedBox(height: GowlokSpacing.xs),
                      FutureBuilder<int>(
                        future: CattleService.getCattleCount(farm.farmId),
                        builder: (context, countSnap) {
                          final count = countSnap.data ?? 0;
                          return Text(
                            '$count cattle',
                            style: GowlokTextStyles.bodyMedium.copyWith(
                              color: isDark
                                  ? GowlokColors.neutral400
                                  : GowlokColors.neutral600,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: GowlokSpacing.sm,
                    vertical: GowlokSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: _roleColor(farm.role).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(GowlokTheme.chipRadius),
                  ),
                  child: Text(
                    farm.role.toUpperCase(),
                    style: GowlokTextStyles.labelSmall.copyWith(
                      color: _roleColor(farm.role),
                    ),
                  ),
                ),
                const SizedBox(width: GowlokSpacing.xs),
                Icon(
                  Icons.chevron_right,
                  color: isDark ? GowlokColors.neutral500 : GowlokColors.neutral600,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _roleColor(String role) {
    switch (role.toLowerCase()) {
      case 'owner':
        return GowlokColors.primary;
      case 'manager':
        return const Color(0xFFFFA500);
      default:
        return GowlokColors.success;
    }
  }
}

class _AddFarmCard extends StatelessWidget {
  final bool isDark;
  final VoidCallback onFarmCreated;

  const _AddFarmCard({required this.isDark, required this.onFarmCreated});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: GowlokSpacing.md),
      child: GestureDetector(
        onTap: () async {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => const FarmRegistrationPage(),
            ),
          );
          if (result == true) {
            onFarmCreated();
          }
        },
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(GowlokSpacing.md),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: GowlokColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(GowlokTheme.cardRadius),
                    border: Border.all(
                      color: GowlokColors.success.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.add,
                    color: GowlokColors.success,
                    size: 28,
                  ),
                ),
                const SizedBox(width: GowlokSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add Farm',
                        style: GowlokTextStyles.headline3.copyWith(
                          color: GowlokColors.success,
                        ),
                      ),
                      const SizedBox(height: GowlokSpacing.xs),
                      Text(
                        'Register a new farm',
                        style: GowlokTextStyles.bodySmall.copyWith(
                          color: isDark
                              ? GowlokColors.neutral400
                              : GowlokColors.neutral600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: GowlokColors.success.withValues(alpha: 0.6),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
