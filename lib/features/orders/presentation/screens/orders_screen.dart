import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_constants.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../../shared/models/order_model.dart';
import '../../../../shared/widgets/custom_app_bar_widget.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../shared/widgets/error_state_widget.dart';
import '../../../../shared/widgets/glass_container.dart';
import '../../../../shared/widgets/mesh_gradient_background.dart';
import '../../../../shared/widgets/order_card_widget.dart';
import '../../../../shared/widgets/responsive_builder_widget.dart';
import '../../../../shared/widgets/shimmer_loader_widget.dart';
import '../bloc/order_bloc.dart';
import '../bloc/order_event.dart';
import '../bloc/order_state.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final List<String> _tabs = ['All', 'Pending', 'Shipped', 'Delivered', 'Cancelled'];

  @override
  void initState() {
    super.initState();
    context.read<OrderBloc>().add(const OrdersFetchRequested());
  }

  List<OrderModel> _getFilteredOrders(List<OrderModel> allOrders, int tabIndex) {
    if (tabIndex == 0) return allOrders;

    return allOrders.where((order) {
      if (tabIndex == 1) {
        return order.status == OrderStatus.pending || order.status == OrderStatus.confirmed;
      } else if (tabIndex == 2) {
        return order.status == OrderStatus.shipped;
      } else if (tabIndex == 3) {
        return order.status == OrderStatus.delivered;
      } else if (tabIndex == 4) {
        return order.status == OrderStatus.cancelled;
      }
      return false;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final responsivePad = ResponsiveHelper.responsivePadding(context);

    return MeshGradientBackground(
      child: DefaultTabController(
        length: _tabs.length,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: const CustomAppBar(
            title: 'My Orders',
            showBackButton: true,
          ),
          body: Column(
            children: [
              // --- Glassmorphism Tab Bar ---
              Padding(
                padding: responsivePad.copyWith(top: AppConstants.kSpaceSM, bottom: AppConstants.kSpaceMD),
                child: GlassContainer(
                  padding: EdgeInsets.zero,
                  borderRadius: AppConstants.kRadiusLG,
                  child: TabBar(
                    isScrollable: true,
                    dividerColor: Colors.transparent,
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicator: BoxDecoration(
                      color: AppColors.kAccentIndigo.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppConstants.kRadiusLG),
                      border: Border.all(color: AppColors.kAccentIndigo.withValues(alpha: 0.3)),
                    ),
                    labelColor: AppColors.kAccentIndigo,
                    unselectedLabelColor: AppColors.kTextSecondary,
                    labelStyle: AppTextStyles.kLabelLarge.copyWith(fontWeight: FontWeight.bold),
                    tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
                  ),
                ),
              ),

              // --- Main Content Area ---
              Expanded(
                child: BlocConsumer<OrderBloc, OrderState>(
                  listener: (context, state) {},
                  builder: (context, state) {
                    if (state is OrderInitial || state is OrdersLoading) {
                      // Integrated Shimmer Skeleton
                      return Padding(
                        padding: responsivePad,
                        child: ResponsiveGridView(
                          items: List.generate(6, (index) => index),
                          itemBuilder: (context, index, item) => const ShimmerOrderCard(),
                        ),
                      );
                    } else if (state is OrderError) {
                      // Integrated Error State Widget
                      return Padding(
                        padding: responsivePad,
                        child: ErrorStateWidget(
                          message: state.message,
                          onRetry: () => context.read<OrderBloc>().add(const OrdersFetchRequested()),
                        ),
                      );
                    } else if (state is OrdersLoaded || state is OrderCancelling) {

                      List<OrderModel> orders = [];
                      if (state is OrdersLoaded) orders = state.orders;
                      if (state is OrderCancelling) {
                        orders = context.read<OrderBloc>().state is OrdersLoaded
                            ? (context.read<OrderBloc>().state as OrdersLoaded).orders
                            : [];
                      }

                      if (orders.isEmpty) {
                        // Integrated Empty State Widget
                        return EmptyStateWidget.noOrders(
                          onAction: () => context.go('/shop'),
                        );
                      }

                      return TabBarView(
                        children: List.generate(_tabs.length, (index) {
                          final filteredOrders = _getFilteredOrders(orders, index);

                          if (filteredOrders.isEmpty) {
                            return Center(
                              child: Text(
                                'No ${_tabs[index].toLowerCase()} orders.',
                                style: AppTextStyles.kBodyMedium.copyWith(color: AppColors.kTextSecondary),
                              ),
                            ).animate().fadeIn();
                          }

                          return RefreshIndicator(
                            color: AppColors.kAccentIndigo,
                            onRefresh: () async {
                              context.read<OrderBloc>().add(const OrdersRefreshRequested());
                              await Future.delayed(const Duration(seconds: 1));
                            },
                            // Integrated ResponsiveGridView to prevent stretched cards on tablets/desktops
                            child: SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: responsivePad.copyWith(bottom: AppConstants.kSpaceXXL),
                              child: ResponsiveGridView(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                items: filteredOrders,
                                itemBuilder: (context, idx, item) {
                                  final order = item;
                                  return OrderCardWidget(
                                    order: order,
                                    onTap: () => context.push('/orders/${order.id}'),
                                  );
                                },
                              ),
                            ),
                          );
                        }),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}