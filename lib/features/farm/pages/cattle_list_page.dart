import 'dart:async';
import 'package:flutter/material.dart';
import 'package:gowlok/core/widgets/top_app_bar.dart';
import 'package:gowlok/core/widgets/bottom_nav_bar.dart';
import 'package:gowlok/core/theme/health_status_colors.dart';
import 'package:gowlok/core/theme/app_theme.dart';
import '../farm_context.dart';
import '../models/cattle_with_health.dart';
import '../services/cattle_service.dart';
import '../../alerts/services/alert_realtime_service.dart';
import 'cattle_health_detail_page.dart';
import 'cattle_registration_page.dart';
import '../../../core/locale/app_translations.dart';

class CattleListPage extends StatefulWidget {
  const CattleListPage({Key? key}) : super(key: key);

  @override
  State<CattleListPage> createState() => _CattleListPageState();
}

class _CattleListPageState extends State<CattleListPage> {
  late Future<List<CattleWithHealth>> _cattleFuture;
  StreamSubscription<void>? _alertSub;

  // Filter state
  String? _filterGender;
  String? _filterHealth;
  String? _filterBreed;
  bool? _filterAlertOnly;

  // Sort state
  String _sortOrder = 'newest'; // 'newest', 'oldest', 'tag_asc', 'tag_desc'

  // Display limit (null = show all)
  int? _displayLimit;

  @override
  void initState() {
    super.initState();
    final activeFarm = FarmContext.activeFarm;
    if (activeFarm != null) {
      AlertRealtimeService().subscribe(activeFarm.farmId);
      _cattleFuture = CattleService.getCattleByFarm(activeFarm.farmId);
      _alertSub = AlertRealtimeService().alertStream.listen((_) {
        _onPullToRefresh();
      });
    } else {
      _cattleFuture = Future.value([]);
    }
  }

  @override
  void dispose() {
    _alertSub?.cancel();
    AlertRealtimeService().unsubscribe();
    super.dispose();
  }

  Future<void> _onPullToRefresh() async {
    final activeFarm = FarmContext.activeFarm;
    if (activeFarm != null) {
      final newCattle = await CattleService.getCattleByFarm(activeFarm.farmId);
      if (mounted) {
        setState(() {
          _cattleFuture = Future.value(newCattle);
        });
      }
    }
  }

  List<CattleWithHealth> _applyFiltersAndSort(List<CattleWithHealth> list) {
    var filtered = List<CattleWithHealth>.from(list);

    if (_filterGender != null) {
      filtered = filtered
          .where((c) => c.gender.toLowerCase() == _filterGender!.toLowerCase())
          .toList();
    }
    if (_filterHealth != null) {
      filtered = filtered
          .where(
              (c) => c.healthStatus.toLowerCase() == _filterHealth!.toLowerCase())
          .toList();
    }
    if (_filterBreed != null) {
      filtered = filtered
          .where((c) => c.breed.toLowerCase() == _filterBreed!.toLowerCase())
          .toList();
    }
    if (_filterAlertOnly == true) {
      filtered = filtered.where((c) => c.hasActiveAlert).toList();
    }

    switch (_sortOrder) {
      case 'oldest':
        // Keep original DB order (ascending)
        break;
      case 'newest':
        filtered = filtered.reversed.toList();
        break;
      case 'tag_asc':
        filtered.sort((a, b) => a.tagNumber.compareTo(b.tagNumber));
        break;
      case 'tag_desc':
        filtered.sort((a, b) => b.tagNumber.compareTo(a.tagNumber));
        break;
    }

    // Apply display limit
    if (_displayLimit != null && _displayLimit! < filtered.length) {
      filtered = filtered.sublist(0, _displayLimit!);
    }

    return filtered;
  }

  Set<String> _getUniqueBreeds(List<CattleWithHealth> cattle) {
    return cattle.map((c) => c.breed).where((b) => b.isNotEmpty).toSet();
  }

