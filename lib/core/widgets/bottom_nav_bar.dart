import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../locale/locale_controller.dart';
import '../locale/app_translations.dart';
import 'global_nav_controller.dart';

class GlobalBottomNav extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const GlobalBottomNav({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  /// Use this on sub-pages pushed via Navigator.push.
  /// Tapping a nav item pops back to root and switches tab.
  static Widget persistent(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: GlobalNavController.selectedIndex,
      builder: (context, index, _) {
        return GlobalBottomNav(
          currentIndex: index,
          onTap: (i) => GlobalNavController.switchTo(context, i),
        );
      },
    );
  }

  @override
  State<GlobalBottomNav> createState() => _GlobalBottomNavState();
}

class _GlobalBottomNavState extends State<GlobalBottomNav> with SingleTickerProviderStateMixin {
  late final AnimationController _entryController;
  late final Animation<Offset> _entryAnimation;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _entryAnimation = Tween<Offset>(
      begin: const Offset(0, 1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOutBack,
    ));

    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? GowlokColors.neutral800.withOpacity(0.9) : Colors.white.withOpacity(0.9);
    final shadowColor = isDark ? Colors.black54 : Colors.black26;

    return Consumer<LocaleController>(
      builder: (context, localeCtrl, _) {
        final items = [
          _NavItemData(Icons.home_rounded, tr(context, 'home')),
          _NavItemData(Icons.agriculture_rounded, tr(context, 'farm')),
          _NavItemData(Icons.search_rounded, tr(context, 'check')),
          _NavItemData(Icons.person_rounded, tr(context, 'profile')),
        ];

        return SlideTransition(
          position: _entryAnimation,
          child: Container(
            height: 70,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(35),
              boxShadow: [
                BoxShadow(
                  color: shadowColor,
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(35),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(items.length, (index) {
                  return _NavItemWidget(
                    data: items[index],
                    isSelected: widget.currentIndex == index,
                    onTap: () => widget.onTap(index),
                  );
                }),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _NavItemData {
  final IconData icon;
  final String label;
  _NavItemData(this.icon, this.label);
}

class _NavItemWidget extends StatefulWidget {
  final _NavItemData data;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItemWidget({
    Key? key,
    required this.data,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  State<_NavItemWidget> createState() => _NavItemWidgetState();
}

class _NavItemWidgetState extends State<_NavItemWidget> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = widget.isSelected 
        ? (isDark ? Colors.blue.shade300 : GowlokColors.primary) 
        : GowlokColors.neutral500;
    
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : (widget.isSelected ? 1.15 : 1.0),
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutQuad,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: widget.isSelected 
                ? (isDark ? Colors.blue.shade300.withOpacity(0.2) : GowlokColors.primary.withOpacity(0.15)) 
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            boxShadow: widget.isSelected
                ? [
                    BoxShadow(
                      color: isDark ? Colors.blue.shade300.withOpacity(0.1) : GowlokColors.primary.withOpacity(0.2),
                      blurRadius: 10,
                      spreadRadius: -2,
                    )
                  ]
                : [],
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.2), // Slide up slightly
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: widget.isSelected
                ? Text(
                    widget.data.label,
                    key: const ValueKey('text'),
                    style: GoogleFonts.outfit(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  )
                : Icon(
                    widget.data.icon,
                    key: const ValueKey('icon'),
                    color: color,
                    size: 26,
                  ),
          ),
        ),
      ),
    );
  }
}
