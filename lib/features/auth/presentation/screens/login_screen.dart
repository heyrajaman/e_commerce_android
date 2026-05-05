import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_constants.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../../shared/widgets/glass_container.dart';
import '../../../../shared/widgets/mesh_gradient_background.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormBuilderState>();

  void _onLogin() {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      final values = _formKey.currentState!.value;
      context.read<AuthBloc>().add(
        AuthLoginRequested(
          phone: values['phone'],
          password: values['password'],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MeshGradientBackground(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.kSpaceLG),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo & Title Header
              Column(
                    children: [
                      const Icon(
                        Icons.shopping_bag_outlined,
                        size: 64,
                        color: AppColors.kAccentIndigo,
                      ),
                      const SizedBox(height: AppConstants.kSpaceMD),
                      Text('Welcome Back', style: AppTextStyles.kHeading1),
                      const SizedBox(height: AppConstants.kSpaceSM),
                      Text(
                        'Login to continue your shopping',
                        style: AppTextStyles.kBodyMedium,
                      ),
                    ],
                  )
                  .animate()
                  .fadeIn(duration: AppConstants.kAnimNormal)
                  .slideY(
                    begin: 0.2,
                    end: 0,
                    duration: AppConstants.kAnimNormal,
                    curve: Curves.easeOut,
                  ),

              const SizedBox(height: AppConstants.kSpaceXL),

              // The Glass Form Container
              GlassContainer(
                    child: FormBuilder(
                      key: _formKey,
                      child: Column(
                        children: [
                          CustomTextField(
                            name: 'phone',
                            label: 'Phone Number',
                            hint: 'Enter your registered phone number',
                            prefixIcon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                            maxLength: 10,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            validator: FormBuilderValidators.compose([
                              FormBuilderValidators.required(
                                errorText: 'Phone number is required',
                              ),
                              FormBuilderValidators.match(
                                RegExp(r'^\d{10}$'),
                                errorText: 'Must be exactly 10 digits',
                              ),
                            ]),
                          ),
                          const SizedBox(height: AppConstants.kSpaceLG),

                          CustomTextField(
                            name: 'password',
                            label: 'Password',
                            hint: 'Enter your password',
                            prefixIcon: Icons.lock_outline,
                            isPassword: true,
                            maxLength: 16,
                            validator: FormBuilderValidators.compose([
                              FormBuilderValidators.required(
                                errorText: 'Password is required',
                              ),
                              FormBuilderValidators.minLength(
                                6,
                                errorText: 'Minimum 6 characters',
                              ),
                            ]),
                          ),
                          const SizedBox(height: AppConstants.kSpaceMD),

                          // BlocConsumer updated to show error in UI instead of Toast
                          BlocConsumer<AuthBloc, AuthState>(
                            listener: (context, state) {
                              if (state is AuthAuthenticated) {
                                context.go('/home');
                              }
                              // Removed the Fluttertoast error popup from here!
                            },
                            builder: (context, state) {
                              return Column(
                                children: [
                                  // 🟢 CRITICAL FIX: If there is an error, show it here in the UI!
                                  if (state is AuthError)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: AppConstants.kSpaceMD,
                                      ),
                                      child:
                                          Container(
                                            padding: const EdgeInsets.all(
                                              AppConstants.kSpaceSM,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.kError
                                                  .withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                color: AppColors.kError
                                                    .withValues(alpha: 0.5),
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(
                                                  Icons.error_outline,
                                                  color: AppColors.kError,
                                                  size: 20,
                                                ),
                                                const SizedBox(
                                                  width: AppConstants.kSpaceSM,
                                                ),
                                                Expanded(
                                                  child: Text(
                                                    state.message,
                                                    style: AppTextStyles
                                                        .kBodyMedium
                                                        .copyWith(
                                                          color:
                                                              AppColors.kError,
                                                        ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ).animate().fadeIn().slideY(
                                            begin: -0.2,
                                            end: 0,
                                          ),
                                    ),

                                  PrimaryButton(
                                    label: 'LOGIN',
                                    icon: Icons.login,
                                    isLoading: state is AuthLoading,
                                    onPressed: _onLogin,
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  )
                  .animate()
                  .fadeIn(delay: const Duration(milliseconds: 200))
                  .slideY(
                    begin: 0.1,
                    end: 0,
                    duration: AppConstants.kAnimNormal,
                    curve: Curves.easeOut,
                  ),

              const SizedBox(height: AppConstants.kSpaceLG),

              // Navigation to Register Screen
              TextButton(
                onPressed: () => context.push('/register'),
                child: Text.rich(
                  TextSpan(
                    text: "Don't have an account? ",
                    style: AppTextStyles.kBodyMedium,
                    children: [
                      TextSpan(
                        text: 'Register',
                        style: AppTextStyles.kBodyMedium.copyWith(
                          color: AppColors.kAccentIndigo,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: const Duration(milliseconds: 400)),

              const SizedBox(height: 24),
              Center(
                child: TextButton.icon(
                  onPressed: () {
                    context.push('/delivery-login');
                  },
                  icon: const Icon(
                    Icons.local_shipping_outlined,
                    color: Colors.deepOrangeAccent,
                    // A distinct color for delivery
                    size: 22,
                  ),
                  label: const Text(
                    'Login as Delivery Partner',
                    style: TextStyle(
                      color: Colors.deepOrangeAccent,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      letterSpacing: 0.5,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    backgroundColor: Colors.deepOrangeAccent.withValues(
                      alpha: 0.05,
                    ),
                    // Soft tint
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      // Smooth rounded corners
                      side: BorderSide(
                        color: Colors.deepOrangeAccent.withValues(
                          alpha: 0.3,
                        ), // Subtle border
                      ),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
