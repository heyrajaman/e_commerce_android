import 'package:flutter/material.dart';

import '../../core/utils/responsive_helper.dart';

class ResponsiveBuilder extends StatelessWidget {
  final WidgetBuilder mobile;
  final WidgetBuilder? tablet;
  final WidgetBuilder? desktop;

  const ResponsiveBuilder({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Desktop Layout
        if (constraints.maxWidth >= ResponsiveHelper.kDesktopMinWidth) {
          // Fallback to tablet, then to mobile if desktop isn't provided
          return (desktop ?? tablet ?? mobile)(context);
        }
        // Tablet Layout
        else if (constraints.maxWidth > ResponsiveHelper.kMobileMaxWidth) {
          // Fallback to mobile if tablet isn't provided
          return (tablet ?? mobile)(context);
        }
        // Mobile Layout
        else {
          return mobile(context);
        }
      },
    );
  }
}

class ResponsiveGridView<T> extends StatelessWidget {
  final List<T> items;
  final Widget Function(BuildContext context, int index, T item) itemBuilder;
  final int mobileColumns;
  final int tabletColumns;
  final int desktopColumns;

  // Customization parameters to pass down to the GridView
  final double childAspectRatio;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;
  final bool shrinkWrap;

  const ResponsiveGridView({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.mobileColumns = 2,
    this.tabletColumns = 3,
    this.desktopColumns = 4,
    this.childAspectRatio = 0.75, // Good default for product cards
    this.crossAxisSpacing = 16.0,
    this.mainAxisSpacing = 16.0,
    this.padding,
    this.physics,
    this.shrinkWrap = false,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      mobile: (context) => _buildGrid(context, mobileColumns),
      tablet: (context) => _buildGrid(context, tabletColumns),
      desktop: (context) => _buildGrid(context, desktopColumns),
    );
  }

  Widget _buildGrid(BuildContext context, int crossAxisCount) {
    return GridView.builder(
      padding: padding,
      physics: physics,
      shrinkWrap: shrinkWrap,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: crossAxisSpacing,
        mainAxisSpacing: mainAxisSpacing,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) => itemBuilder(context, index, items[index]),
    );
  }
}