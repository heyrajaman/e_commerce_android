import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/theme/app_colors.dart';
import '../../features/cart/presentation/bloc/cart_bloc.dart';
import '../../features/cart/presentation/bloc/cart_state.dart';

class CartBadgeWidget extends StatelessWidget {
  final VoidCallback onTap;
  final Color? iconColor;

  const CartBadgeWidget({super.key, required this.onTap, this.iconColor});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CartBloc, CartState>(
      builder: (context, state) {
        int itemCount = 0;

        // Extract item count from loaded or updating states
        if (state is CartLoaded) {
          itemCount = state.cart.totalItems;
        } else if (state is CartUpdating) {
          itemCount = state.cart.totalItems;
        }

        return Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: Icon(
                Icons.shopping_cart_outlined,
                color: iconColor ?? AppColors.kTextPrimary,
                size: 28,
              ),
              onPressed: onTap,
            ),

            // Only show the badge if there are items in the cart
            if (itemCount > 0)
              Positioned(
                right: 4,
                top: 4,
                child:
                    Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red, // Bright red for high visibility
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 20,
                            minHeight: 20,
                          ),
                          child: Center(
                            child: Text(
                              itemCount > 99 ? '99+' : '$itemCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                        // The ValueKey ensures the animation re-runs every time the count changes!
                        .animate(key: ValueKey(itemCount))
                        .scale(
                          begin: const Offset(0.3, 0.3),
                          end: const Offset(1.0, 1.0),
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.elasticOut,
                        ),
              ),
          ],
        );
      },
    );
  }
}
