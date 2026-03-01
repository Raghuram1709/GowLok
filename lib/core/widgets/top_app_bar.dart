import 'package:flutter/material.dart';
import '../../features/alerts/services/alert_realtime_service.dart';
import '../../features/alerts/services/alert_service.dart';
import '../../features/alerts/pages/alerts_page.dart';
import '../../features/farm/farm_context.dart';

class GowlokTopBar extends StatefulWidget implements PreferredSizeWidget {
  final String title;
  final bool showHamburger;
  final List<Widget>? extraActions;

  const GowlokTopBar({Key? key, required this.title, this.showHamburger = false, this.extraActions}) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  State<GowlokTopBar> createState() => _GowlokTopBarState();
}

class _GowlokTopBarState extends State<GowlokTopBar> {
  @override
  void initState() {
    super.initState();
    final farm = FarmContext.activeFarm;
    if (farm != null) {
      AlertRealtimeService().subscribe(farm.farmId);
    }
  }

  @override
  void dispose() {
    AlertRealtimeService().unsubscribe();
    super.dispose();
  }

  Future<int> _fetchCount() {
    final farm = FarmContext.activeFarm;
    if (farm == null) return Future.value(0);
    return AlertService.getUnresolvedCount(farm.farmId);
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(widget.title),
      actions: [
        if (widget.extraActions != null) ...widget.extraActions!,
        StreamBuilder<void>(
          stream: AlertRealtimeService().alertStream,
          builder: (context, _) {
            return FutureBuilder<int>(
              future: _fetchCount(),
              builder: (context, snapshot) {
                final count = snapshot.data ?? 0;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_none),
                      onPressed: () {
                        final currentRoute = ModalRoute.of(context)?.settings.name;
                        if (currentRoute != AlertsPage.routeName) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AlertsPage(),
                              settings: const RouteSettings(name: AlertsPage.routeName),
                            ),
                          );
                        }
                      },
                    ),
                    if (count > 0)
                      Positioned(
                        right: 6,
                        top: 6,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFF0000),
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          child: Text(
                            count > 99 ? '99+' : count.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              },
            );
          },
        ),
        if (widget.showHamburger)
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openEndDrawer(),
          ),
      ],
    );
  }
}
