import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../config/app_config.dart';
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
  bool _isEmailEditable = false; // 🟢 Tracks if the user clicked "Edit"

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
      final email = currentValues['email'] as String?;

      final state = context.read<ProfileBloc>().state;
      String? fallbackEmail;

      if (state is ProfileLoaded) {
        fallbackEmail = state.user.email;
      } else if (state is ProfileUpdateSuccess) {
        fallbackEmail = state.user.email;
      }

      context.read<ProfileBloc>().add(
        ProfileUpdateRequested(
          email: email ?? fallbackEmail ?? '',
          imageFile: File(image.path),
        ),
      );
    }
  }

  void _saveProfile() {
    if (_profileFormKey.currentState?.saveAndValidate() ?? false) {
      final values = _profileFormKey.currentState!.value;
      context.read<ProfileBloc>().add(
        ProfileUpdateRequested(email: values['email']),
      );
      // Disable editing mode after saving
      setState(() => _isEmailEditable = false);
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
    final responsivePad = ResponsiveHelper.responsivePadding(context);

    return MeshGradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: const CustomAppBar(title: 'My Profile', showBackButton: false),
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

            return LoadingOverlay(
              isLoading: isUpdating,
              message: 'Updating Profile...',
              child: SingleChildScrollView(
                padding: responsivePad,
                child: Center(
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
    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 60,
                backgroundColor: AppColors.kAccentIndigo.withValues(alpha: 0.2),
                child: ClipOval(
                  child: user.profilePic != null && user.profilePic!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: AppConfig.sanitizeImageUrl(
                            user.profilePic!,
                          ),
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) => const Icon(
                            Icons.person,
                            size: 60,
                            color: AppColors.kAccentIndigo,
                          ),
                          placeholder: (context, url) =>
                              const CircularProgressIndicator(),
                        )
                      : const Icon(
                          Icons.person,
                          size: 60,
                          color: AppColors.kAccentIndigo,
                        ),
                ),
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
    // 🟢 Dynamic validation: Check if email is both typed and different from original
    final currentEmail =
        _profileFormKey.currentState?.fields['email']?.value as String? ??
        user.email;
    final isEmailChanged =
        currentEmail.trim() != user.email.trim() &&
        currentEmail.trim().isNotEmpty;

    return GlassContainer(
      padding: const EdgeInsets.all(AppConstants.kSpaceLG),
      child: FormBuilder(
        key: _profileFormKey,
        initialValue: {
          'name': user.name,
          'phone': user.phone,
          'email': user.email,
        },
        // 🟢 Rebuild UI on every keystroke so the Save button updates live
        onChanged: () => setState(() {}),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🟢 Header with Toggleable Edit/Cancel Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Personal Information', style: AppTextStyles.kHeading3),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _isEmailEditable = !_isEmailEditable;
                      // If user cancels, reset the field to original email
                      if (!_isEmailEditable) {
                        _profileFormKey.currentState?.fields['email']
                            ?.didChange(user.email);
                      }
                    });
                  },
                  icon: Icon(
                    _isEmailEditable ? Icons.close : Icons.edit,
                    size: 16,
                    color: AppColors.kAccentIndigo,
                  ),
                  label: Text(
                    _isEmailEditable ? 'Cancel' : 'Edit',
                    style: AppTextStyles.kBodyMedium.copyWith(
                      color: AppColors.kAccentIndigo,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.kSpaceMD),

            CustomTextField(name: 'name', label: 'Full Name', readOnly: true),
            const SizedBox(height: AppConstants.kSpaceMD),

            CustomTextField(
              name: 'phone',
              label: 'Phone Number',
              readOnly: true,
            ),
            const SizedBox(height: AppConstants.kSpaceMD),

            CustomTextField(
              name: 'email',
              label: 'Email Address',
              keyboardType: TextInputType.emailAddress,
              readOnly: !_isEmailEditable,
              // 🟢 Editable only when toggled
              validator: FormBuilderValidators.compose([
                FormBuilderValidators.required(),
                FormBuilderValidators.email(),
              ]),
            ),
            const SizedBox(height: AppConstants.kSpaceLG),

            // 🟢 Button is completely disabled (null) unless email is actively changed
            PrimaryButton(
              label: 'Save Changes',
              onPressed: isEmailChanged ? _saveProfile : null,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: const Duration(milliseconds: 400)).slideY(begin: 0.1);
  }

  Widget _buildChangePasswordSection() {
    // 🟢 Dynamic validation for password button
    final oldPw =
        _passwordFormKey.currentState?.fields['oldPassword']?.value
            as String? ??
        '';
    final newPw =
        _passwordFormKey.currentState?.fields['newPassword']?.value
            as String? ??
        '';
    final confirmPw =
        _passwordFormKey.currentState?.fields['confirmNewPassword']?.value
            as String? ??
        '';

    // Valid if all exist and new matches confirm
    final isPasswordReady =
        oldPw.isNotEmpty &&
        newPw.isNotEmpty &&
        confirmPw.isNotEmpty &&
        (newPw == confirmPw);

    return GlassContainer(
      padding: const EdgeInsets.all(AppConstants.kSpaceLG),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => setState(
              () => _isPasswordSectionExpanded = !_isPasswordSectionExpanded,
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
              // 🟢 Rebuild UI on every keystroke to evaluate password match
              onChanged: () => setState(() {}),
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
                    validator: AppValidators.password(),
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
                  // 🟢 Button is completely disabled (null) unless all inputs are valid
                  PrimaryButton(
                    label: 'Update Password',
                    backgroundColor: AppColors.kAccentPink,
                    onPressed: isPasswordReady ? _changePassword : null,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(delay: const Duration(milliseconds: 500)).slideY(begin: 0.1);
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
              icon: Icons.location_on_outlined,
              title: 'My Addresses',
              onTap: () {
                context.push('/addresses').then((_) {
                  if (context.mounted) {
                    context.read<ProfileBloc>().add(
                      const ProfileFetchRequested(),
                    );
                  }
                });
              },
            ),
            // 🟢 Notifications and About App Removed as requested!
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
