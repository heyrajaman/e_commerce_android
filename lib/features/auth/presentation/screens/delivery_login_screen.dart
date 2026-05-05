import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/widgets/custom_text_field.dart';
import '../../../../shared/widgets/mesh_gradient_background.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class DeliveryLoginScreen extends StatefulWidget {
  const DeliveryLoginScreen({super.key});

  @override
  State<DeliveryLoginScreen> createState() => _DeliveryLoginScreenState();
}

class _DeliveryLoginScreenState extends State<DeliveryLoginScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (_formKey.currentState!.validate()) {
      final phone = _phoneController.text.trim();
      final password = _passwordController.text.trim();

      // Dispatch the event to our AuthBloc
      context.read<AuthBloc>().add(AuthDeliveryLoginRequested(phone, password));
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. WRAP THE ENTIRE SCREEN IN YOUR BEAUTIFUL BACKGROUND
    return MeshGradientBackground(
      child: Scaffold(
        // 2. MAKE THE SCAFFOLD TRANSPARENT SO THE MESH GRADIENT SHOWS
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          // Use white or black depending on your mesh gradient colors
          iconTheme: const IconThemeData(color: Colors.black87),
        ),
        body: SafeArea(
          child: BlocConsumer<AuthBloc, AuthState>(
            listener: (context, state) {
              if (state is AuthError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
            builder: (context, state) {
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 16.0,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 20),
                      const Center(
                        child: Icon(
                          Icons.local_shipping,
                          size: 80,
                          color: Colors.deepOrangeAccent,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Delivery Partner Portal',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Sign in to view your assigned orders',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.black54),
                      ),
                      const SizedBox(height: 48),

                      CustomTextField(
                        name: 'phone',
                        label: 'Phone Number',
                        hint: 'e.g., 9876543210',
                        controller: _phoneController,
                        prefixIcon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        // Restricts keyboard input to numbers and limits to 10 digits
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your phone number';
                          }
                          // Validates that exactly 10 digits were entered
                          if (value.length != 10) {
                            return 'Please enter a valid 10-digit mobile number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      CustomTextField(
                        name: 'password',
                        label: 'Password',
                        hint: '••••••••',
                        controller: _passwordController,
                        prefixIcon: Icons.lock_outline,
                        isPassword: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 40),

                      state is AuthLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: Colors.deepOrangeAccent,
                              ),
                            )
                          : PrimaryButton(
                              label: 'Login as Partner',
                              onPressed: _handleLogin,
                            ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
