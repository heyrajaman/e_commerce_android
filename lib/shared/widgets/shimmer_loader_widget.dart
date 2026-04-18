import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_constants.dart';
import 'glass_container.dart';

// --- Base Shimmer Wrapper ---
class BaseShimmer extends StatelessWidget {
  final Widget child;

  const BaseShimmer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.kGlassWhite,
      highlightColor: AppColors.kAccentIndigo.withValues(alpha: 0.2),
      child: child,
    );
  }
}

// --- 1. Product Card Shimmer ---
class ShimmerProductCard extends StatelessWidget {
  const ShimmerProductCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseShimmer(
      child: GlassContainer(
        padding: const EdgeInsets.all(AppConstants.kSpaceSM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppConstants.kRadiusMD),
                ),
              ),
            ),
            const SizedBox(height: AppConstants.kSpaceSM),
            Container(width: 100, height: 16, color: Colors.white),
            const SizedBox(height: 4),
            Container(width: double.infinity, height: 14, color: Colors.white),
            const SizedBox(height: 4),
            Container(width: 80, height: 14, color: Colors.white),
            const SizedBox(height: AppConstants.kSpaceSM),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(width: 60, height: 20, color: Colors.white),
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// --- 2. Order Card Shimmer ---
class ShimmerOrderCard extends StatelessWidget {
  const ShimmerOrderCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseShimmer(
      child: GlassContainer(
        padding: const EdgeInsets.all(AppConstants.kSpaceLG),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(width: 100, height: 18, color: Colors.white),
                      Container(width: 80, height: 14, color: Colors.white),
                    ],
                  ),
                  const SizedBox(height: AppConstants.kSpaceSM),
                  Row(
                    children: [
                      Container(width: 60, height: 24, color: Colors.white),
                      const SizedBox(width: AppConstants.kSpaceSM),
                      Container(width: 80, height: 14, color: Colors.white),
                    ],
                  ),
                  const SizedBox(height: AppConstants.kSpaceMD),
                  Container(
                    width: 90,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppConstants.kSpaceMD),
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- 3. Profile Header Shimmer ---
class ShimmerProfileHeader extends StatelessWidget {
  const ShimmerProfileHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseShimmer(
      child: Center(
        child: Column(
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(height: AppConstants.kSpaceMD),
            Container(width: 150, height: 24, color: Colors.white),
            const SizedBox(height: AppConstants.kSpaceSM),
            Container(width: 200, height: 16, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

// --- 4. Generic List Tile Shimmer ---
class ShimmerListTile extends StatelessWidget {
  const ShimmerListTile({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseShimmer(
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: AppConstants.kSpaceLG, vertical: AppConstants.kSpaceMD),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppConstants.kSpaceMD),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(width: double.infinity, height: 16, color: Colors.white),
                  const SizedBox(height: 8),
                  Container(width: 120, height: 14, color: Colors.white),
                ],
              ),
            ),
            const SizedBox(width: AppConstants.kSpaceMD),
            Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}