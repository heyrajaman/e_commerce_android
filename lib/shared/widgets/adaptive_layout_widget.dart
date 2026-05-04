import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive_helper.dart';
import 'glass_container.dart';

class AdaptiveDestination {
  final String label;
  final Widget icon;
  final Widget activeIcon;

  const AdaptiveDestination({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });
}

class AdaptiveScaffold extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<AdaptiveDestination> destinations;
  final Widget body;

  const AdaptiveScaffold({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final isTabletOrDesktop =
        ResponsiveHelper.isTablet(context) ||
        ResponsiveHelper.isDesktop(context);
    final isPortrait = ResponsiveHelper.isPortrait(context);

    Widget layout;

    if (isMobile && isPortrait) {
      layout = _buildMobilePortrait(context);
    } else if (isMobile && !isPortrait) {
      layout = _buildMobileLandscape(context);
    } else if (isTabletOrDesktop && isPortrait) {
      layout = _buildTabletPortrait(context);
    } else {
      layout = _buildTabletLandscape(context);
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      extendBodyBehindAppBar: true,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        child: layout,
      ),
    );
  }

  Widget _buildMobilePortrait(BuildContext context) {
    return Stack(
      key: const ValueKey('mobile_portrait'),
      children: [
        Positioned.fill(child: body),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.only(
                left: 16.0,
                right: 16.0,
                bottom: 16.0,
              ),
              child: GlassContainer(
                padding: const EdgeInsets.symmetric(vertical: 4),
                borderRadius: 30,
                child: Theme(
                  data: Theme.of(context).copyWith(
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                  ),
                  child: BottomNavigationBar(
                    elevation: 0,
                    backgroundColor: Colors.transparent,
                    type: BottomNavigationBarType.fixed,
                    selectedItemColor: AppColors.kAccentIndigo,
                    unselectedItemColor: AppColors.kTextSecondary,
                    currentIndex: selectedIndex,
                    onTap: onDestinationSelected,
                    showSelectedLabels: true,
                    showUnselectedLabels: true,
                    selectedFontSize: 12,
                    unselectedFontSize: 12,
                    selectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      height: 1.5, // Added line height for spacing
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.w500,
                      height: 1.5,
                    ),
                    items: destinations.map((d) {
                      return BottomNavigationBarItem(
                        icon: d.icon,
                        activeIcon: d.activeIcon,
                        label: d.label,
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLandscape(BuildContext context) {
    return Stack(
      key: const ValueKey('mobile_landscape'),
      children: [
        Positioned.fill(child: body),
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          child: SafeArea(
            right: false,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: GlassContainer(
                borderRadius: 20,
                child: NavigationRail(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  selectedIndex: selectedIndex,
                  onDestinationSelected: onDestinationSelected,
                  labelType: NavigationRailLabelType.all,
                  // 🟢 Show labels in landscape
                  selectedIconTheme: const IconThemeData(
                    color: AppColors.kAccentIndigo,
                  ),
                  unselectedIconTheme: const IconThemeData(
                    color: AppColors.kTextSecondary,
                  ),
                  destinations: destinations.map((d) {
                    return NavigationRailDestination(
                      icon: d.icon,
                      selectedIcon: d.activeIcon,
                      label: Text(d.label),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabletPortrait(BuildContext context) {
    return Stack(
      key: const ValueKey('tablet_portrait'),
      children: [
        Positioned.fill(child: body),
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          child: SafeArea(
            right: false,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: GlassContainer(
                borderRadius: 24,
                child: NavigationRail(
                  extended: true,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  minExtendedWidth: 160,
                  selectedIndex: selectedIndex,
                  onDestinationSelected: onDestinationSelected,
                  selectedIconTheme: const IconThemeData(
                    color: AppColors.kAccentIndigo,
                  ),
                  unselectedIconTheme: const IconThemeData(
                    color: AppColors.kTextSecondary,
                  ),
                  selectedLabelTextStyle: const TextStyle(
                    color: AppColors.kAccentIndigo,
                    fontWeight: FontWeight.bold,
                  ),
                  unselectedLabelTextStyle: const TextStyle(
                    color: AppColors.kTextSecondary,
                  ),
                  destinations: destinations.map((d) {
                    return NavigationRailDestination(
                      icon: d.icon,
                      selectedIcon: d.activeIcon,
                      label: Text(d.label),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabletLandscape(BuildContext context) {
    return Stack(
      key: const ValueKey('tablet_landscape'),
      children: [
        Positioned.fill(child: body),
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          child: SafeArea(
            right: false,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: GlassContainer(
                borderRadius: 24,
                child: SizedBox(
                  width: 240,
                  child: Column(
                    children: [
                      const SizedBox(height: 40),
                      const Icon(
                        Icons.storefront,
                        size: 48,
                        color: AppColors.kAccentIndigo,
                      ),
                      const SizedBox(height: 40),
                      Expanded(
                        child: ListView.builder(
                          itemCount: destinations.length,
                          itemBuilder: (context, index) {
                            final isSelected = selectedIndex == index;
                            final dest = destinations[index];
                            return ListTile(
                              leading: isSelected ? dest.activeIcon : dest.icon,
                              title: Text(
                                dest.label,
                                style: TextStyle(
                                  color: isSelected
                                      ? AppColors.kAccentIndigo
                                      : AppColors.kTextSecondary,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                              selected: isSelected,
                              onTap: () => onDestinationSelected(index),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
