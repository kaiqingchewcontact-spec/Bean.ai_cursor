import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../providers/app_state.dart';

/// Main app shell with bottom navigation and a centered scan FAB.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.child});

  final Widget child;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  static const List<_ShellTab> _tabs = [
    _ShellTab(label: 'Home', icon: Icons.home_rounded, path: '/'),
    _ShellTab(
      label: 'Library',
      icon: Icons.inventory_2_rounded,
      path: '/library',
    ),
    _ShellTab(
      label: 'Brew',
      icon: Icons.coffee_maker_rounded,
      path: '/brew',
    ),
    _ShellTab(
      label: 'Journal',
      icon: Icons.book_rounded,
      path: '/journal',
    ),
    _ShellTab(
      label: 'Discover',
      icon: Icons.explore_rounded,
      path: '/discover',
    ),
  ];

  int _indexForLocation(String location) {
    if (location == '/' || location.isEmpty) return 0;
    if (location.startsWith('/library')) return 1;
    if (location.startsWith('/brew')) return 2;
    if (location.startsWith('/journal')) return 3;
    if (location.startsWith('/discover')) return 4;
    return 0;
  }

  void _onTabSelected(int index) {
    final path = _tabs[index].path;
    if (path == '/') {
      context.go('/');
    } else {
      context.go(path);
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<AppState>();

    final routerState = GoRouterState.of(context);
    final location = routerState.uri.path;
    final selectedIndex = _indexForLocation(location);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final barColor = isDark ? BeanTheme.darkSurface : Colors.white;
    final selectedColor = isDark ? BeanTheme.caramel : BeanTheme.espresso;
    final unselectedColor =
        isDark ? BeanTheme.crema.withOpacity(0.45) : BeanTheme.lightRoast.withOpacity(0.55);
    final borderColor =
        isDark ? BeanTheme.darkCard : BeanTheme.latte.withOpacity(0.9);

    return Scaffold(
      extendBody: true,
      body: widget.child,
      floatingActionButton: Material(
        elevation: 8,
        shadowColor: BeanTheme.espresso.withOpacity(0.35),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => context.push('/scan'),
          child: Ink(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  BeanTheme.cherry,
                  BeanTheme.cherry.withOpacity(0.82),
                  BeanTheme.honey.withOpacity(0.95),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: BeanTheme.cherry.withOpacity(0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.photo_camera_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: Material(
        elevation: 12,
        color: barColor,
        child: SafeArea(
          top: false,
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: borderColor, width: 1),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavSlot(
                  tab: _tabs[0],
                  selected: selectedIndex == 0,
                  selectedColor: selectedColor,
                  unselectedColor: unselectedColor,
                  onTap: () => _onTabSelected(0),
                ),
                _NavSlot(
                  tab: _tabs[1],
                  selected: selectedIndex == 1,
                  selectedColor: selectedColor,
                  unselectedColor: unselectedColor,
                  onTap: () => _onTabSelected(1),
                ),
                const SizedBox(width: 72),
                _NavSlot(
                  tab: _tabs[2],
                  selected: selectedIndex == 2,
                  selectedColor: selectedColor,
                  unselectedColor: unselectedColor,
                  onTap: () => _onTabSelected(2),
                ),
                _NavSlot(
                  tab: _tabs[3],
                  selected: selectedIndex == 3,
                  selectedColor: selectedColor,
                  unselectedColor: unselectedColor,
                  onTap: () => _onTabSelected(3),
                ),
                _NavSlot(
                  tab: _tabs[4],
                  selected: selectedIndex == 4,
                  selectedColor: selectedColor,
                  unselectedColor: unselectedColor,
                  onTap: () => _onTabSelected(4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ShellTab {
  const _ShellTab({
    required this.label,
    required this.icon,
    required this.path,
  });

  final String label;
  final IconData icon;
  final String path;
}

class _NavSlot extends StatelessWidget {
  const _NavSlot({
    required this.tab,
    required this.selected,
    required this.selectedColor,
    required this.unselectedColor,
    required this.onTap,
  });

  final _ShellTab tab;
  final bool selected;
  final Color selectedColor;
  final Color unselectedColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? selectedColor : unselectedColor;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(tab.icon, size: 24, color: color),
              const SizedBox(height: 2),
              Text(
                tab.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
