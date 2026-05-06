import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/size_config.dart';
import '../../features/cart/presentation/bloc/cart_bloc.dart';
import '../../features/cart/presentation/bloc/cart_event.dart';
import '../../features/profile/presentation/bloc/profile_bloc.dart';
import '../../features/profile/presentation/bloc/profile_event.dart';
import '../widgets/adaptive_layout_widget.dart';
import '../widgets/cart_badge_widget.dart';

class MainLayoutScreen extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MainLayoutScreen({super.key, required this.navigationShell});

  @override
  State<MainLayoutScreen> createState() => _MainLayoutScreenState();
}

class _MainLayoutScreenState extends State<MainLayoutScreen> {
  @override
  void initState() {
    super.initState();
    context.read<CartBloc>().add(const CartFetchRequested());
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
        icon: IgnorePointer(child: CartBadgeWidget(onTap: () {})),
        activeIcon: IgnorePointer(child: CartBadgeWidget(onTap: () {})),
      ),
      const AdaptiveDestination(
        label: 'Profile',
        icon: Icon(Icons.person_outline),
        activeIcon: Icon(Icons.person),
      ),
    ];

    return AdaptiveScaffold(
      selectedIndex: widget.navigationShell.currentIndex,
      onDestinationSelected: (index) {
        if (index == 3) {
          context.read<ProfileBloc>().add(const ProfileFetchRequested());
        }

        if (index == 2) {
          context.read<CartBloc>().add(const CartFetchRequested());
        }

        widget.navigationShell.goBranch(
          index,
          initialLocation: index == widget.navigationShell.currentIndex,
        );
      },
      destinations: destinations,
      body: widget.navigationShell,
    );
  }
}
