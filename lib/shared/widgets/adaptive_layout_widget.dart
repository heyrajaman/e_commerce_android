import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive_helper.dart';
import 'glass_container.dart';

// 1. UPDATED: Changed IconData to Widget to support custom badges
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
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        child: layout,
      ),
    );
  }

  Widget _buildMobilePortrait(BuildContext context) {
    return Column(
      key: const ValueKey('mobile_portrait'),
      children: [
        Expanded(child: body),
        SafeArea(
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
                  items: destinations.map((d) {
                    return BottomNavigationBarItem(
                      icon: d.icon,
                      // 2. UPDATED: Removed Icon() wrapper
                      activeIcon: d.activeIcon,
                      // 3. UPDATED: Removed Icon() wrapper
                      label: d.label,
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

  Widget _buildMobileLandscape(BuildContext context) {
    return Row(
      key: const ValueKey('mobile_landscape'),
      children: [
        SafeArea(
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
                labelType: NavigationRailLabelType.none,
                selectedIconTheme: const IconThemeData(
                  color: AppColors.kAccentIndigo,
                ),
                unselectedIconTheme: const IconThemeData(
                  color: AppColors.kTextSecondary,
                ),
                destinations: destinations.map((d) {
                  return NavigationRailDestination(
                    icon: d.icon, // 4. UPDATED
                    selectedIcon: d.activeIcon, // 5. UPDATED
                    label: Text(d.label),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
        Expanded(child: body),
      ],
    );
  }

  Widget _buildTabletPortrait(BuildContext context) {
    return Row(
      key: const ValueKey('tablet_portrait'),
      children: [
        SafeArea(
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
                    icon: d.icon, // 6. UPDATED
                    selectedIcon: d.activeIcon, // 7. UPDATED
                    label: Text(d.label),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
        Expanded(child: body),
      ],
    );
  }

  Widget _buildTabletLandscape(BuildContext context) {
    return Row(
      key: const ValueKey('tablet_landscape'),
      children: [
        SafeArea(
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
                            // 8. UPDATED: No longer injecting color directly into the icon to avoid breaking CartBadgeWidget
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
        Expanded(child: body),
      ],
    );
  }
}
