import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_constants.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/app_extensions.dart';
import '../../../../core/utils/app_validators.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../../shared/widgets/custom_app_bar_widget.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../../shared/widgets/glass_container.dart';
import '../../../../shared/widgets/loading_overlay_widget.dart';
import '../../../../shared/widgets/mesh_gradient_background.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../shared/widgets/responsive_builder_widget.dart';
import '../../../cart/presentation/bloc/cart_bloc.dart';
import '../../../cart/presentation/bloc/cart_event.dart';
import '../../../cart/presentation/bloc/cart_state.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final PageController _pageController = PageController();
  final _formKey = GlobalKey<FormBuilderState>();

  int _currentStep = 0;
  String _selectedPaymentMethod = 'COD';
  bool _isPlacingOrder = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      setState(() => _currentStep = 1);
      _pageController.nextPage(
        duration: AppConstants.kAnimNormal,
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _placeOrder() async {
    // Validate form (Crucial for desktop layout since they don't click "Next Step")
    if (!(_formKey.currentState?.saveAndValidate() ?? false)) {
      Fluttertoast.showToast(
        msg: 'Please check your shipping details.',
        backgroundColor: AppColors.kError,
        textColor: Colors.white,
      );
      return;
    }

    final cartState = context.read<CartBloc>().state;
    if (cartState is! CartLoaded) return;

    setState(() => _isPlacingOrder = true);

    try {
      final addressData = _formKey.currentState!.value;
      final cart = cartState.cart;

      final shippingCost = cart.subtotal > 100 ? 0.0 : 10.0;
      final totalAmount = cart.subtotal + shippingCost;

      final payload = {
        'shippingAddress': addressData,
        'paymentMethod': _selectedPaymentMethod,
        'items': cart.items.map((item) => {
          'productId': item.productId,
          'quantity': item.quantity,
          'price': item.price,
        }).toList(),
        'totalAmount': totalAmount,
      };

      final response = await GetIt.I<ApiClient>().dio.post(
        '/api/orders/checkout',
        data: payload,
      );

      final orderId = response.data['order']['_id'] ?? response.data['order']['id'] ?? 'UNKNOWN_ID';

      if (mounted) {
        context.read<CartBloc>().add(const CartCleared());
        context.go('/order-success/$orderId');
      }

    } on DioException catch (e) {
      Fluttertoast.showToast(
        msg: e.response?.data['message'] ?? 'Failed to place order',
        backgroundColor: AppColors.kError,
        textColor: Colors.white,
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'An unexpected error occurred',
        backgroundColor: AppColors.kError,
        textColor: Colors.white,
      );
    } finally {
      if (mounted) {
        setState(() => _isPlacingOrder = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MeshGradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: const CustomAppBar(
          title: 'Checkout',
          showBackButton: true,
        ),
        body: LoadingOverlay(
          isLoading: _isPlacingOrder,
          message: 'Processing Order...',
          child: ResponsiveBuilder(
            mobile: (context) => Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppConstants.kSpaceMD),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildStepIndicator(0, 'Shipping', Icons.local_shipping_outlined),
                      Container(width: 40, height: 2, color: _currentStep >= 1 ? AppColors.kAccentIndigo : AppColors.kGlassBorder),
                      _buildStepIndicator(1, 'Payment', Icons.payment_outlined),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildShippingStep(isMobile: true),
                      _buildPaymentStep(isMobile: true),
                    ],
                  ),
                ),
              ],
            ),
            tablet: (context) {
              final responsivePad = ResponsiveHelper.responsivePadding(context);
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: SingleChildScrollView(
                      padding: EdgeInsets.only(left: responsivePad.left, right: AppConstants.kSpaceMD, top: AppConstants.kSpaceLG, bottom: AppConstants.kSpaceXXL),
                      child: _buildShippingStep(isMobile: false),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: SingleChildScrollView(
                      padding: EdgeInsets.only(left: AppConstants.kSpaceMD, right: responsivePad.right, top: AppConstants.kSpaceLG, bottom: AppConstants.kSpaceXXL),
                      child: _buildPaymentStep(isMobile: false),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator(int stepIndex, String title, IconData icon) {
    final isActive = _currentStep >= stepIndex;
    return GestureDetector(
      onTap: () {
        if (stepIndex == 0 && _currentStep == 1) {
          setState(() => _currentStep = 0);
          _pageController.previousPage(duration: AppConstants.kAnimNormal, curve: Curves.easeInOut);
        }
      },
      child: Column(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: isActive ? AppColors.kAccentIndigo : AppColors.kGlassWhite,
            child: Icon(
              icon,
              color: isActive ? Colors.white : AppColors.kTextSecondary,
              size: 20,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: AppTextStyles.kLabelSmall.copyWith(
              color: isActive ? AppColors.kTextPrimary : AppColors.kTextSecondary,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShippingStep({required bool isMobile}) {
    return FormBuilder(
      key: _formKey,
      child: GlassContainer(
        padding: const EdgeInsets.all(AppConstants.kSpaceLG),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Shipping Details', style: AppTextStyles.kHeading3),
            const SizedBox(height: AppConstants.kSpaceLG),

            CustomTextField(
              name: 'fullName',
              label: 'Full Name',
              hint: 'Aman Singh',
              validator: AppValidators.name(),
            ),
            const SizedBox(height: AppConstants.kSpaceMD),

            CustomTextField(
              name: 'phone',
              label: 'Phone Number',
              hint: '9876543210',
              keyboardType: TextInputType.phone,
              validator: AppValidators.phone(),
            ),
            const SizedBox(height: AppConstants.kSpaceMD),

            CustomTextField(
              name: 'addressLine1',
              label: 'Address Line 1',
              hint: 'Street, House No.',
              validator: AppValidators.requiredField('Address'),
            ),
            const SizedBox(height: AppConstants.kSpaceMD),

            CustomTextField(
              name: 'addressLine2',
              label: 'Address Line 2 (Optional)',
              hint: 'Apartment, Suite, etc.',
            ),
            const SizedBox(height: AppConstants.kSpaceMD),

            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    name: 'city',
                    label: 'City',
                    validator: AppValidators.requiredField('City'),
                  ),
                ),
                const SizedBox(width: AppConstants.kSpaceMD),
                Expanded(
                  child: CustomTextField(
                    name: 'state',
                    label: 'State',
                    validator: AppValidators.requiredField('State'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.kSpaceMD),

            CustomTextField(
              name: 'pincode',
              label: 'Pincode / Zip',
              keyboardType: TextInputType.number,
              validator: AppValidators.pincode(),
            ),

            if (isMobile) ...[
              const SizedBox(height: AppConstants.kSpaceXL),
              PrimaryButton(
                label: 'Continue to Payment',
                onPressed: _nextStep,
              ),
            ]
          ],
        ),
      ),
    ).animate().fadeIn().slideX(begin: 0.1);
  }

  Widget _buildPaymentStep({required bool isMobile}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Payment Method', style: AppTextStyles.kHeading3),
        const SizedBox(height: AppConstants.kSpaceSM),

        // --- NEW: RadioGroup ancestor wrapping all options ---
        RadioGroup<String>(
          groupValue: _selectedPaymentMethod,
          onChanged: (val) {
            if (val != null) {
              setState(() => _selectedPaymentMethod = val);
            }
          },
          child: Column(
            children: [
              _buildPaymentOption(
                title: 'Cash on Delivery (COD)',
                value: 'COD',
                icon: Icons.money,
                isEnabled: true,
              ),
              const SizedBox(height: AppConstants.kSpaceSM),
              _buildPaymentOption(
                title: 'Online Payment',
                value: 'ONLINE',
                icon: Icons.credit_card,
                isEnabled: false,
                badgeText: 'Coming Soon',
              ),
            ],
          ),
        ),

        const SizedBox(height: AppConstants.kSpaceXL),

        Text('Order Summary', style: AppTextStyles.kHeading3),
        const SizedBox(height: AppConstants.kSpaceSM),

        BlocBuilder<CartBloc, CartState>(
          builder: (context, state) {
            if (state is CartLoaded) {
              final subtotal = state.cart.subtotal;
              final shippingCost = subtotal > 100 ? 0.0 : 10.0;
              final total = subtotal + shippingCost;

              return GlassContainer(
                padding: const EdgeInsets.all(AppConstants.kSpaceLG),
                child: Column(
                  children: [
                    ...state.cart.items.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        children: [
                          Text('${item.quantity}x', style: AppTextStyles.kBodyMedium.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(width: AppConstants.kSpaceSM),
                          Expanded(child: Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis)),
                          Text((item.price * item.quantity).toCurrency()),
                        ],
                      ),
                    )),
                    const Divider(color: AppColors.kGlassBorder, height: AppConstants.kSpaceXL),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Subtotal'),
                        Text(subtotal.toCurrency()),
                      ],
                    ),
                    const SizedBox(height: AppConstants.kSpaceSM),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Shipping'),
                        Text(shippingCost == 0 ? 'FREE' : shippingCost.toCurrency(),
                            style: TextStyle(color: shippingCost == 0 ? Colors.green : null)),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppConstants.kSpaceSM),
                      child: Divider(color: AppColors.kGlassBorder),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Grand Total', style: AppTextStyles.kHeading3),
                        Text(total.toCurrency(), style: AppTextStyles.kHeading2.copyWith(color: AppColors.kAccentIndigo)),
                      ],
                    ),
                    const SizedBox(height: AppConstants.kSpaceXL),

                    PrimaryButton(
                      label: 'Place Order',
                      icon: Icons.check_circle_outline,
                      isLoading: _isPlacingOrder,
                      onPressed: _placeOrder,
                    ),
                    if (isMobile) ...[
                      const SizedBox(height: AppConstants.kSpaceMD),
                      TextButton(
                        onPressed: () {
                          setState(() => _currentStep = 0);
                          _pageController.previousPage(duration: AppConstants.kAnimNormal, curve: Curves.easeInOut);
                        },
                        child: Text('Back to Shipping', style: AppTextStyles.kBodyMedium),
                      )
                    ]
                  ],
                ),
              );
            }
            return const Center(child: CircularProgressIndicator(color: AppColors.kAccentIndigo));
          },
        ),
      ],
    ).animate().fadeIn().slideX(begin: 0.1);
  }

  Widget _buildPaymentOption({
    required String title,
    required String value,
    required IconData icon,
    required bool isEnabled,
    String? badgeText,
  }) {
    final isSelected = _selectedPaymentMethod == value;

    return GestureDetector(
      onTap: isEnabled ? () => setState(() => _selectedPaymentMethod = value) : null,
      child: Opacity(
        opacity: isEnabled ? 1.0 : 0.6,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? AppColors.kAccentIndigo : AppColors.kGlassBorder,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(AppConstants.kRadiusMD),
          ),
          child: GlassContainer(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.kSpaceSM,
              vertical: AppConstants.kSpaceMD,
            ),
            child: Row(
              children: [
                // --- NEW: Radio no longer handles state or groups itself ---
                Radio<String>(
                  value: value,
                  activeColor: AppColors.kAccentIndigo,
                ),
                Icon(icon, color: AppColors.kTextPrimary),
                const SizedBox(width: AppConstants.kSpaceMD),
                Expanded(
                  child: Text(
                    title,
                    style: AppTextStyles.kBodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (badgeText != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.kAccentPink.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(AppConstants.kRadiusSM),
                    ),
                    child: Text(
                      badgeText,
                      style: AppTextStyles.kLabelSmall.copyWith(
                        color: AppColors.kAccentPink,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}