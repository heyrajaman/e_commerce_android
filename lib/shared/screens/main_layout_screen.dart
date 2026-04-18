import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/size_config.dart';
import '../widgets/adaptive_layout_widget.dart'; // <-- Added this import

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
    // 1. Responsive sizing initialized perfectly!
    SizeConfig.setScreenSize(context);

    // 2. Define the navigation items using our new AdaptiveDestination class
    const destinations = [
      AdaptiveDestination(
        label: 'Home',
        icon: Icons.home_outlined,
        activeIcon: Icons.home,
      ),
      AdaptiveDestination(
        label: 'Shop',
        icon: Icons.storefront_outlined,
        activeIcon: Icons.storefront,
      ),
      AdaptiveDestination(
        label: 'Cart',
        icon: Icons.shopping_cart_outlined,
        activeIcon: Icons.shopping_cart,
      ),
      AdaptiveDestination(
        label: 'Profile',
        icon: Icons.person_outline,
        activeIcon: Icons.person,
      ),
    ];

    // 3. Return the AdaptiveScaffold wrapper instead of a raw Scaffold
    return AdaptiveScaffold(
      selectedIndex: navigationShell.currentIndex,
      onDestinationSelected: _onDestinationSelected,
      destinations: destinations,
      body: navigationShell, // GoRouter injects the active screen here
    );
  }
}