import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_constants.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/app_validators.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/widgets/custom_app_bar_widget.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../../shared/widgets/glass_container.dart';
import '../../../../shared/widgets/loading_overlay_widget.dart';
import '../../../../shared/widgets/mesh_gradient_background.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
import '../bloc/profile_state.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _profileFormKey = GlobalKey<FormBuilderState>();
  final _passwordFormKey = GlobalKey<FormBuilderState>();
  final ImagePicker _picker = ImagePicker();

  bool _isPasswordSectionExpanded = false;

  @override
  void initState() {
    super.initState();
    context.read<ProfileBloc>().add(const ProfileFetchRequested());
  }

  Future<void> _pickAndUploadImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (image != null && mounted) {
      final currentValues = _profileFormKey.currentState?.value ?? {};
      final name = currentValues['name'] as String?;
      final phone = currentValues['phone'] as String?;

      final state = context.read<ProfileBloc>().state;
      String? fallbackName, fallbackPhone;

      if (state is ProfileLoaded) {
        fallbackName = state.user.name;
        fallbackPhone = state.user.phone;
      } else if (state is ProfileUpdateSuccess) {
        fallbackName = state.user.name;
        fallbackPhone = state.user.phone;
      }

      context.read<ProfileBloc>().add(
        ProfileUpdateRequested(
          name: name ?? fallbackName ?? '',
          phone: phone ?? fallbackPhone ?? '',
          imageFile: File(image.path),
        ),
      );
    }
  }

  void _saveProfile() {
    if (_profileFormKey.currentState?.saveAndValidate() ?? false) {
      final values = _profileFormKey.currentState!.value;
      context.read<ProfileBloc>().add(
        ProfileUpdateRequested(name: values['name'], phone: values['phone']),
      );
    }
  }

  void _changePassword() {
    if (_passwordFormKey.currentState?.saveAndValidate() ?? false) {
      final values = _passwordFormKey.currentState!.value;
      context.read<ProfileBloc>().add(
        ProfilePasswordChangeRequested(
          oldPassword: values['oldPassword'],
          newPassword: values['newPassword'],
        ),
      );
    }
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.kGlassWhite,
        title: const Text('Log Out'),
        content: const Text(
          'Are you sure you want to log out of your account?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: AppTextStyles.kBodyMedium),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthBloc>().add(const AuthLogoutRequested());
            },
            child: Text(
              'Log Out',
              style: AppTextStyles.kBodyMedium.copyWith(
                color: AppColors.kError,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Dynamic padding ensures it breathes well on tablets
    final responsivePad = ResponsiveHelper.responsivePadding(context);

    return MeshGradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: const CustomAppBar(
          title: 'My Profile',
          showBackButton: false, // Root tab, no back button needed
        ),
        body: BlocConsumer<ProfileBloc, ProfileState>(
          listener: (context, state) {
            if (state is ProfilePasswordChangeSuccess) {
              _passwordFormKey.currentState?.reset();
              setState(() => _isPasswordSectionExpanded = false);
            }
          },
          builder: (context, state) {
            if (state is ProfileInitial || state is ProfileLoading) {
              return const Center(
                child: CircularProgressIndicator(
                  color: AppColors.kAccentIndigo,
                ),
              );
            } else if (state is ProfileError &&
                context.read<ProfileBloc>().state is! ProfileLoaded) {
              return Center(
                child: Text(
                  state.message,
                  style: AppTextStyles.kBodyMedium.copyWith(
                    color: AppColors.kError,
                  ),
                ),
              );
            }

            UserModel? user;
            bool isUpdating = false;

            if (state is ProfileLoaded) user = state.user;
            if (state is ProfileUpdateSuccess) user = state.user;
            if (state is ProfileUpdating) {
              user = state.user;
              isUpdating = true;
            }

            if (user == null) return const SizedBox.shrink();

            // Using our new unified LoadingOverlay Widget
            return LoadingOverlay(
              isLoading: isUpdating,
              message: 'Updating Profile...',
              child: SingleChildScrollView(
                padding: responsivePad,
                child: Center(
                  // ConstrainedBox ensures the profile form doesn't stretch infinitely on wide desktop screens
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Column(
                      children: [
                        _buildProfileHeader(user),
                        const SizedBox(height: AppConstants.kSpaceXL),

                        _buildEditProfileForm(user),
                        const SizedBox(height: AppConstants.kSpaceLG),

                        _buildChangePasswordSection(),
                        const SizedBox(height: AppConstants.kSpaceXL),

                        _buildMenuItems(context),
                        const SizedBox(height: AppConstants.kSpaceXXL),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // =========================================
  // UI COMPONENTS
  // =========================================

  Widget _buildProfileHeader(UserModel user) {
    final initials = user.name.isNotEmpty
        ? user.name.trim().split(' ').map((e) => e).take(2).join().toUpperCase()
        : '?';

    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 60,
                backgroundColor: AppColors.kAccentIndigo.withValues(alpha: 0.2),
                backgroundImage:
                    user.profilePic != null && user.profilePic!.isNotEmpty
                    ? CachedNetworkImageProvider(user.profilePic!)
                    : null,
                child: user.profilePic == null || user.profilePic!.isEmpty
                    ? Text(
                        initials,
                        style: AppTextStyles.kHeading1.copyWith(
                          color: AppColors.kAccentIndigo,
                        ),
                      )
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _pickAndUploadImage,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.kAccentIndigo,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ).animate().scale(
            delay: const Duration(milliseconds: 100),
            curve: Curves.easeOutBack,
          ),

          const SizedBox(height: AppConstants.kSpaceMD),
          Text(
            user.name,
            style: AppTextStyles.kHeading2,
          ).animate().fadeIn(delay: const Duration(milliseconds: 200)),
          Text(
            user.email,
            style: AppTextStyles.kBodyMedium.copyWith(
              color: AppColors.kTextSecondary,
            ),
          ).animate().fadeIn(delay: const Duration(milliseconds: 300)),
        ],
      ),
    );
  }

  Widget _buildEditProfileForm(UserModel user) {
    return GlassContainer(
          padding: const EdgeInsets.all(AppConstants.kSpaceLG),
          child: FormBuilder(
            key: _profileFormKey,
            initialValue: {'name': user.name, 'phone': user.phone},
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Personal Information', style: AppTextStyles.kHeading3),
                const SizedBox(height: AppConstants.kSpaceLG),

                CustomTextField(
                  name: 'name',
                  label: 'Full Name',
                  validator: AppValidators.name(), // Upgraded to AppValidators
                ),
                const SizedBox(height: AppConstants.kSpaceMD),

                CustomTextField(
                  name: 'phone',
                  label: 'Phone Number',
                  keyboardType: TextInputType.phone,
                  validator: AppValidators.phone(), // Upgraded to AppValidators
                ),
                const SizedBox(height: AppConstants.kSpaceLG),

                PrimaryButton(label: 'Save Changes', onPressed: _saveProfile),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(delay: const Duration(milliseconds: 400))
        .slideY(begin: 0.1);
  }

  Widget _buildChangePasswordSection() {
    return GlassContainer(
          padding: const EdgeInsets.all(AppConstants.kSpaceLG),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => setState(
                  () =>
                      _isPasswordSectionExpanded = !_isPasswordSectionExpanded,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Change Password', style: AppTextStyles.kHeading3),
                    Icon(
                      _isPasswordSectionExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: AppColors.kTextPrimary,
                    ),
                  ],
                ),
              ),

              if (_isPasswordSectionExpanded) ...[
                const SizedBox(height: AppConstants.kSpaceLG),
                FormBuilder(
                  key: _passwordFormKey,
                  child: Column(
                    children: [
                      CustomTextField(
                        name: 'oldPassword',
                        label: 'Current Password',
                        isPassword: true,
                        validator: FormBuilderValidators.required(
                          errorText: 'Required',
                        ),
                      ),
                      const SizedBox(height: AppConstants.kSpaceMD),
                      CustomTextField(
                        name: 'newPassword',
                        label: 'New Password',
                        isPassword: true,
                        validator:
                            AppValidators.password(), // Upgraded to AppValidators
                      ),
                      const SizedBox(height: AppConstants.kSpaceMD),
                      CustomTextField(
                        name: 'confirmNewPassword',
                        label: 'Confirm New Password',
                        isPassword: true,
                        validator: (val) {
                          if (val == null || val.isEmpty) return 'Required';
                          if (val !=
                              _passwordFormKey
                                  .currentState
                                  ?.fields['newPassword']
                                  ?.value) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppConstants.kSpaceLG),
                      PrimaryButton(
                        label: 'Update Password',
                        backgroundColor: AppColors.kAccentPink,
                        onPressed: _changePassword,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        )
        .animate()
        .fadeIn(delay: const Duration(milliseconds: 500))
        .slideY(begin: 0.1);
  }

  Widget _buildMenuItems(BuildContext context) {
    return Column(
          children: [
            _buildMenuCard(
              icon: Icons.receipt_long_outlined,
              title: 'My Orders',
              onTap: () => context.push('/orders'),
            ),
            const SizedBox(height: AppConstants.kSpaceMD),
            _buildMenuCard(
              icon: Icons.notifications_none_outlined,
              title: 'Notifications',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Notifications coming soon!')),
                );
              },
            ),
            const SizedBox(height: AppConstants.kSpaceMD),
            _buildMenuCard(
              icon: Icons.info_outline,
              title: 'About App',
              onTap: () {
                showAboutDialog(
                  context: context,
                  applicationName: 'E-Commerce App',
                  applicationVersion: '1.0.0',
                  applicationIcon: const FlutterLogo(size: 40),
                );
              },
            ),
            const SizedBox(height: AppConstants.kSpaceMD),
            _buildMenuCard(
              icon: Icons.logout,
              title: 'Log Out',
              iconColor: AppColors.kError,
              textColor: AppColors.kError,
              onTap: _confirmLogout,
            ),
          ],
        )
        .animate()
        .fadeIn(delay: const Duration(milliseconds: 600))
        .slideY(begin: 0.1);
  }

  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color iconColor = AppColors.kAccentIndigo,
    Color textColor = AppColors.kTextPrimary,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.kSpaceLG,
          vertical: AppConstants.kSpaceMD,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: AppConstants.kSpaceMD),
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.kLabelLarge.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: textColor.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }
}
