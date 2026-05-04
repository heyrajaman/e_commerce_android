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
    return Container(
      // 🟢 This ensures the GlassContainer extends behind the status bar
      color: Colors.transparent,
      child: GlassContainer(
        borderRadius: 0, // 🟢 FIX: Set to 0 to make it full horizontal width
        padding: EdgeInsets.zero,
        child: AppBar(
          // Make the actual AppBar background transparent
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          centerTitle: centerTitle,
          title: Text(
            title,
            style: AppTextStyles.kHeading3.copyWith(
              color: AppColors.kTextPrimary,
            ),
          ),
          leading: showBackButton
              ? IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: AppColors.kTextPrimary,
                    size: 20,
                  ),
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/home');
                    }
                  },
                )
              : null,
          actions: actions,
        ),
      ),
    );
  }

  // Use the standard height since we are no longer "floating"
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
