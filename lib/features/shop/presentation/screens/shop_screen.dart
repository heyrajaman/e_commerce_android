import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_constants.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../../shared/models/product_model.dart';
import '../../../../shared/widgets/custom_app_bar_widget.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../shared/widgets/error_state_widget.dart';
import '../../../../shared/widgets/glass_container.dart';
import '../../../../shared/widgets/mesh_gradient_background.dart';
import '../../../../shared/widgets/product_card_widget.dart';
import '../../../../shared/widgets/responsive_builder_widget.dart';
import '../../../../shared/widgets/shimmer_loader_widget.dart';
import '../bloc/product_bloc.dart';
import '../bloc/product_event.dart';
import '../bloc/product_state.dart';

enum SortOption { none, priceLowToHigh, priceHighToLow }

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  final ScrollController _scrollController = ScrollController();

  int _currentPage = 1;
  bool _isFetchingMore = false;
  SortOption _currentSort = SortOption.none;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    final productBloc = context.read<ProductBloc>();

    productBloc.add(const CategoriesFetchRequested());

    if (productBloc.state is ProductInitial) {
      productBloc.add(const ProductsFetchRequested(page: 1));
    } else if (productBloc.state is ProductsLoaded) {
      _currentPage =
          ((productBloc.state as ProductsLoaded).products.length / 10).ceil();
      if (_currentPage == 0) _currentPage = 1;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final state = context.read<ProductBloc>().state;
      if (state is ProductsLoaded && state.hasMore && !_isFetchingMore) {
        setState(() {
          _isFetchingMore = true;
          _currentPage++;
        });

        context.read<ProductBloc>().add(
          ProductsFetchRequested(
            category: state.activeCategory,
            search: state.searchQuery,
            page: _currentPage,
          ),
        );
      }
    }
  }

  List<ProductModel> _getSortedProducts(List<ProductModel> products) {
    if (_currentSort == SortOption.none) return products;

    final sortedList = List<ProductModel>.from(products);
    sortedList.sort((a, b) {
      if (_currentSort == SortOption.priceLowToHigh) {
        return a.effectivePrice.compareTo(b.effectivePrice);
      } else {
        return b.effectivePrice.compareTo(a.effectivePrice);
      }
    });
    return sortedList;
  }

  @override
  Widget build(BuildContext context) {
    final responsivePad = ResponsiveHelper.responsivePadding(context);

    return MeshGradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: const CustomAppBar(title: 'Shop', showBackButton: true),
        // SONARQUBE FIX: Replaced MultiBlocListener with a single BlocListener
        body: BlocListener<ProductBloc, ProductState>(
          listener: (context, state) {
            if (state is ProductsLoaded || state is ProductError) {
              setState(() => _isFetchingMore = false);
            }
          },
          child: RefreshIndicator(
            color: AppColors.kAccentIndigo,
            onRefresh: () async {
              setState(() {
                _currentPage = 1;
                _isFetchingMore = false;
              });
              context.read<ProductBloc>().add(const ProductsRefreshRequested());
              await Future.delayed(const Duration(seconds: 1));
            },
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  // --- Filter and Sort Bar ---
                  Padding(
                        padding: responsivePad.copyWith(
                          top: AppConstants.kSpaceSM,
                          bottom: AppConstants.kSpaceSM,
                        ),
                        child: GlassContainer(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppConstants.kSpaceMD,
                            vertical: 8,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: BlocBuilder<ProductBloc, ProductState>(
                                  builder: (context, state) {
                                    String activeCategory = 'All';
                                    List<String> dynamicCategories = ['All'];

                                    if (state is ProductsLoaded) {
                                      if (state.activeCategory != null) {
                                        activeCategory = state.activeCategory!;
                                      }
                                      dynamicCategories = state.categories;
                                    }

                                    if (!dynamicCategories.contains(
                                      activeCategory,
                                    )) {
                                      dynamicCategories.insert(
                                        0,
                                        activeCategory,
                                      );
                                    }

                                    return DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        isExpanded: true,
                                        value: activeCategory,
                                        icon: const Icon(
                                          Icons.keyboard_arrow_down,
                                          color: AppColors.kTextSecondary,
                                        ),
                                        style: AppTextStyles.kBodyMedium
                                            .copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                        dropdownColor: AppColors.kGlassWhite,
                                        items: dynamicCategories.map((
                                          String value,
                                        ) {
                                          return DropdownMenuItem<String>(
                                            value: value,
                                            child: Text(
                                              value,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          );
                                        }).toList(),
                                        onChanged: (newValue) {
                                          if (newValue != null) {
                                            setState(() {
                                              _currentPage = 1;
                                              _isFetchingMore = false;
                                            });
                                            // PROD COMPILE FIX: Switched to named parameter
                                            context.read<ProductBloc>().add(
                                              ProductsCategorySelected(
                                                category: newValue == 'All'
                                                    ? null
                                                    : newValue,
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                    );
                                  },
                                ),
                              ),

                              const SizedBox(width: 12),

                              Expanded(
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<SortOption>(
                                    isExpanded: true,
                                    value: _currentSort,
                                    icon: const Icon(
                                      Icons.sort,
                                      color: AppColors.kTextSecondary,
                                    ),
                                    style: AppTextStyles.kBodyMedium.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                    dropdownColor: AppColors.kGlassWhite,
                                    items: const [
                                      DropdownMenuItem(
                                        value: SortOption.none,
                                        child: Text(
                                          'Sort: Default',
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      DropdownMenuItem(
                                        value: SortOption.priceLowToHigh,
                                        child: Text(
                                          'Price: Low to High',
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      DropdownMenuItem(
                                        value: SortOption.priceHighToLow,
                                        child: Text(
                                          'Price: High to Low',
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                    onChanged: (newValue) {
                                      if (newValue != null) {
                                        setState(() => _currentSort = newValue);
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .animate()
                      .fadeIn(duration: AppConstants.kAnimNormal)
                      .slideY(begin: -0.2),

                  // --- Product Count ---
                  BlocBuilder<ProductBloc, ProductState>(
                    builder: (context, state) {
                      if (state is ProductsLoaded) {
                        return Padding(
                          padding: responsivePad.copyWith(
                            bottom: AppConstants.kSpaceSM,
                          ),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Showing ${state.products.length} products',
                              style: AppTextStyles.kLabelSmall.copyWith(
                                color: AppColors.kTextSecondary,
                              ),
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),

                  // --- Main Content Area ---
                  BlocBuilder<ProductBloc, ProductState>(
                    builder: (context, state) {
                      if (state is ProductInitial ||
                          (state is ProductsLoading && !_isFetchingMore)) {
                        return Padding(
                          padding: responsivePad,
                          child: ResponsiveGridView(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            items: List.generate(6, (index) => index),
                            itemBuilder: (context, index, item) =>
                                const ShimmerProductCard(),
                          ),
                        );
                      } else if (state is ProductError) {
                        return Padding(
                          padding: responsivePad.copyWith(
                            top: AppConstants.kSpaceXL,
                          ),
                          child: ErrorStateWidget(
                            message: state.message,
                            onRetry: () {
                              setState(() => _currentPage = 1);
                              context.read<ProductBloc>().add(
                                const ProductsRefreshRequested(),
                              );
                            },
                          ),
                        );
                      } else if (state is ProductsLoaded) {
                        if (state.products.isEmpty) {
                          return Padding(
                            padding: responsivePad.copyWith(
                              top: AppConstants.kSpaceXL,
                            ),
                            child: EmptyStateWidget.noProducts(
                              onAction: () {
                                setState(() => _currentPage = 1);
                                context.read<ProductBloc>().add(
                                  const ProductsRefreshRequested(),
                                );
                              },
                            ),
                          );
                        }

                        final sortedProducts = _getSortedProducts(
                          state.products,
                        );

                        final List<dynamic> gridItems = List.from(
                          sortedProducts,
                        );
                        if (state.hasMore && _isFetchingMore) {
                          int placeholders = ResponsiveHelper.isDesktop(context)
                              ? 4
                              : ResponsiveHelper.isTablet(context)
                              ? 3
                              : 2;
                          gridItems.addAll(
                            List.filled(placeholders, 'loading_shimmer'),
                          );
                        }

                        return Padding(
                          padding: responsivePad.copyWith(bottom: 100),
                          child: ResponsiveGridView(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            items: gridItems,
                            itemBuilder: (context, index, item) {
                              if (item == 'loading_shimmer') {
                                return const ShimmerProductCard()
                                    .animate()
                                    .fadeIn();
                              }

                              final product = item as ProductModel;
                              return ProductCardWidget(
                                product: product,
                                // PROD ROUTING FIX: Safe named route usage
                                onTap: () => context.pushNamed(
                                  'product_details',
                                  pathParameters: {'id': product.id},
                                ),
                              );
                            },
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
