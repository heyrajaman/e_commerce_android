import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:fluttertoast/fluttertoast.dart'; // 🟢 Added for error toasts
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:get_it/get_it.dart'; // 🟢 Added for ApiClient

import '../../../../core/network/api_client.dart'; // 🟢 Added to fetch areas
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_constants.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/custom_app_bar_widget.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../../shared/widgets/glass_container.dart';
import '../../../../shared/widgets/mesh_gradient_background.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
import '../bloc/profile_state.dart';

class AddressesScreen extends StatefulWidget {
  const AddressesScreen({super.key});

  @override
  State<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends State<AddressesScreen> {
  final _addressFormKey = GlobalKey<FormBuilderState>();

  // 🟢 Added State variables for dynamic areas
  List<Map<String, dynamic>> _shippingRates = [];
  bool _isLoadingRates = true;

  @override
  void initState() {
    super.initState();
    context.read<ProfileBloc>().add(ProfileAddressesFetchRequested());
    _fetchShippingRates(); // 🟢 Fetch areas on init
  }

  // 🟢 Added fetch method identical to checkout_screen.dart
  Future<void> _fetchShippingRates() async {
    try {
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

  void _showAddAddressDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: GlassContainer(
          padding: const EdgeInsets.all(AppConstants.kSpaceLG),
          child: FormBuilder(
            key: _addressFormKey,
            // 🟢 Set initial values for the locked fields
            initialValue: const {'city': 'Raipur', 'state': 'Chhattisgarh'},
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Add New Address', style: AppTextStyles.kHeading3),
                const SizedBox(height: AppConstants.kSpaceLG),

                // 🟢 Renamed to Address Line
                CustomTextField(
                  name: 'addressLine1',
                  label: 'Address Line',
                  validator: FormBuilderValidators.required(),
                ),
                const SizedBox(height: AppConstants.kSpaceMD),

                // 🟢 Dynamic Dropdown for Area
                _isLoadingRates
                    ? const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.kAccentIndigo,
                          ),
                        ),
                      )
                    : FormBuilderDropdown<String>(
                        name: 'area',
                        decoration: InputDecoration(
                          labelText: 'Area / Locality',
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
                        validator: FormBuilderValidators.required(
                          errorText: 'Please select a delivery area',
                        ),
                        items: _shippingRates.map((rate) {
                          final areaName =
                              rate['areaName'] ??
                              rate['region'] ??
                              'Unknown Area';
                          return DropdownMenuItem<String>(
                            value: areaName,
                            child: Text(areaName),
                          );
                        }).toList(),
                      ),
                const SizedBox(height: AppConstants.kSpaceMD),

                // 🟢 Read-Only City & State
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        name: 'city',
                        label: 'City',
                        readOnly: true,
                        validator: FormBuilderValidators.required(),
                      ),
                    ),
                    const SizedBox(width: AppConstants.kSpaceMD),
                    Expanded(
                      child: CustomTextField(
                        name: 'state',
                        label: 'State',
                        readOnly: true,
                        validator: FormBuilderValidators.required(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.kSpaceLG),

                PrimaryButton(
                  label: 'Save Address',
                  onPressed: () {
                    if (_addressFormKey.currentState?.saveAndValidate() ??
                        false) {
                      final values = _addressFormKey.currentState!.value;
                      context.read<ProfileBloc>().add(
                        ProfileAddressAddRequested(
                          addressLine1: values['addressLine1'],
                          state: values['state'],
                          city: values['city'],
                          area: values['area'],
                          isDefault: true,
                        ),
                      );
                      Navigator.pop(context);
                    }
                  },
                ),
                const SizedBox(height: AppConstants.kSpaceMD),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MeshGradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: const CustomAppBar(title: 'My Addresses'),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _showAddAddressDialog,
          backgroundColor: AppColors.kAccentIndigo,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text(
            "Add Address",
            style: TextStyle(color: Colors.white),
          ),
        ),
        body: BlocConsumer<ProfileBloc, ProfileState>(
          listener: (context, state) {
            if (state is ProfileAddressActionSuccess) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.message)));
            }
          },
          buildWhen: (previous, current) =>
              current is ProfileAddressesLoaded ||
              current is ProfileLoading ||
              current is ProfileError,
          builder: (context, state) {
            if (state is ProfileLoading) {
              return const Center(
                child: CircularProgressIndicator(
                  color: AppColors.kAccentIndigo,
                ),
              );
            } else if (state is ProfileAddressesLoaded) {
              if (state.addresses.isEmpty) {
                return const Center(child: Text("No addresses found."));
              }
              return ListView.builder(
                padding: const EdgeInsets.all(AppConstants.kSpaceMD),
                itemCount: state.addresses.length,
                itemBuilder: (context, index) {
                  final address = state.addresses[index];
                  return GlassContainer(
                    margin: const EdgeInsets.only(
                      bottom: AppConstants.kSpaceMD,
                    ),
                    child: ListTile(
                      leading: const Icon(
                        Icons.location_on,
                        color: AppColors.kAccentIndigo,
                      ),
                      title: Text("${address.addressLine1}, ${address.area}"),
                      subtitle: Text("${address.city}, ${address.state}"),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: AppColors.kError,
                        ),
                        onPressed: () => context.read<ProfileBloc>().add(
                          ProfileAddressDeleteRequested(address.id),
                        ),
                      ),
                    ),
                  );
                },
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
