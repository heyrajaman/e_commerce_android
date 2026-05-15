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

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormBuilderState>();

  void _onRegister() {
    // PROD UX FIX: Dismiss keyboard so the error box or loading indicator is visible
    FocusScope.of(context).unfocus();

    if (_formKey.currentState?.saveAndValidate() ?? false) {
      final values = _formKey.currentState!.value;

      // PROD DATA FIX: Always trim inputs on registration to prevent invisible whitespace bugs in the database
      context.read<AuthBloc>().add(
        AuthRegisterRequested(
          name: values['name'].toString().trim(),
          email: values['email'].toString().trim(),
          phone: values['phone'].toString().trim(),
          password: values['password'].toString(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MeshGradientBackground(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.kSpaceLG,
            vertical: AppConstants.kSpaceXXL,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Header section
              Column(
                    children: [
                      const Icon(
                        Icons.person_add_alt_1_outlined,
                        size: 56,
                        color: AppColors.kAccentPurple,
                      ),
                      const SizedBox(height: AppConstants.kSpaceMD),
                      Text('Create Account', style: AppTextStyles.kHeading1),
                      const SizedBox(height: AppConstants.kSpaceSM),
                      Text(
                        'Join us to start shopping',
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

              // Form Container
              GlassContainer(
                    child: FormBuilder(
                      key: _formKey,
                      child: Column(
                        children: [
                          CustomTextField(
                            name: 'name',
                            label: 'Full Name',
                            hint: 'Enter your full name',
                            prefixIcon: Icons.person_outline,
                            validator: FormBuilderValidators.required(
                              errorText: 'Name is required',
                            ),
                          ),
                          const SizedBox(height: AppConstants.kSpaceMD),

                          CustomTextField(
                            name: 'email',
                            label: 'Email Address',
                            hint: 'Enter your email',
                            prefixIcon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: FormBuilderValidators.compose([
                              FormBuilderValidators.required(
                                errorText: 'Email is required',
                              ),
                              FormBuilderValidators.email(
                                errorText: 'Enter a valid email',
                              ),
                            ]),
                          ),
                          const SizedBox(height: AppConstants.kSpaceMD),

                          CustomTextField(
                            name: 'phone',
                            label: 'Phone Number',
                            hint: 'Enter your 10-digit phone number',
                            prefixIcon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                            // PROD DATA FIX: Prevent users from typing spaces, dashes, or overflowing the database limit
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(10),
                            ],
                            validator: FormBuilderValidators.compose([
                              FormBuilderValidators.required(
                                errorText: 'Phone number is required',
                              ),
                              // PROD DATA FIX: Enforce exact length
                              (value) {
                                if (value != null && value.length != 10) {
                                  return 'Please enter a valid 10-digit mobile number';
                                }
                                return null;
                              },
                            ]),
                          ),
                          const SizedBox(height: AppConstants.kSpaceMD),

                          CustomTextField(
                            name: 'password',
                            label: 'Password',
                            hint: 'Create a password',
                            prefixIcon: Icons.lock_outline,
                            isPassword: true,
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

                          CustomTextField(
                            name: 'confirm_password',
                            label: 'Confirm Password',
                            hint: 'Re-enter your password',
                            prefixIcon: Icons.lock_reset_outlined,
                            isPassword: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please confirm your password';
                              }
                              final password = _formKey
                                  .currentState
                                  ?.fields['password']
                                  ?.value;
                              if (value != password) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppConstants.kSpaceXL),

                          BlocConsumer<AuthBloc, AuthState>(
                            listener: (context, state) {
                              if (state is AuthAuthenticated) {
                                // Using context.go replaces the stack so they can't hit back to return to registration
                                context.go('/home');
                              }
                            },
                            builder: (context, state) {
                              return Column(
                                children: [
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
                                    label: 'CREATE ACCOUNT',
                                    icon: Icons.app_registration,
                                    isLoading: state is AuthLoading,
                                    onPressed: _onRegister,
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

              // Navigation to Login Screen
              TextButton(
                onPressed: () => context.go('/login'),
                child: Text.rich(
                  TextSpan(
                    text: 'Already have an account? ',
                    style: AppTextStyles.kBodyMedium,
                    children: [
                      TextSpan(
                        text: 'Login',
                        style: AppTextStyles.kBodyMedium.copyWith(
                          color: AppColors.kAccentPurple,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: const Duration(milliseconds: 400)),
            ],
          ),
        ),
      ),
    );
  }
}
