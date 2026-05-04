import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_constants.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/app_extensions.dart';
import '../../../../shared/models/cart_model.dart';
import '../../../../shared/widgets/custom_app_bar_widget.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../shared/widgets/glass_container.dart';
import '../../../../shared/widgets/mesh_gradient_background.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../shared/widgets/responsive_builder_widget.dart';
import '../bloc/cart_bloc.dart';
import '../bloc/cart_event.dart';
import '../bloc/cart_state.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  void initState() {
    super.initState();
    final state = context.read<CartBloc>().state;
    if (state is! CartLoading) {
      context.read<CartBloc>().add(const CartFetchRequested());
    }
  }

  void _confirmClearCart(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.kGlassWhite,
        title: const Text('Clear Cart'),
        content: const Text(
          'Are you sure you want to remove all items from your cart?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: AppTextStyles.kBodyMedium),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<CartBloc>().add(const CartCleared());
            },
            child: Text(
              'Clear All',
              style: AppTextStyles.kBodyMedium.copyWith(
                color: AppColors.kError,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmRemoveItem(BuildContext context, String cartItemId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.kGlassWhite,
        title: const Text('Remove Item'),
        content: const Text('Are you sure you want to remove this item?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: AppTextStyles.kBodyMedium),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<CartBloc>().add(CartItemRemoved(cartItemId));
            },
            child: Text(
              'Remove',
              style: AppTextStyles.kBodyMedium.copyWith(
                color: AppColors.kError,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MeshGradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: CustomAppBar(
          title: 'My Cart',
          showBackButton: true,
          actions: [
            BlocBuilder<CartBloc, CartState>(
              builder: (context, state) {
                bool hasItems = false;

                if (state is CartLoaded) {
                  hasItems = state.cart.items.isNotEmpty;
                }

                if (state is CartUpdating) {
                  hasItems = state.cart.items.isNotEmpty;
                }

                if (hasItems) {
                  return IconButton(
                    icon: const Icon(
                      Icons.remove_shopping_cart_outlined,
                      color: AppColors.kError,
                    ),
                    onPressed: () => _confirmClearCart(context),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            const SizedBox(width: AppConstants.kSpaceMD),
          ],
        ),
        body: BlocConsumer<CartBloc, CartState>(
          listener: (context, state) {
            if (state is CartError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.kError,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is CartInitial ||
                (state is CartLoading && state is! CartUpdating)) {
              return const Center(
                child: CircularProgressIndicator(
                  color: AppColors.kAccentIndigo,
                ),
              );
            }

            if (state is CartError && state is! CartLoaded) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      state.message,
                      style: AppTextStyles.kBodyMedium.copyWith(
                        color: AppColors.kError,
                      ),
                    ),
                    const SizedBox(height: AppConstants.kSpaceMD),
                    ElevatedButton(
                      onPressed: () => context.read<CartBloc>().add(
                        const CartFetchRequested(),
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            CartModel? currentCart;
            bool isUpdating = false;

            if (state is CartLoaded) {
              currentCart = state.cart;
            } else if (state is CartUpdating) {
              currentCart = state.cart;
              isUpdating = true;
            }

            if ((currentCart == null || currentCart.isEmpty) && !isUpdating) {
              return EmptyStateWidget.emptyCart(
                onAction: () => context.go('/home'),
              );
            }

            if (currentCart == null) {
              return const Center(
                child: CircularProgressIndicator(
                  color: AppColors.kAccentIndigo,
                ),
              );
            }

            return ResponsiveBuilder(
              mobile: (context) => Column(
                children: [
                  if (isUpdating) _buildLoadingBar(),
                  Expanded(child: _buildCartList(context, currentCart!.items)),
                  _buildOrderSummary(
                    context,
                    currentCart.subtotal,
                    isMobile: true,
                  ),
                ],
              ),
              tablet: (context) => Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      children: [
                        if (isUpdating) _buildLoadingBar(),
                        Expanded(
                          child: _buildCartList(context, currentCart!.items),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.only(
                        top: AppConstants.kSpaceMD,
                        right: AppConstants.kSpaceLG,
                        bottom: AppConstants.kSpaceLG,
                      ),
                      child: SingleChildScrollView(
                        child: _buildOrderSummary(
                          context,
                          currentCart.subtotal,
                          isMobile: false,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoadingBar() {
    return const LinearProgressIndicator(
      minHeight: 3,
      backgroundColor: Colors.transparent,
      valueColor: AlwaysStoppedAnimation<Color>(AppColors.kAccentIndigo),
    );
  }

  Widget _buildCartList(BuildContext context, List<CartItemModel> items) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.kSpaceLG,
      ).copyWith(top: AppConstants.kSpaceMD, bottom: 100),
      itemCount: items.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppConstants.kSpaceMD),
      itemBuilder: (context, index) {
        return _buildCartItem(context, items[index]);
      },
    );
  }

  Widget _buildCartItem(BuildContext context, CartItemModel item) {
    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppConstants.kSpaceLG),
        decoration: BoxDecoration(
          color: AppColors.kError,
          borderRadius: BorderRadius.circular(AppConstants.kRadiusLG),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 32),
      ),
      confirmDismiss: (direction) async {
        _confirmRemoveItem(context, item.id);
        return false;
      },
      child: GlassContainer(
        padding: const EdgeInsets.all(AppConstants.kSpaceSM),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppConstants.kRadiusMD),
              child: SizedBox(
                width: 80,
                height: 80,
                child: (item.image.isEmpty)
                    ? Container(
                        color: AppColors.kGlassWhite,
                        child: const Icon(
                          Icons.sync,
                          color: AppColors.kAccentIndigo,
                        ),
                      )
                    : CachedNetworkImage(
                        imageUrl: item.image,
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            const Center(child: CircularProgressIndicator()),
                        errorWidget: (context, url, error) => Container(
                          color: AppColors.kGlassWhite,
                          child: const Icon(
                            Icons.image_not_supported,
                            color: AppColors.kTextSecondary,
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: AppConstants.kSpaceMD),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: AppTextStyles.kLabelLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.price.toCurrency(),
                    style: AppTextStyles.kBodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.kAccentIndigo,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildQuantityBtn(
                        icon: Icons.remove,
                        onTap: item.quantity > 1
                            ? () => context.read<CartBloc>().add(
                                CartItemQuantityUpdated(
                                  cartItemId: item.id,
                                  newQuantity: item.quantity - 1,
                                ),
                              )
                            : null,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppConstants.kSpaceMD,
                        ),
                        child: Text(
                          '${item.quantity}',
                          style: AppTextStyles.kBodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      _buildQuantityBtn(
                        icon: Icons.add,
                        onTap: item.quantity < item.stock
                            ? () => context.read<CartBloc>().add(
                                CartItemQuantityUpdated(
                                  cartItemId: item.id,
                                  newQuantity: item.quantity + 1,
                                ),
                              )
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                color: AppColors.kTextSecondary,
              ),
              onPressed: () => _confirmRemoveItem(context, item.id),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: AppConstants.kAnimFast).slideX(begin: 0.1);
  }

  Widget _buildQuantityBtn({
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: onTap == null
              ? Colors.grey.withValues(alpha: 0.2)
              : AppColors.kGlassWhite,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppColors.kGlassBorder),
        ),
        child: Icon(
          icon,
          size: 16,
          color: onTap == null ? Colors.grey : AppColors.kTextPrimary,
        ),
      ),
    );
  }

  Widget _buildOrderSummary(
    BuildContext context,
    double subtotal, {
    required bool isMobile,
  }) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: isMobile ? 85.0 : 0,
        left: isMobile ? 16.0 : 0,
        right: isMobile ? 16.0 : 0,
      ),
      child: GlassContainer(
        borderRadius: isMobile
            ? AppConstants.kRadiusXL
            : AppConstants.kRadiusXL,
        padding: const EdgeInsets.all(AppConstants.kSpaceLG),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Subtotal', style: AppTextStyles.kBodyMedium),
                  Text(
                    subtotal.toCurrency(),
                    style: AppTextStyles.kBodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.kSpaceSM),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Shipping', style: AppTextStyles.kBodyMedium),
                  Text(
                    'Calculated at checkout',
                    style: AppTextStyles.kLabelSmall.copyWith(
                      color: AppColors.kTextSecondary,
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppConstants.kSpaceSM),
                child: Divider(color: AppColors.kGlassBorder),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total', style: AppTextStyles.kHeading3),
                  Text(
                    subtotal.toCurrency(),
                    style: AppTextStyles.kHeading2.copyWith(
                      color: AppColors.kAccentIndigo,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.kSpaceLG),
              PrimaryButton(
                label: 'Proceed to Checkout',
                icon: Icons.payment,
                onPressed: () => context.push('/cart/checkout'),
              ),
            ],
          ),
        ),
      ),
    ).animate().slideY(
      begin: 1,
      duration: AppConstants.kAnimNormal,
      curve: Curves.easeOut,
    );
  }
}
