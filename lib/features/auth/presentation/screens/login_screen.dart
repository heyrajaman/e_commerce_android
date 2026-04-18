import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:fluttertoast/fluttertoast.dart';
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
          email: values['email'],
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
                  Text(
                    'Welcome Back',
                    style: AppTextStyles.kHeading1,
                  ),
                  const SizedBox(height: AppConstants.kSpaceSM),
                  Text(
                    'Login to continue your shopping',
                    style: AppTextStyles.kBodyMedium,
                  ),
                ],
              ).animate().fadeIn(duration: AppConstants.kAnimNormal).slideY(
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
                        name: 'email',
                        label: 'Email Address',
                        hint: 'Enter your email',
                        prefixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: FormBuilderValidators.compose([
                          FormBuilderValidators.required(errorText: 'Email is required'),
                          FormBuilderValidators.email(errorText: 'Enter a valid email'),
                        ]),
                      ),
                      const SizedBox(height: AppConstants.kSpaceLG),

                      CustomTextField(
                        name: 'password',
                        label: 'Password',
                        hint: 'Enter your password',
                        prefixIcon: Icons.lock_outline,
                        isPassword: true,
                        validator: FormBuilderValidators.compose([
                          FormBuilderValidators.required(errorText: 'Password is required'),
                          FormBuilderValidators.minLength(6, errorText: 'Minimum 6 characters'),
                        ]),
                      ),
                      const SizedBox(height: AppConstants.kSpaceXL),

                      // BlocConsumer listens to AuthBloc to show errors or navigate,
                      // and builds the UI to show the loading spinner when needed.
                      BlocConsumer<AuthBloc, AuthState>(
                        listener: (context, state) {
                          if (state is AuthAuthenticated) {
                            context.go('/home');
                          } else if (state is AuthError) {
                            Fluttertoast.showToast(
                              msg: state.message,
                              backgroundColor: AppColors.kError,
                              textColor: Colors.white,
                              gravity: ToastGravity.BOTTOM,
                            );
                          }
                        },
                        builder: (context, state) {
                          return PrimaryButton(
                            label: 'LOGIN',
                            icon: Icons.login,
                            isLoading: state is AuthLoading,
                            onPressed: _onLogin,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: const Duration(milliseconds: 200)).slideY(
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
            ],
          ),
        ),
      ),
    );
  }
}