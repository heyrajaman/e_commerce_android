import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_constants.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../../shared/models/product_model.dart';
import '../../../../shared/widgets/cart_badge_widget.dart';
import '../../../../shared/widgets/category_chip_widget.dart';
import '../../../../shared/widgets/custom_app_bar_widget.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../shared/widgets/error_state_widget.dart';
import '../../../../shared/widgets/mesh_gradient_background.dart';
import '../../../../shared/widgets/product_card_widget.dart';
import '../../../../shared/widgets/responsive_builder_widget.dart';
import '../../../../shared/widgets/shimmer_loader_widget.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../shop/presentation/bloc/product_bloc.dart';
import '../../../shop/presentation/bloc/product_event.dart';
import '../../../shop/presentation/bloc/product_state.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _formKey = GlobalKey<FormBuilderState>();

  static const List<String> _categories = [
    'All',
    'Electronics',
    'Clothing',
    'Shoes',
    'Accessories',
  ];

  @override
  void initState() {
    super.initState();
    final productBloc = context.read<ProductBloc>();
    if (productBloc.state is ProductInitial) {
      productBloc.add(const ProductsFetchRequested());
    }
  }

  Future<void> _onRefresh() async {
    context.read<ProductBloc>().add(const ProductsRefreshRequested());
    await Future.delayed(const Duration(seconds: 1));
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final userName = authState is AuthAuthenticated
        ? authState.user.name
        : 'Guest';

    final responsivePad = ResponsiveHelper.responsivePadding(context);
    const double cardAspectRatio = 170 / 200;

    return MeshGradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: CustomAppBar(
          title: 'Home',
          showBackButton: false,
          actions: [
            CartBadgeWidget(
              onTap: () => context.pushNamed('cart'),
              iconColor: AppColors.kTextPrimary,
            ),
            const SizedBox(width: AppConstants.kSpaceMD),
          ],
        ),
        body: RefreshIndicator(
          color: AppColors.kAccentIndigo,
          onRefresh: _onRefresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              // --- Greeting ---
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: responsivePad.left,
                    right: responsivePad.right,
                    top: AppConstants.kSpaceLG,
                    bottom: AppConstants.kSpaceMD,
                  ),
                  child:
                      Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome,',
                                style: AppTextStyles.kBodyMedium.copyWith(
                                  color: AppColors.kTextSecondary,
                                ),
                              ),
                              Text(userName, style: AppTextStyles.kHeading2),
                            ],
                          )
                          .animate()
                          .fadeIn(duration: AppConstants.kAnimNormal)
                          .slideX(begin: -0.1),
                ),
              ),

              // --- Search Bar ---
              SliverToBoxAdapter(
                child:
                    Padding(
                          padding: responsivePad,
                          child: FormBuilder(
                            key: _formKey,
                            child: CustomTextField(
                              name: 'search',
                              label: '',
                              hint: 'Search products...',
                              prefixIcon: Icons.search,
                              onChanged: (value) {
                                // PROD COMPILE FIX: Switched to named parameter
                                context.read<ProductBloc>().add(
                                  ProductsSearchChanged(query: value ?? ''),
                                );
                              },
                            ),
                          ),
                        )
                        .animate()
                        .fadeIn(delay: const Duration(milliseconds: 100))
                        .slideY(begin: 0.1),
              ),

              // --- Categories List ---
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 80,
                  child: BlocBuilder<ProductBloc, ProductState>(
                    builder: (context, state) {
                      String activeCategory = 'All';
                      if (state is ProductsLoaded &&
                          state.activeCategory != null) {
                        activeCategory = state.activeCategory!;
                      }

                      return ListView.separated(
                        padding: EdgeInsets.symmetric(
                          horizontal: responsivePad.left,
                          vertical: AppConstants.kSpaceMD,
                        ),
                        scrollDirection: Axis.horizontal,
                        itemCount: _categories.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(width: AppConstants.kSpaceSM),
                        itemBuilder: (context, index) {
                          final category = _categories[index];
                          return CategoryChipWidget(
                            label: category,
                            isSelected: activeCategory == category,
                            onTap: () {
                              // PROD COMPILE FIX: Switched to named parameter
                              context.read<ProductBloc>().add(
                                ProductsCategorySelected(
                                  category: category == 'All' ? null : category,
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ).animate().fadeIn(delay: const Duration(milliseconds: 200)),
              ),

              // --- Products Sections ---
              BlocBuilder<ProductBloc, ProductState>(
                builder: (context, state) {
                  if (state is ProductsLoading && state is! ProductsLoaded) {
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: responsivePad,
                        child: ResponsiveGridView(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          childAspectRatio: cardAspectRatio,
                          crossAxisSpacing: 10.0,
                          mainAxisSpacing: 10.0,
                          items: List.generate(4, (index) => index),
                          itemBuilder: (context, index, item) =>
                              const ShimmerProductCard(),
                        ),
                      ),
                    );
                  } else if (state is ProductError) {
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: responsivePad,
                        child: ErrorStateWidget(
                          message: state.message,
                          onRetry: () => context.read<ProductBloc>().add(
                            const ProductsRefreshRequested(),
                          ),
                        ),
                      ),
                    );
                  } else if (state is ProductsLoaded) {
                    if (state.products.isEmpty) {
                      return SliverToBoxAdapter(
                        child: EmptyStateWidget.noProducts(
                          onAction: () => context.read<ProductBloc>().add(
                            const ProductsRefreshRequested(),
                          ),
                        ),
                      );
                    }

                    final bool isSearching =
                        state.searchQuery != null &&
                        state.searchQuery!.trim().isNotEmpty;

                    if (isSearching) {
                      return SliverList(
                        delegate: SliverChildListDelegate([
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: responsivePad.left,
                              vertical: AppConstants.kSpaceLG,
                            ),
                            child: Text(
                              'Search Results',
                              style: AppTextStyles.kHeading3,
                            ),
                          ),
                          Padding(
                            padding: responsivePad,
                            child: ResponsiveGridView(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              childAspectRatio: cardAspectRatio,
                              crossAxisSpacing: 10.0,
                              mainAxisSpacing: 10.0,
                              items: state.products,
                              itemBuilder: (context, index, product) {
                                return ProductCardWidget(
                                  product: product,
                                  onTap: () => context.pushNamed(
                                    'product_details',
                                    pathParameters: {'id': product.id},
                                  ),
                                );
                              },
                            ),
                          ),
                        ]),
                      );
                    }

                    final newArrivalProducts = state.products;
                    final featuredProducts = state.products.length > 5
                        ? state.products.skip(5).take(5).toList()
                        : state.products.take(5).toList();
                    final recentProducts = state.products.reversed
                        .take(5)
                        .toList();

                    return SliverList(
                      delegate: SliverChildListDelegate([
                        if (recentProducts.isNotEmpty)
                          _buildHorizontalSection(
                            context: context,
                            title: 'Recently Viewed',
                            products: recentProducts,
                            responsivePad: responsivePad,
                          ),

                        if (recentProducts.isNotEmpty &&
                            featuredProducts.isNotEmpty)
                          const SizedBox(height: AppConstants.kSpaceMD),

                        if (featuredProducts.isNotEmpty)
                          _buildHorizontalSection(
                            context: context,
                            title: 'Featured Collections',
                            products: featuredProducts,
                            responsivePad: responsivePad,
                          ),

                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: responsivePad.left,
                            vertical: AppConstants.kSpaceLG,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'New Arrivals',
                                style: AppTextStyles.kHeading3,
                              ),
                              TextButton(
                                onPressed: () => context.pushNamed('shop'),
                                child: Text(
                                  'View All',
                                  style: AppTextStyles.kButtonText.copyWith(
                                    color: AppColors.kAccentIndigo,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        Padding(
                          padding: responsivePad,
                          child: ResponsiveGridView(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            childAspectRatio: cardAspectRatio,
                            crossAxisSpacing: 10.0,
                            mainAxisSpacing: 10.0,
                            items: newArrivalProducts,
                            itemBuilder: (context, index, product) {
                              return ProductCardWidget(
                                product: product,
                                onTap: () => context.pushNamed(
                                  'product_details',
                                  pathParameters: {'id': product.id},
                                ),
                              );
                            },
                          ),
                        ),
                      ]),
                    );
                  }
                  return const SliverToBoxAdapter(child: SizedBox.shrink());
                },
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHorizontalSection({
    required BuildContext context,
    required String title,
    required List<ProductModel> products,
    required EdgeInsets responsivePad,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: responsivePad.left,
            vertical: AppConstants.kSpaceSM,
          ).copyWith(top: AppConstants.kSpaceLG),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: AppTextStyles.kHeading3),
              TextButton(
                onPressed: () => context.pushNamed('shop'),
                child: Text(
                  'View All',
                  style: AppTextStyles.kButtonText.copyWith(
                    color: AppColors.kAccentIndigo,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 200,
          child: ListView.separated(
            padding: EdgeInsets.symmetric(horizontal: responsivePad.left),
            scrollDirection: Axis.horizontal,
            itemCount: products.length,
            separatorBuilder: (context, index) => const SizedBox(width: 18),
            itemBuilder: (context, index) {
              final product = products[index];
              return SizedBox(
                width: 170,
                child: ProductCardWidget(
                  product: product,
                  onTap: () => context.pushNamed(
                    'product_details',
                    pathParameters: {'id': product.id},
                  ),
                ),
              );
            },
          ),
        ),
      ],
    ).animate().fadeIn(delay: const Duration(milliseconds: 300));
  }
}
