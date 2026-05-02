import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/size_config.dart';
import '../widgets/adaptive_layout_widget.dart';
import '../widgets/cart_badge_widget.dart';

class MainLayoutScreen extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainLayoutScreen({super.key, required this.navigationShell});

  // Updated to match the expected signature (removed BuildContext)
  void _onDestinationSelected(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig.setScreenSize(context);

    final destinations = [
      const AdaptiveDestination(
        label: 'Home',
        icon: Icon(Icons.home_outlined),
        activeIcon: Icon(Icons.home),
      ),
      const AdaptiveDestination(
        label: 'Shop',
        icon: Icon(Icons.storefront_outlined),
        activeIcon: Icon(Icons.storefront),
      ),
      AdaptiveDestination(
        label: 'Cart',
        icon: CartBadgeWidget(onTap: () {}),
        activeIcon: CartBadgeWidget(onTap: () {}),
      ),
      const AdaptiveDestination(
        label: 'Profile',
        icon: Icon(Icons.person_outline),
        activeIcon: Icon(Icons.person),
      ),
    ];

    return AdaptiveScaffold(
      selectedIndex: navigationShell.currentIndex,
      onDestinationSelected: _onDestinationSelected,
      destinations: destinations,
      body: navigationShell,
    );
  }
}
