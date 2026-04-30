import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_constants.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/responsive_helper.dart';
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
  final PageController _pageController = PageController(viewportFraction: 0.9);
  Timer? _bannerTimer;

  final List<String> _categories = [
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

    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients) {
        int nextPage = _pageController.page!.round() + 1;
        if (nextPage > 2) nextPage = 0;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.fastOutSlowIn,
        );
      }
    });
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _pageController.dispose();
    super.dispose();
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

    // Dynamically grab horizontal padding based on screen size
    final responsivePad = ResponsiveHelper.responsivePadding(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: CustomAppBar(
        title: 'Home',
        showBackButton: false,
        actions: [
          // ✅ ADD THIS:
          CartBadgeWidget(
            onTap: () => context.push('/cart'),
            iconColor: AppColors.kTextPrimary,
          ),
          const SizedBox(width: AppConstants.kSpaceMD),
        ],
      ),
      body: MeshGradientBackground(
        child: RefreshIndicator(
          color: AppColors.kAccentIndigo,
          onRefresh: _onRefresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
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
                                'Good Morning,',
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
                                context.read<ProductBloc>().add(
                                  ProductsSearchChanged(value ?? ''),
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
                              context.read<ProductBloc>().add(
                                ProductsCategorySelected(
                                  category == 'All' ? null : category,
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

              // --- Featured Banner (Flipkart Style Horizontal Scroll) ---
              SliverToBoxAdapter(
                child: BlocBuilder<ProductBloc, ProductState>(
                  builder: (context, state) {
                    if (state is ProductsLoaded && state.products.isNotEmpty) {
                      // Grab up to 5 featured products
                      final featuredProducts = state.products.take(5).toList();

                      return SizedBox(
                        height: 200,
                        child: ListView.separated(
                          padding: EdgeInsets.symmetric(
                            horizontal: responsivePad.left,
                          ),
                          scrollDirection: Axis.horizontal,
                          itemCount: featuredProducts.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(width: 18),
                          itemBuilder: (context, index) {
                            return SizedBox(
                              width: 170,
                              child: ProductCardWidget(
                                product: featuredProducts[index],
                                onTap: () => context.push(
                                  '/shop/product/${featuredProducts[index].id}',
                                ),
                              ),
                            );
                          },
                        ),
                      ).animate().fadeIn(
                        delay: const Duration(milliseconds: 300),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),

              // --- Section Title ---
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: responsivePad.left,
                    vertical: AppConstants.kSpaceLG,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('New Arrivals', style: AppTextStyles.kHeading3),
                      TextButton(
                        onPressed: () => context.push('/shop'),
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
              ),

              // --- Products Responsive Grid / State Handling ---
              BlocBuilder<ProductBloc, ProductState>(
                builder: (context, state) {
                  if (state is ProductsLoading && state is! ProductsLoaded) {
                    // Shimmer Skeleton applied to ResponsiveGrid
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: responsivePad,
                        child: ResponsiveGridView(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          childAspectRatio: 0.65,
                          crossAxisSpacing: 10.0,
                          mainAxisSpacing: 10.0,
                          items: List.generate(4, (index) => index),
                          itemBuilder: (context, index, item) =>
                              const ShimmerProductCard(),
                        ),
                      ),
                    );
                  } else if (state is ProductError) {
                    // Beautiful Error State
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
                      // Beautiful Empty State
                      return SliverToBoxAdapter(
                        child: EmptyStateWidget.noProducts(
                          onAction: () => context.read<ProductBloc>().add(
                            const ProductsRefreshRequested(),
                          ),
                        ),
                      );
                    }

                    final gridProducts = state.products.skip(3).toList();

                    // Responsive Grid integrated
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: responsivePad,
                        child: ResponsiveGridView(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          childAspectRatio: 0.65,
                          crossAxisSpacing: 10.0,
                          mainAxisSpacing: 10.0,
                          items: gridProducts,
                          itemBuilder: (context, index, product) {
                            return ProductCardWidget(
                              product: product, // dynamic casting
                              onTap: () =>
                                  context.push('/product/${product.id}'),
                            );
                          },
                        ),
                      ),
                    );
                  }
                  return const SliverToBoxAdapter(child: SizedBox.shrink());
                },
              ),

              const SliverToBoxAdapter(
                child: SizedBox(height: AppConstants.kSpaceXXL),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