  void _showFilterSheet(List<CattleWithHealth> allCattle) {
    final breeds = _getUniqueBreeds(allCattle);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Filter Cattle',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        TextButton(
                          onPressed: () {
                            setSheetState(() {
                              _filterGender = null;
                              _filterHealth = null;
                              _filterBreed = null;
                              _filterAlertOnly = null;
                            });
                            setState(() {});
                          },
                          child: const Text('Clear All'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Gender
                    const Text('Gender',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: ['Female', 'Male'].map((g) {
                        final selected =
                            _filterGender?.toLowerCase() == g.toLowerCase();
                        return ChoiceChip(
                          label: Text(g),
                          selected: selected,
                          onSelected: (v) {
                            setSheetState(() {
                              _filterGender = v ? g : null;
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),

                    // Health Status
                    const Text('Health Status',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: ['Normal', 'Warning', 'Critical'].map((h) {
                        final selected =
                            _filterHealth?.toLowerCase() == h.toLowerCase();
                        return ChoiceChip(
                          label: Text(h),
                          selected: selected,
                          onSelected: (v) {
                            setSheetState(() {
                              _filterHealth = v ? h : null;
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),

                    // Breed
                    if (breeds.isNotEmpty) ...[
                      const Text('Breed',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: breeds.map((b) {
                          final selected =
                              _filterBreed?.toLowerCase() == b.toLowerCase();
                          return ChoiceChip(
                            label: Text(b),
                            selected: selected,
                            onSelected: (v) {
                              setSheetState(() {
                                _filterBreed = v ? b : null;
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Active Alerts
                    CheckboxListTile(
                      title: const Text('With Active Alerts Only'),
                      value: _filterAlertOnly ?? false,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (v) {
                        setSheetState(() {
                          _filterAlertOnly = v == true ? true : null;
                        });
                      },
                    ),

                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          setState(() {});
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text('Apply Filters'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  int _totalCattleCount = 0;

  void _showSortSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final maxCount = _totalCattleCount > 0 ? _totalCattleCount : 1;
            final currentLimit = _displayLimit ?? maxCount;
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sort Cattle',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _sortOption(ctx, 'Newest First', 'newest'),
                  _sortOption(ctx, 'Oldest First', 'oldest'),
                  _sortOption(ctx, 'Tag Number (A → Z)', 'tag_asc'),
                  _sortOption(ctx, 'Tag Number (Z → A)', 'tag_desc'),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Show Count',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        _displayLimit == null ? 'All ($maxCount)' : '$currentLimit / $maxCount',
                        style: TextStyle(
                          color: GowlokColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: currentLimit.toDouble(),
                    min: 1,
                    max: maxCount.toDouble(),
                    divisions: maxCount > 1 ? maxCount - 1 : 1,
                    label: currentLimit == maxCount ? 'All' : currentLimit.toString(),
                    onChanged: (val) {
                      final intVal = val.round();
                      setSheetState(() {});
                      setState(() {
                        _displayLimit = intVal >= maxCount ? null : intVal;
                      });
                    },
                  ),
                  if (_displayLimit != null)
                    Center(
                      child: TextButton(
                        onPressed: () {
                          setSheetState(() {});
                          setState(() => _displayLimit = null);
                        },
                        child: const Text('Show All'),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _sortOption(BuildContext ctx, String label, String value) {
    return ListTile(
      title: Text(label),
      trailing: _sortOrder == value
          ? const Icon(Icons.check, color: GowlokColors.primary)
          : null,
      contentPadding: EdgeInsets.zero,
      onTap: () {
        Navigator.pop(ctx);
        setState(() => _sortOrder = value);
      },
    );
  }

  bool get _hasActiveFilters =>
      _filterGender != null ||
      _filterHealth != null ||
      _filterBreed != null ||
      _filterAlertOnly == true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GowlokTopBar(title: tr(context, 'cattle_list')),
      bottomNavigationBar: GlobalBottomNav.persistent(context),
      body: FutureBuilder<List<CattleWithHealth>>(
        future: _cattleFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final allCattle = snapshot.data ?? [];
          _totalCattleCount = allCattle.length;
          final cattle = _applyFiltersAndSort(allCattle);

          return Column(
            children: [
                  // ── FILTER + SORT BAR ──
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                        GowlokSpacing.md, GowlokSpacing.sm, GowlokSpacing.md, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _showFilterSheet(allCattle),
                            icon: Icon(
                              Icons.filter_list,
                              size: 18,
                              color: _hasActiveFilters
                                  ? GowlokColors.primary
                                  : null,
                            ),
                            label: Text(
                              _hasActiveFilters ? 'Filtered' : 'Filter',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _showSortSheet,
                            icon: const Icon(Icons.sort, size: 18),
                            label: const Text('Sort'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: GowlokColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${cattle.length}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: GowlokColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── REGISTER CATTLE BUTTON ──
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: GowlokSpacing.md,
                      vertical: GowlokSpacing.sm,
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const CattleRegistrationPage()),
                          );
                        },
                        icon: const Icon(Icons.add),
                        label: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 10),
                          child: Text(
                            'Register Cattle',
                            style: TextStyle(fontSize: 15),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ── CATTLE LIST ──
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _onPullToRefresh,
                      child: cattle.isEmpty
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.all(GowlokSpacing.md),
                              children: [
                                SizedBox(height: MediaQuery.of(context).size.height * 0.15),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.pets,
                                      size: 48,
                                      color: Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? GowlokColors.neutral600
                                          : GowlokColors.neutral400,
                                    ),
                                    const SizedBox(height: GowlokSpacing.md),
                                    Text(
                                      allCattle.isEmpty
                                          ? tr(context, 'no_cattle_registered')
                                          : 'No cattle match filters',
                                      style: GowlokTextStyles.headline3,
                                      textAlign: TextAlign.center,
                                    ),
                                    if (allCattle.isEmpty) ...[
                                      const SizedBox(height: GowlokSpacing.sm),
                                      Text(
                                        tr(context, 'no_cattle_farm'),
                                        style:
                                            GowlokTextStyles.bodyMedium.copyWith(
                                          color: GowlokColors.neutral600,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            )
                          : ListView.separated(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.symmetric(
                                horizontal: GowlokSpacing.md,
                                vertical: GowlokSpacing.sm,
                              ),
                              itemCount: cattle.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: GowlokSpacing.sm),
                              itemBuilder: (context, index) {
                                final item = cattle[index];
                                final statusColor =
                                    getHealthStatusColor(item.healthStatus);
                                final isDark = Theme.of(context).brightness ==
                                    Brightness.dark;

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
                                      padding:
                                          const EdgeInsets.all(GowlokSpacing.md),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 80,
                                            height: 80,
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(
                                                  GowlokTheme.cardRadius),
                                              color: isDark
                                                  ? GowlokColors.neutral700
                                                  : GowlokColors.neutral200,
                                              border: item.hasActiveAlert
                                                  ? Border.all(
                                                      color:
                                                          GowlokColors.critical,
                                                      width: 2,
                                                    )
                                                  : null,
                                            ),
                                            child: item.primaryImageUrl != null
                                                ? ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                      GowlokTheme.cardRadius,
                                                    ),
                                                    child: Image.network(
                                                      item.primaryImageUrl!,
                                                      fit: BoxFit.cover,
                                                      errorBuilder:
                                                          (_, __, ___) =>
                                                              const _PlaceholderImage(),
                                                    ),
                                                  )
                                                : const _PlaceholderImage(),
                                          ),
                                          const SizedBox(
                                              width: GowlokSpacing.md),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    if (item.hasActiveAlert)
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets.only(
                                                          right: GowlokSpacing.sm,
                                                        ),
                                                        child: Icon(
                                                          Icons.warning_rounded,
                                                          color: GowlokColors
                                                              .critical,
                                                          size: 20,
                                                        ),
                                                      ),
                                                    Expanded(
                                                      child: Text(
                                                        item.breed,
                                                        style: GowlokTextStyles
                                                            .headline3,
                                                        overflow:
                                                            TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(
                                                    height: GowlokSpacing.xs),
                                                Text(
                                                  'Tag: ${item.tagNumber} • ${item.gender}',
                                                  style: GowlokTextStyles
                                                      .bodySmall
                                                      .copyWith(
                                                    color:
                                                        GowlokColors.neutral600,
                                                  ),
                                                ),
                                                const SizedBox(
                                                    height: GowlokSpacing.sm),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                    horizontal: GowlokSpacing.sm,
                                                    vertical: GowlokSpacing.xs,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: statusColor.withValues(
                                                        alpha: 0.2),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                      GowlokTheme.chipRadius,
                                                    ),
                                                  ),
                                                  child: Text(
                                                    item.healthStatus
                                                        .toUpperCase(),
                                                    style: GowlokTextStyles
                                                        .labelSmall
                                                        .copyWith(
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
                            ),
                    ),
                  ),
                ],
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
