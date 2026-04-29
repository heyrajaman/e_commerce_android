import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_constants.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/app_extensions.dart';
import '../models/product_model.dart';
import 'glass_container.dart';

class ProductCardWidget extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onTap;

  const ProductCardWidget({
    super.key,
    required this.product,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child:
          GlassContainer(
                // Remove padding so the image goes flush to the edges of the card
                padding: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Product Image with Sale Badge Overlay ---
                    Expanded(
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(AppConstants.kRadiusLG),
                            ),
                            child: product.images.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl:
                                        product.images.first.toEmulatorUrl,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(
                                      color: AppColors.kGlassWhite,
                                      child: const Center(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColors.kAccentIndigo,
                                        ),
                                      ),
                                    ),
                                    errorWidget: (context, url, error) =>
                                        Container(
                                          color: AppColors.kGlassWhite,
                                          child: const Icon(
                                            Icons.image_not_supported_outlined,
                                            color: AppColors.kTextSecondary,
                                          ),
                                        ),
                                  )
                                : Container(
                                    color: AppColors.kGlassWhite,
                                    child: const Icon(
                                      Icons.image_not_supported_outlined,
                                      color: AppColors.kTextSecondary,
                                    ),
                                  ),
                          ),

                          // Discount Badge
                          if (product.isOnSale)
                            Positioned(
                              top: AppConstants.kSpaceSM,
                              left: AppConstants.kSpaceSM,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppConstants.kSpaceSM,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.kAccentIndigo,
                                  borderRadius: BorderRadius.circular(
                                    AppConstants.kRadiusSM,
                                  ),
                                ),
                                child: Text(
                                  'SALE',
                                  style: AppTextStyles.kLabelSmall.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // --- Product Details ---
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: AppTextStyles.kLabelLarge.copyWith(
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),

                          // Pricing Logic
                          if (product.isOnSale) ...[
                            Row(
                              children: [
                                Text(
                                  '\$${product.effectivePrice.toStringAsFixed(2)}',
                                  style: AppTextStyles.kBodyMedium.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.kTextPrimary,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    product.price.toCurrency(),
                                    style: AppTextStyles.kLabelSmall.copyWith(
                                      decoration: TextDecoration.lineThrough,
                                      color: AppColors.kTextSecondary,
                                      fontSize: 10,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ] else ...[
                            Text(
                              product.price.toCurrency(),
                              style: AppTextStyles.kBodyMedium.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.kTextPrimary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              )
              .animate()
              .scale(
                duration: AppConstants.kAnimFast,
                curve: Curves.easeOut,
                begin: const Offset(0.95, 0.95),
                end: const Offset(1.0, 1.0),
              )
              .fadeIn(duration: AppConstants.kAnimFast),
    );
  }
}
