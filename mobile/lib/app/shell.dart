import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:openair/app/theme.dart';
import 'package:openair/core/audio/mini_player.dart';

/// The frame around the four main tabs: the current tab's screen, the mini
/// player when audio is loaded, and the tab bar.
class AppShell extends StatelessWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  static const _tabs = [
    _Tab('/home', 'Home', Icons.home_outlined, Icons.home_rounded),
    _Tab('/live', 'Live', Icons.sensors_rounded, Icons.sensors_rounded),
    _Tab('/schedule', 'Guide', Icons.calendar_today_outlined, Icons.calendar_today_rounded),
    _Tab('/library', 'Library', Icons.bookmark_outline_rounded, Icons.bookmark_rounded),
  ];

  int _selectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final index = _tabs.indexWhere((tab) => location.startsWith(tab.route));
    return index < 0 ? 0 : index;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final selected = _selectedIndex(context);

    return Scaffold(
      body: Column(
        children: [
          Expanded(child: child),
          const MiniPlayer(),
        ],
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.background,
          border: Border(top: BorderSide(color: colors.border)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Row(
              children: [
                for (var i = 0; i < _tabs.length; i++)
                  Expanded(
                    child: _TabButton(
                      tab: _tabs[i],
                      selected: i == selected,
                      onTap: () => context.go(_tabs[i].route),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Tab {
  final String route;
  final String label;
  final IconData icon;
  final IconData activeIcon;
  const _Tab(this.route, this.label, this.icon, this.activeIcon);
}

class _TabButton extends StatelessWidget {
  final _Tab tab;
  final bool selected;
  final VoidCallback onTap;

  const _TabButton({required this.tab, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final labelStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
          letterSpacing: 0,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? colors.text : colors.textMuted,
        );

    return Semantics(
      button: true,
      selected: selected,
      label: tab.label,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        radius: 40,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // The selected tab's icon sits on a pill in the brand colour.
            AnimatedContainer(
              duration: AppMotion.fast,
              width: 48,
              height: 28,
              decoration: BoxDecoration(
                color: selected ? colors.brand : colors.brand.withValues(alpha: 0),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Icon(
                selected ? tab.activeIcon : tab.icon,
                size: 20,
                color: selected ? colors.onBrand : colors.textMuted,
              ),
            ),
            const SizedBox(height: 4),
            Text(tab.label, style: labelStyle),
          ],
        ),
      ),
    );
  }
}
