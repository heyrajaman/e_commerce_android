import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'glass_container.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final List<Widget>? actions;
  final bool centerTitle;

  const CustomAppBar({
    super.key,
    required this.title,
    this.showBackButton = true,
    this.actions,
    this.centerTitle = true,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      // Make the actual AppBar background transparent
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: centerTitle,

      // Inject the Glassmorphism effect behind the AppBar content
      flexibleSpace: const GlassContainer(
        borderRadius: 0, // Flat against the top of the screen
        child: SizedBox.expand(),
      ),

      title: Text(
        title,
        style: AppTextStyles.kHeading3.copyWith(
          color: AppColors.kTextPrimary,
        ),
      ),

      // Standardized GoRouter back button
      leading: showBackButton
          ? IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: AppColors.kTextPrimary,
          size: 20,
        ),
        onPressed: () {
          // canPop safely checks if there's a screen to go back to
          if (context.canPop()) {
            context.pop();
          } else {
            // Fallback for deeply nested shell routes
            context.go('/home');
          }
        },
      )
          : null,

      actions: actions,
    );
  }

  // Required by PreferredSizeWidget to let the Scaffold know the height
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}