import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

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
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
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

  Map<String, dynamic>? _savedAddressData;

  // --- Dynamic Shipping State ---
  List<Map<String, dynamic>> _shippingRates = [];
  Map<String, dynamic>? _selectedShippingRate;
  bool _isLoadingRates = true;

  late Razorpay _razorpay;
  String? _pendingOrderId;

  @override
  void initState() {
    super.initState();
    _fetchShippingRates();

    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _razorpay.clear();
    super.dispose();
  }

  Future<void> _fetchShippingRates() async {
    try {
      // Adjust the route if your backend shipping rate endpoint differs
      final response = await GetIt.I<ApiClient>().dio.get(
        '/api/orders/shipping/shipping-rates/active',
      );

      if (mounted) {
        setState(() {
          final responseData = response.data;
          List<dynamic> rawList = [];

          if (responseData is List) {
            rawList = responseData;
          } else if (responseData is Map && responseData.containsKey('data')) {
            rawList = responseData['data'] is List ? responseData['data'] : [];
          } else if (responseData is Map &&
              responseData.containsKey('shippingRates')) {
            rawList = responseData['shippingRates'];
          }

          _shippingRates = List<Map<String, dynamic>>.from(rawList);
          _isLoadingRates = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingRates = false);
      }
      Fluttertoast.showToast(
        msg: 'Failed to load delivery areas. Please try again.',
        backgroundColor: AppColors.kError,
        textColor: Colors.white,
      );
    }
  }

  void _nextStep() {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      _savedAddressData = Map<String, dynamic>.from(
        _formKey.currentState!.value,
      );
      setState(() => _currentStep = 1);
      _pageController.nextPage(
        duration: AppConstants.kAnimNormal,
        curve: Curves.easeInOut,
      );
    }
  }

  // 👇 ADD THESE THREE FUNCTIONS 👇
  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    if (_pendingOrderId == null) return;

    setState(() => _isPlacingOrder = true);

    try {
      // 1. Send the exact payload your verifyPayment controller expects
      final verifyPayload = {
        'razorpay_order_id': response.orderId,
        'razorpay_payment_id': response.paymentId,
        'razorpay_signature': response.signature,
        'orderId': _pendingOrderId,
      };

      // Ensure this route matches your backend routing setup!
      await GetIt.I<ApiClient>().dio.post(
        '/api/orders/payment/verify',
        data: verifyPayload,
      );

      // 2. Clear cart and navigate on success
      if (mounted) {
        context.read<CartBloc>().add(const CartCleared());
        context.go('/cart/order-success/$_pendingOrderId');
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Payment verification failed. Please contact support.',
        backgroundColor: AppColors.kError,
        textColor: Colors.white,
      );
    } finally {
      if (mounted) setState(() => _isPlacingOrder = false);
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    Fluttertoast.showToast(
      msg: 'Payment Failed: ${response.message}',
      backgroundColor: AppColors.kError,
      textColor: Colors.white,
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    Fluttertoast.showToast(
      msg: 'External wallet selected: ${response.walletName}',
      backgroundColor: AppColors.kAccentIndigo,
      textColor: Colors.white,
    );
  }

  Future<void> _placeOrder() async {
    if (_savedAddressData == null) {
      Fluttertoast.showToast(
        msg: 'Please check your shipping details.',
        backgroundColor: AppColors.kError,
        textColor: Colors.white,
      );
      return;
    }

    final cartState = context.read<CartBloc>().state;
    if (cartState is! CartLoaded) return;

    if (_selectedShippingRate == null) {
      Fluttertoast.showToast(
        msg: 'Please select a delivery area.',
        backgroundColor: AppColors.kError,
        textColor: Colors.white,
      );
      return;
    }

    setState(() => _isPlacingOrder = true);

    try {
      final addressData = Map<String, dynamic>.from(_savedAddressData!);
      addressData['area'] =
          _selectedShippingRate?['areaName'] ??
          _selectedShippingRate?['region'] ??
          'Unknown';
      addressData.remove('deliveryArea');

      final cart = cartState.cart;

      final double subtotal = (cart.subtotal as num).toDouble();

      final payload = {
        'address': addressData,
        'paymentMethod': _selectedPaymentMethod,
        'amount': subtotal,
        'items': cart.items
            .map(
              (item) => {
                'productId': int.tryParse(item.productId) ?? 0,
                'vendorId': (item.vendorId > 0) ? item.vendorId : 1,
                'quantity': item.quantity,
                'price': item.price,
              },
            )
            .toList(),
      };

      final response = await GetIt.I<ApiClient>().dio.post(
        '/api/orders/checkout',
        data: payload,
      );

      final orderId = response.data['orderId']?.toString() ?? 'UNKNOWN_ID';

      if (_selectedPaymentMethod == 'RAZORPAY') {
        _pendingOrderId = orderId;

        final razorpayOrder = response.data['razorpayOrder'];

        var options = {
          'key': dotenv.env['RAZORPAY_KEY_ID'] ?? '',
          'amount': razorpayOrder['amount'],
          'name': 'E-Commerce',
          'description': 'Order #$orderId',
          'order_id': razorpayOrder['id'],
          'prefill': {'contact': addressData['phone']},
        };

        _razorpay.open(options);
      } else {
        if (mounted) {
          context.read<CartBloc>().add(const CartCleared());
          context.go('/cart/order-success/$orderId');
        }
      }
    } on DioException catch (e) {
      print("❌ BACKEND ERROR: ${e.response?.data}");
      Fluttertoast.showToast(
        msg: e.response?.data['message'] ?? 'Failed to place order',
        backgroundColor: AppColors.kError,
        textColor: Colors.white,
      );
    } catch (e) {
      print("❌ APP ERROR: $e");
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
        appBar: const CustomAppBar(title: 'Checkout', showBackButton: true),
        body: LoadingOverlay(
          isLoading: _isPlacingOrder,
          message: 'Processing Order...',
          child: ResponsiveBuilder(
            mobile: (context) => Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppConstants.kSpaceMD,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildStepIndicator(
                        0,
                        'Shipping',
                        Icons.local_shipping_outlined,
                      ),
                      Container(
                        width: 40,
                        height: 2,
                        color: _currentStep >= 1
                            ? AppColors.kAccentIndigo
                            : AppColors.kGlassBorder,
                      ),
                      _buildStepIndicator(1, 'Payment', Icons.payment_outlined),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      // Wrapped in SingleChildScrollView to prevent 141px keyboard overflow
                      SingleChildScrollView(
                        child: _buildShippingStep(isMobile: true),
                      ),
                      SingleChildScrollView(
                        child: _buildPaymentStep(isMobile: true),
                      ),
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
                      padding: EdgeInsets.only(
                        left: responsivePad.left,
                        right: AppConstants.kSpaceMD,
                        top: AppConstants.kSpaceLG,
                        bottom: AppConstants.kSpaceXXL,
                      ),
                      child: _buildShippingStep(isMobile: false),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: SingleChildScrollView(
                      padding: EdgeInsets.only(
                        left: AppConstants.kSpaceMD,
                        right: responsivePad.right,
                        top: AppConstants.kSpaceLG,
                        bottom: AppConstants.kSpaceXXL,
                      ),
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
          _pageController.previousPage(
            duration: AppConstants.kAnimNormal,
            curve: Curves.easeInOut,
          );
        }
      },
      child: Column(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: isActive
                ? AppColors.kAccentIndigo
                : AppColors.kGlassWhite,
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
              color: isActive
                  ? AppColors.kTextPrimary
                  : AppColors.kTextSecondary,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShippingStep({required bool isMobile}) {
    final authState = context.read<AuthBloc>().state;
    String userName = '';
    String userPhone = '';

    if (authState is AuthAuthenticated) {
      userName = authState.user.name;
      userPhone = authState.user.phone;
    }

    return FormBuilder(
      key: _formKey,
      child: GlassContainer(
        padding: const EdgeInsets.all(AppConstants.kSpaceLG),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Shipping Details', style: AppTextStyles.kHeading3),
            const SizedBox(height: AppConstants.kSpaceLG),

            // Locked Full Name Field
            CustomTextField(
              name: 'fullName',
              label: 'Full Name',
              initialValue: userName,
              readOnly: true,
              validator: AppValidators.name(),
            ),
            const SizedBox(height: AppConstants.kSpaceMD),

            // Locked Phone Field
            CustomTextField(
              name: 'phone',
              label: 'Phone Number',
              initialValue: userPhone,
              keyboardType: TextInputType.phone,
              readOnly: true,
              validator: AppValidators.phone(),
            ),
            const SizedBox(height: AppConstants.kSpaceMD),

            // Address Line 1
            CustomTextField(
              name: 'addressLine1',
              label: 'Street Address',
              hint: 'House No., Building, Street',
              validator: AppValidators.requiredField('Address'),
            ),
            const SizedBox(height: AppConstants.kSpaceMD),

            // Dynamic Delivery Area Dropdown
            _isLoadingRates
                ? const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.kAccentIndigo,
                      ),
                    ),
                  )
                : FormBuilderDropdown<Map<String, dynamic>>(
                    name: 'deliveryArea',
                    decoration: InputDecoration(
                      labelText: 'Delivery Area',
                      filled: true,
                      fillColor: AppColors.kGlassWhite,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppConstants.kRadiusMD,
                        ),
                        borderSide: const BorderSide(
                          color: AppColors.kGlassBorder,
                        ),
                      ),
                    ),
                    validator: (value) =>
                        value == null ? 'Please select a delivery area' : null,
                    items: _shippingRates.map((rate) {
                      // Change 'areaName' or 'region' to match your DB column
                      final areaName =
                          rate['areaName'] ?? rate['region'] ?? 'Unknown Area';
                      return DropdownMenuItem(
                        value: rate,
                        child: Text(areaName),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedShippingRate = val;
                        });
                      }
                    },
                  ),
            const SizedBox(height: AppConstants.kSpaceMD),

            // Locked City and State
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    name: 'city',
                    label: 'City',
                    initialValue: 'Raipur',
                    readOnly: true,
                    validator: AppValidators.requiredField('City'),
                  ),
                ),
                const SizedBox(width: AppConstants.kSpaceMD),
                Expanded(
                  child: CustomTextField(
                    name: 'state',
                    label: 'State',
                    initialValue: 'Chhattisgarh',
                    readOnly: true,
                    validator: AppValidators.requiredField('State'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.kSpaceMD),

            if (isMobile) ...[
              const SizedBox(height: AppConstants.kSpaceXL),
              PrimaryButton(label: 'Continue to Payment', onPressed: _nextStep),
            ],
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
                value: 'RAZORPAY',
                icon: Icons.credit_card,
                isEnabled: true,
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
              // 1. IRONCLAD CASTS: Force everything to 'num' then to 'double'
              final double subtotal = (state.cart.subtotal as num).toDouble();

              final double shippingCost = _selectedShippingRate != null
                  ? ((_selectedShippingRate!['rate'] ??
                                _selectedShippingRate!['cost'] ??
                                0.0)
                            as num)
                        .toDouble()
                  : 0.0;

              final double total = subtotal + shippingCost;

              return GlassContainer(
                padding: const EdgeInsets.all(AppConstants.kSpaceLG),
                child: Column(
                  children: [
                    ...state.cart.items.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          children: [
                            Text(
                              '${item.quantity}x',
                              style: AppTextStyles.kBodyMedium.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: AppConstants.kSpaceSM),
                            Expanded(
                              child: Text(
                                item.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // 2. CAST ITEM TOTALS
                            Text(
                              ((item.price * item.quantity) as num)
                                  .toDouble()
                                  .toCurrency(),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Divider(
                      color: AppColors.kGlassBorder,
                      height: AppConstants.kSpaceXL,
                    ),

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
                        Text(
                          shippingCost == 0
                              ? 'FREE'
                              : shippingCost.toCurrency(),
                          style: TextStyle(
                            color: shippingCost == 0 ? Colors.green : null,
                          ),
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: AppConstants.kSpaceSM,
                      ),
                      child: Divider(color: AppColors.kGlassBorder),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Grand Total', style: AppTextStyles.kHeading3),
                        Text(
                          total.toCurrency(),
                          style: AppTextStyles.kHeading2.copyWith(
                            color: AppColors.kAccentIndigo,
                          ),
                        ),
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
                          _pageController.previousPage(
                            duration: AppConstants.kAnimNormal,
                            curve: Curves.easeInOut,
                          );
                        },
                        child: Text(
                          'Back to Shipping',
                          style: AppTextStyles.kBodyMedium,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }
            return const Center(
              child: CircularProgressIndicator(color: AppColors.kAccentIndigo),
            );
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
      onTap: isEnabled
          ? () => setState(() => _selectedPaymentMethod = value)
          : null,
      child: Opacity(
        opacity: isEnabled ? 1.0 : 0.6,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected
                  ? AppColors.kAccentIndigo
                  : AppColors.kGlassBorder,
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
                // ✅ FIXED (NO groupValue, NO onChanged)
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.kAccentPink.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(
                        AppConstants.kRadiusSM,
                      ),
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
