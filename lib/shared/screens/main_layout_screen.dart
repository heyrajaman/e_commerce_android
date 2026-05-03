import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; // Add this import
import 'package:go_router/go_router.dart';

import '../../core/utils/size_config.dart';
import '../../features/profile/presentation/bloc/profile_bloc.dart'; // Add this import
import '../../features/profile/presentation/bloc/profile_event.dart';
import '../widgets/adaptive_layout_widget.dart';
import '../widgets/cart_badge_widget.dart';

class MainLayoutScreen extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainLayoutScreen({super.key, required this.navigationShell});

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
      onDestinationSelected: (index) {
        if (index == 3) {
          context.read<ProfileBloc>().add(const ProfileFetchRequested());
        }

        navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        );
      },
      destinations: destinations,
      body: navigationShell,
    );
  }
}
