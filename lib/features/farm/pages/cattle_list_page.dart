import 'package:flutter/material.dart';
import 'package:gowlok/core/widgets/top_app_bar.dart';
import 'package:gowlok/core/theme/health_status_colors.dart';
import 'package:gowlok/core/theme/app_theme.dart';
import '../farm_context.dart';
import '../models/cattle_with_health.dart';
import '../services/cattle_service.dart';
import '../../alerts/services/alert_realtime_service.dart';
import 'cattle_health_detail_page.dart';

class CattleListPage extends StatefulWidget {
  const CattleListPage({Key? key}) : super(key: key);

  @override
  State<CattleListPage> createState() => _CattleListPageState();
}

class _CattleListPageState extends State<CattleListPage> {
  late Future<List<CattleWithHealth>> _cattleFuture;

  @override
  void initState() {
    super.initState();
    final activeFarm = FarmContext.activeFarm;
    if (activeFarm != null) {
      AlertRealtimeService().subscribe(activeFarm.farmId);
      _cattleFuture = CattleService.getCattleByFarm(activeFarm.farmId);
    } else {
      _cattleFuture = Future.value([]);
    }
  }

  @override
  void dispose() {
    AlertRealtimeService().unsubscribe();
    super.dispose();
  }

  Future<List<CattleWithHealth>> _refreshCattle() {
    final activeFarm = FarmContext.activeFarm;
    if (activeFarm != null) {
      _cattleFuture = CattleService.getCattleByFarm(activeFarm.farmId);
      return _cattleFuture;
    }
    return Future.value([]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GowlokTopBar(title: 'Cattle List'),
      body: StreamBuilder<void>(
        stream: AlertRealtimeService().alertStream,
        builder: (context, streamSnapshot) {
          return FutureBuilder<List<CattleWithHealth>>(
            future: streamSnapshot.hasData
                ? _refreshCattle()
                : _cattleFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final cattle = snapshot.data ?? [];

              if (cattle.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(GowlokSpacing.md),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.pets,
                          size: 48,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? GowlokColors.neutral600
                              : GowlokColors.neutral400,
                        ),
                        const SizedBox(height: GowlokSpacing.md),
                        Text(
                          'No cattle registered',
                          style: GowlokTextStyles.headline3,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: GowlokSpacing.sm),
                        Text(
                          'No cattle in this farm yet',
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

              return ListView.separated(
                padding: const EdgeInsets.all(GowlokSpacing.md),
                itemCount: cattle.length,
                separatorBuilder: (_, __) => const SizedBox(
                  height: GowlokSpacing.sm,
                ),
                itemBuilder: (context, index) {
                  final item = cattle[index];
                  final statusColor = getHealthStatusColor(item.healthStatus);
                  final isDark =
                      Theme.of(context).brightness == Brightness.dark;

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CattleHealthDetailPage(
                            cattleId: item.id,
                            tagNumber: item.tagNumber,
                          ),
                        ),
                      );
                    },
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(GowlokSpacing.md),
                        child: Row(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                borderRadius:
                                    BorderRadius.circular(GowlokTheme.cardRadius),
                                color: isDark
                                    ? GowlokColors.neutral700
                                    : GowlokColors.neutral200,
                                border: item.hasActiveAlert
                                    ? Border.all(
                                        color: GowlokColors.critical,
                                        width: 2,
                                      )
                                    : null,
                              ),
                              child: item.primaryImageUrl != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(
                                        GowlokTheme.cardRadius,
                                      ),
                                      child: Image.network(
                                        item.primaryImageUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            const _PlaceholderImage(),
                                      ),
                                    )
                                  : const _PlaceholderImage(),
                            ),
                            const SizedBox(width: GowlokSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      if (item.hasActiveAlert)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            right: GowlokSpacing.sm,
                                          ),
                                          child: Icon(
                                            Icons.warning_rounded,
                                            color: GowlokColors.critical,
                                            size: 20,
                                          ),
                                        ),
                                      Text(
                                        item.breed,
                                        style: GowlokTextStyles.headline3,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: GowlokSpacing.xs),
                                  Text(
                                    'Tag: ${item.tagNumber} • ${item.gender}',
                                    style: GowlokTextStyles.bodySmall.copyWith(
                                      color: GowlokColors.neutral600,
                                    ),
                                  ),
                                  const SizedBox(height: GowlokSpacing.sm),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: GowlokSpacing.sm,
                                      vertical: GowlokSpacing.xs,
                                    ),
                                    decoration: BoxDecoration(
                                      color: statusColor.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(
                                        GowlokTheme.chipRadius,
                                      ),
                                    ),
                                    child: Text(
                                      item.healthStatus.toUpperCase(),
                                      style: GowlokTextStyles.labelSmall.copyWith(
                                        color: statusColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _PlaceholderImage extends StatelessWidget {
  const _PlaceholderImage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: isDark ? GowlokColors.neutral700 : GowlokColors.neutral300,
      child: Icon(
        Icons.image,
        color: isDark ? GowlokColors.neutral600 : GowlokColors.neutral500,
      ),
    );
  }
}
