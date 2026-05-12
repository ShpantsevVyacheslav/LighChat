import 'package:flutter/material.dart';

import 'breakpoints.dart';

/// Один экран навигации: иконка + подпись + ключ маршрута.
class AdaptiveDestination {
  const AdaptiveDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.route,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final String route;
}

/// Адаптивный scaffold: на узких — BottomNavigationBar, на средних+ —
/// NavigationRail. Контент рисуется как есть; навигация выбирается
/// автоматически по ширине окна.
class AdaptiveScaffold extends StatelessWidget {
  const AdaptiveScaffold({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.body,
    this.appBar,
    this.floatingActionButton,
    this.bottomSheet,
    this.endDrawer,
    this.backgroundColor,
    this.extendBody = false,
    this.extendBodyBehindAppBar = false,
  });

  final List<AdaptiveDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final Widget? bottomSheet;
  final Widget? endDrawer;
  final Color? backgroundColor;
  final bool extendBody;
  final bool extendBodyBehindAppBar;

  @override
  Widget build(BuildContext context) {
    final size = context.layoutSize;

    if (size.isCompact) {
      return Scaffold(
        appBar: appBar,
        backgroundColor: backgroundColor,
        body: body,
        floatingActionButton: floatingActionButton,
        bottomSheet: bottomSheet,
        endDrawer: endDrawer,
        extendBody: extendBody,
        extendBodyBehindAppBar: extendBodyBehindAppBar,
        bottomNavigationBar: destinations.length < 2
            ? null
            : NavigationBar(
                selectedIndex: selectedIndex,
                onDestinationSelected: onDestinationSelected,
                destinations: <Widget>[
                  for (final d in destinations)
                    NavigationDestination(
                      icon: Icon(d.icon),
                      selectedIcon: Icon(d.selectedIcon),
                      label: d.label,
                    ),
                ],
              ),
      );
    }

    final extended = size.isLarge;
    return Scaffold(
      appBar: appBar,
      backgroundColor: backgroundColor,
      endDrawer: endDrawer,
      body: Row(
        children: <Widget>[
          if (destinations.length >= 2)
            _AdaptiveRail(
              destinations: destinations,
              selectedIndex: selectedIndex,
              onDestinationSelected: onDestinationSelected,
              extended: extended,
              floatingActionButton: floatingActionButton,
            ),
          const VerticalDivider(width: 1, thickness: 1),
          Expanded(child: body),
        ],
      ),
      bottomSheet: bottomSheet,
    );
  }
}

class _AdaptiveRail extends StatelessWidget {
  const _AdaptiveRail({
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.extended,
    this.floatingActionButton,
  });

  final List<AdaptiveDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final bool extended;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      extended: extended,
      leading: floatingActionButton,
      labelType: extended ? NavigationRailLabelType.none : NavigationRailLabelType.all,
      destinations: <NavigationRailDestination>[
        for (final d in destinations)
          NavigationRailDestination(
            icon: Icon(d.icon),
            selectedIcon: Icon(d.selectedIcon),
            label: Text(d.label),
          ),
      ],
    );
  }
}
