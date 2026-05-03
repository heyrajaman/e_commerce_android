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
  final List<String> _tabs = [
    'All',
    'Pending',
    'Shipped',
    'Delivered',
    'Cancelled',
    'Returned',
  ];

  @override
  void initState() {
    super.initState();
    context.read<OrderBloc>().add(const OrdersFetchRequested());
  }

  List<OrderModel> _getFilteredOrders(
    List<OrderModel> allOrders,
    int tabIndex,
  ) {
    if (tabIndex == 0) return allOrders;

    return allOrders.where((order) {
      if (tabIndex == 1) {
        return order.status == OrderStatus.pending ||
            order.status == OrderStatus.confirmed;
      } else if (tabIndex == 2) {
        return order.status == OrderStatus.shipped;
      } else if (tabIndex == 3) {
        return order.status == OrderStatus.delivered;
      } else if (tabIndex == 4) {
        return order.status == OrderStatus.cancelled;
      } else if (tabIndex == 5) {
        return order.status == OrderStatus.returned;
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
          appBar: const CustomAppBar(title: 'My Orders', showBackButton: true),
          body: Column(
            children: [
              // --- Tab Bar ---
              Padding(
                padding: responsivePad.copyWith(
                  top: AppConstants.kSpaceSM,
                  bottom: AppConstants.kSpaceMD,
                ),
                child: GlassContainer(
                  padding: EdgeInsets.zero,
                  borderRadius: AppConstants.kRadiusLG,
                  child: TabBar(
                    isScrollable: true,
                    dividerColor: Colors.transparent,
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicator: BoxDecoration(
                      color: AppColors.kAccentIndigo.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(
                        AppConstants.kRadiusLG,
                      ),
                      border: Border.all(
                        color: AppColors.kAccentIndigo.withValues(alpha: 0.3),
                      ),
                    ),
                    labelColor: AppColors.kAccentIndigo,
                    unselectedLabelColor: AppColors.kTextSecondary,
                    labelStyle: AppTextStyles.kLabelLarge.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
                  ),
                ),
              ),

              // --- Main Content Area ---
              Expanded(
                child: BlocConsumer<OrderBloc, OrderState>(
                  listener: (context, state) {},
                  builder: (context, state) {
                    List<OrderModel> orders = [];
                    bool hasReachedMax = true;

                    // Access the current state from the BLoC directly
                    final currentBlocState = context.read<OrderBloc>().state;

                    if (state is OrdersLoaded) {
                      orders = state.orders;
                      hasReachedMax = state.hasReachedMax;
                    } else if (currentBlocState is OrdersLoaded) {
                      orders = currentBlocState.orders;
                      hasReachedMax = currentBlocState.hasReachedMax;
                    }

                    if ((state is OrdersLoading || state is OrderInitial) &&
                        orders.isEmpty) {
                      return ListView.builder(
                        padding: responsivePad,
                        itemCount: 6,
                        itemBuilder: (context, index) =>
                            const ShimmerOrderCard(),
                      );
                    }

                    // Handle Error (only if we have no data to show)
                    if (state is OrderError && orders.isEmpty) {
                      return ErrorStateWidget(message: state.message);
                    }

                    if (orders.isEmpty && state is! OrdersLoading) {
                      return EmptyStateWidget.noOrders(
                        onAction: () => context.go('/shop'),
                      );
                    }

                    return TabBarView(
                      children: List.generate(_tabs.length, (index) {
                        final filteredOrders = _getFilteredOrders(
                          orders,
                          index,
                        );

                        if (filteredOrders.isEmpty) {
                          return Center(
                            child: Text(
                              'No ${_tabs[index].toLowerCase()} orders.',
                              style: AppTextStyles.kBodyMedium.copyWith(
                                color: AppColors.kTextSecondary,
                              ),
                            ),
                          ).animate().fadeIn();
                        }

                        return RefreshIndicator(
                          color: AppColors.kAccentIndigo,
                          onRefresh: () async {
                            final refreshFuture = context
                                .read<OrderBloc>()
                                .stream
                                .firstWhere(
                                  (state) =>
                                      state is OrdersLoaded ||
                                      state is OrderError,
                                );

                            context.read<OrderBloc>().add(
                              const OrdersRefreshRequested(),
                            );
                            await Future.wait([
                              refreshFuture,
                              Future.delayed(const Duration(seconds: 1)),
                            ]);
                          },
                          child: NotificationListener<ScrollNotification>(
                            onNotification: (ScrollNotification scrollInfo) {
                              if (!hasReachedMax &&
                                  scrollInfo.metrics.pixels >=
                                      scrollInfo.metrics.maxScrollExtent *
                                          0.9) {
                                context.read<OrderBloc>().add(
                                  const OrdersLoadMoreRequested(),
                                );
                              }
                              return false;
                            },
                            child: ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: responsivePad.copyWith(
                                bottom: AppConstants.kSpaceXXL,
                              ),
                              itemCount:
                                  filteredOrders.length +
                                  (hasReachedMax ? 0 : 1),
                              itemBuilder: (context, idx) {
                                if (idx >= filteredOrders.length) {
                                  return const Center(
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: AppConstants.kSpaceLG,
                                      ),
                                      child: CircularProgressIndicator(
                                        color: AppColors.kAccentIndigo,
                                      ),
                                    ),
                                  );
                                }

                                final order = filteredOrders[idx];
                                return OrderCardWidget(
                                  order: order,
                                  onTap: () {
                                    // 🟢 Navigate and refresh list upon return
                                    context.push('/orders/${order.id}').then((
                                      _,
                                    ) {
                                      if (context.mounted) {
                                        context.read<OrderBloc>().add(
                                          const OrdersFetchRequested(),
                                        );
                                      }
                                    });
                                  },
                                );
                              },
                            ),
                          ),
                        );
                      }),
                    );
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
