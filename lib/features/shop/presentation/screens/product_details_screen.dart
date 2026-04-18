import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_constants.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/glass_container.dart';
import '../../../../shared/widgets/mesh_gradient_background.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../bloc/product_bloc.dart';
import '../bloc/product_event.dart';
import '../bloc/product_state.dart';

class ProductDetailsScreen extends StatefulWidget {
  final String productId;

  const ProductDetailsScreen({super.key, required this.productId});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  final PageController _imageController = PageController();
  int _currentImageIndex = 0;
  int _quantity = 1;
  bool _isDescriptionExpanded = false;

  @override
  void initState() {
    super.initState();
    // Dispatch event to fetch this specific product's details
    context.read<ProductBloc>().add(ProductDetailFetchRequested(widget.productId));
  }

  @override
  void dispose() {
    _imageController.dispose();
    super.dispose();
  }

  void _incrementQuantity(int maxStock) {
    if (_quantity < maxStock) {
      setState(() => _quantity++);
    }
  }

  void _decrementQuantity() {
    if (_quantity > 1) {
      setState(() => _quantity--);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MeshGradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: BlocBuilder<ProductBloc, ProductState>(
          builder: (context, state) {
            if (state is ProductDetailLoading) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.kAccentIndigo),
              );
            } else if (state is ProductError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(state.message, style: AppTextStyles.kBodyMedium.copyWith(color: AppColors.kError)),
                    const SizedBox(height: AppConstants.kSpaceMD),
                    ElevatedButton(
                      onPressed: () => context.pop(),
                      child: const Text('Go Back'),
                    ),
                  ],
                ),
              );
            } else if (state is ProductDetailLoaded) {
              final product = state.product;

              return Stack(
                children: [
                  CustomScrollView(
                    slivers: [
                      // --- Immersive Image Gallery ---
                      SliverAppBar(
                        expandedHeight: 400,
                        pinned: true,
                        backgroundColor: Colors.transparent,
                        leading: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: CircleAvatar(
                            backgroundColor: AppColors.kGlassWhite,
                            child: IconButton(
                              icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.kTextPrimary, size: 20),
                              onPressed: () => context.pop(),
                            ),
                          ),
                        ),
                        flexibleSpace: FlexibleSpaceBar(
                          background: Stack(
                            fit: StackFit.expand,
                            children: [
                              if (product.images.isNotEmpty)
                                PageView.builder(
                                  controller: _imageController,
                                  onPageChanged: (index) => setState(() => _currentImageIndex = index),
                                  itemCount: product.images.length,
                                  itemBuilder: (context, index) {
                                    return CachedNetworkImage(
                                      imageUrl: product.images[index],
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => const Center(
                                        child: CircularProgressIndicator(color: AppColors.kAccentIndigo),
                                      ),
                                    );
                                  },
                                )
                              else
                                Container(
                                  color: AppColors.kGlassWhite,
                                  child: const Icon(Icons.image_not_supported, size: 64, color: AppColors.kTextSecondary),
                                ),

                              // Dot Indicators
                              if (product.images.length > 1)
                                Positioned(
                                  bottom: 40, // Elevated to account for the overlapping container
                                  left: 0,
                                  right: 0,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: List.generate(
                                      product.images.length,
                                          (index) => AnimatedContainer(
                                        duration: AppConstants.kAnimFast,
                                        margin: const EdgeInsets.symmetric(horizontal: 4),
                                        width: _currentImageIndex == index ? 24 : 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: _currentImageIndex == index
                                              ? AppColors.kAccentIndigo
                                              : Colors.white.withValues(alpha: 0.5),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),

                      // --- Product Info Content ---
                      SliverToBoxAdapter(
                        child: Transform.translate(
                          offset: const Offset(0, -30), // Pulls the container up to overlap the image
                          child: GlassContainer(
                            borderRadius: AppConstants.kRadiusXL, // Top rounded corners
                            padding: const EdgeInsets.all(AppConstants.kSpaceLG),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Title and Rating
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(product.name, style: AppTextStyles.kHeading2),
                                    ),
                                    Row(
                                      children: [
                                        const Icon(Icons.star, color: Colors.amber, size: 20),
                                        const SizedBox(width: 4),
                                        Text(
                                          product.rating.toStringAsFixed(1),
                                          style: AppTextStyles.kBodyMedium.copyWith(fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          ' (${product.reviewCount})',
                                          style: AppTextStyles.kLabelSmall,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppConstants.kSpaceMD),

                                // Pricing and Stock Status
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          '\$${product.effectivePrice.toStringAsFixed(2)}',
                                          style: AppTextStyles.kHeading1.copyWith(color: AppColors.kAccentIndigo),
                                        ),
                                        if (product.isOnSale) ...[
                                          const SizedBox(width: AppConstants.kSpaceSM),
                                          Text(
                                            '\$${product.price.toStringAsFixed(2)}',
                                            style: AppTextStyles.kBodyMedium.copyWith(
                                              decoration: TextDecoration.lineThrough,
                                              color: AppColors.kTextSecondary,
                                            ),
                                          ),
                                          const SizedBox(width: AppConstants.kSpaceSM),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: AppColors.kAccentPink..withValues(alpha: 0.2),
                                              borderRadius: BorderRadius.circular(AppConstants.kRadiusSM),
                                            ),
                                            child: Text(
                                              'SALE',
                                              style: AppTextStyles.kLabelSmall.copyWith(
                                                color: AppColors.kAccentPink,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: product.stock > 0
                                            ? Colors.green.withValues(alpha: 0.1)
                                            : AppColors.kError.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(AppConstants.kRadiusSM),
                                      ),
                                      child: Text(
                                        product.stock > 0 ? 'In Stock' : 'Out of Stock',
                                        style: AppTextStyles.kLabelSmall.copyWith(
                                          color: product.stock > 0 ? Colors.green : AppColors.kError,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(height: AppConstants.kSpaceXXL, color: AppColors.kGlassBorder),

                                // Description
                                Text('Description', style: AppTextStyles.kHeading3),
                                const SizedBox(height: AppConstants.kSpaceSM),
                                AnimatedCrossFade(
                                  firstChild: Text(
                                    product.description,
                                    style: AppTextStyles.kBodyMedium.copyWith(color: AppColors.kTextSecondary),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  secondChild: Text(
                                    product.description,
                                    style: AppTextStyles.kBodyMedium.copyWith(color: AppColors.kTextSecondary),
                                  ),
                                  crossFadeState: _isDescriptionExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                                  duration: AppConstants.kAnimFast,
                                ),
                                GestureDetector(
                                  onTap: () => setState(() => _isDescriptionExpanded = !_isDescriptionExpanded),
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      _isDescriptionExpanded ? 'Show less' : 'Show more',
                                      style: AppTextStyles.kLabelLarge.copyWith(color: AppColors.kAccentIndigo),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 100), // Padding for the bottom cart bar
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // --- Bottom Add to Cart Bar ---
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: GlassContainer(
                      borderRadius: 0,
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppConstants.kSpaceLG,
                          vertical: AppConstants.kSpaceMD
                      ),
                      child: SafeArea(
                        top: false,
                        child: Row(
                          children: [
                            // Quantity Selector
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: AppColors.kGlassBorder),
                                borderRadius: BorderRadius.circular(AppConstants.kRadiusMD),
                              ),
                              child: Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove, size: 20),
                                    onPressed: product.stock > 0 ? _decrementQuantity : null,
                                  ),
                                  Text(
                                    '$_quantity',
                                    style: AppTextStyles.kHeading3,
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add, size: 20),
                                    onPressed: product.stock > 0 ? () => _incrementQuantity(product.stock) : null,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppConstants.kSpaceLG),

                            // Add to Cart Button
                            Expanded(
                              child: PrimaryButton(
                                label: 'Add to Cart',
                                icon: Icons.shopping_bag,
                                isLoading: false, // Will connect to CartBloc loading state in the future
                                onPressed: product.stock > 0
                                    ? () {
                                  // TODO: Dispatch Cart Event (Wired in Prompt 7)
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Added $_quantity to cart!')),
                                  );
                                }
                                    : null, // Disable if out of stock
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ).animate().slideY(begin: 1, duration: AppConstants.kAnimNormal, curve: Curves.easeOut),
                ],
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}