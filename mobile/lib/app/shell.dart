import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:openair/core/audio/mini_player.dart';

class AppShell extends StatelessWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  int _selectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/tv')) return 1;
    if (location.startsWith('/radio')) return 2;
    if (location.startsWith('/schedule')) return 3;
    if (location.startsWith('/library')) return 4;
    if (location.startsWith('/profile')) return 5;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final idx = _selectedIndex(context);

    return Scaffold(
      body: Column(
        children: [
          Expanded(child: child),
          const MiniPlayer(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF111113) : Colors.white,
          border: Border(top: BorderSide(color: isDark ? const Color(0xFF1E1E22) : const Color(0xFFE8EAED), width: 1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.06),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 60,
            child: Row(
              children: _items.asMap().entries.map((entry) {
                final i = entry.key;
                final item = entry.value;
                final selected = idx == i;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => context.go(item.route),
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: selected ? theme.colorScheme.primary.withValues(alpha: 0.12) : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Icon(
                              selected ? item.activeIcon : item.icon,
                              size: 22,
                              color: selected ? theme.colorScheme.primary : (isDark ? const Color(0xFF555560) : const Color(0xFFAAAAAA)),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.label,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                              color: selected ? theme.colorScheme.primary : (isDark ? const Color(0xFF555560) : const Color(0xFFAAAAAA)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final String route;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem({required this.route, required this.icon, required this.activeIcon, required this.label});
}

const _items = [
  _NavItem(route: '/home',     icon: Icons.home_outlined,          activeIcon: Icons.home_rounded,           label: 'Home'),
  _NavItem(route: '/tv',       icon: Icons.tv_outlined,            activeIcon: Icons.tv_rounded,             label: 'TV'),
  _NavItem(route: '/radio',    icon: Icons.radio_outlined,         activeIcon: Icons.radio_rounded,          label: 'Radio'),
  _NavItem(route: '/schedule', icon: Icons.calendar_today_outlined,activeIcon: Icons.calendar_today_rounded, label: 'Guide'),
  _NavItem(route: '/library',  icon: Icons.video_library_outlined, activeIcon: Icons.video_library_rounded,  label: 'Library'),
  _NavItem(route: '/profile',  icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded,         label: 'Profile'),
];