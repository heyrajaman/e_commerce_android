import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class MeshGradientBackground extends StatelessWidget {
  final Widget child;

  const MeshGradientBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    // We use a Scaffold here so this can be the root of any screen
    return Scaffold(
      backgroundColor: AppColors.kBackground,
      body: Stack(
        children: [
          // 1. Top Left: Soft Indigo
          Positioned(
            top: -150,
            left: -150,
            child: Container(
              width: 500,
              height: 500,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [AppColors.kMeshIndigo, Colors.transparent],
                  stops: [0.2, 1.0],
                ),
              ),
            ),
          ),

          // 2. Top Right: Gentle Pink
          Positioned(
            top: -100,
            right: -200,
            child: Container(
              width: 600,
              height: 600,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [AppColors.kMeshPink, Colors.transparent],
                  stops: [0.1, 1.0],
                ),
              ),
            ),
          ),

          // 3. Bottom Center: Vibrant Purple
          Positioned(
            bottom: -200,
            left: MediaQuery.of(context).size.width / 2 - 300,
            child: Container(
              width: 600,
              height: 600,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [AppColors.kMeshPurple, Colors.transparent],
                  stops: [0.2, 1.0],
                ),
              ),
            ),
          ),

          // 4. The actual screen content goes on top
          SafeArea(child: child),
        ],
      ),
    );
  }
}