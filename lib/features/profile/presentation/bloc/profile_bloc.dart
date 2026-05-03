import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../data/repositories/profile_repository.dart';
import 'profile_event.dart';
import 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final ProfileRepository _profileRepository;
  final AuthBloc
  _authBloc; // Injected to easily force a logout on password change

  ProfileBloc({
    required ProfileRepository profileRepository,
    required AuthBloc authBloc,
  }) : _profileRepository = profileRepository,
       _authBloc = authBloc,
       super(const ProfileInitial()) {
    on<ProfileFetchRequested>(_onProfileFetchRequested);
    on<ProfileUpdateRequested>(_onProfileUpdateRequested);
    on<ProfilePasswordChangeRequested>(_onProfilePasswordChangeRequested);
    on<ProfileAddressesFetchRequested>(_onAddressesFetchRequested);
    on<ProfileAddressAddRequested>(_onAddressAddRequested);
    on<ProfileAddressDeleteRequested>(_onAddressDeleteRequested);
  }

  Future<void> _onProfileFetchRequested(
    ProfileFetchRequested event,
    Emitter<ProfileState> emit,
  ) async {
    if (state is! ProfileLoaded && state is! ProfileUpdateSuccess) {
      emit(const ProfileLoading());
    }
    try {
      final user = await _profileRepository.getProfile();
      emit(ProfileLoaded(user));
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }

  Future<void> _onProfileUpdateRequested(
    ProfileUpdateRequested event,
    Emitter<ProfileState> emit,
  ) async {
    // Keep the current user data visible while updating
    if (state is ProfileLoaded) {
      emit(ProfileUpdating((state as ProfileLoaded).user));
    } else if (state is ProfileUpdateSuccess) {
      emit(ProfileUpdating((state as ProfileUpdateSuccess).user));
    }

    try {
      // CRITICAL FIX: Only pass email and imageFile (2 arguments)
      final updatedUser = await _profileRepository.updateProfile(
        event.email,
        event.imageFile,
      );

      emit(ProfileUpdateSuccess(updatedUser));

      Fluttertoast.showToast(
        msg: "Profile updated successfully!",
        backgroundColor: Colors.green.shade600,
        textColor: Colors.white,
      );
    } catch (e) {
      // Revert to loaded state on error so the UI doesn't break
      if (state is ProfileUpdating) {
        emit(ProfileLoaded((state as ProfileUpdating).user));
      } else {
        emit(ProfileError(e.toString()));
      }

      Fluttertoast.showToast(
        msg: e.toString(),
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  Future<void> _onProfilePasswordChangeRequested(
    ProfilePasswordChangeRequested event,
    Emitter<ProfileState> emit,
  ) async {
    // Capture current user so we don't lose the profile view during the network call
    final currentUser = (state is ProfileLoaded)
        ? (state as ProfileLoaded).user
        : (state is ProfileUpdateSuccess
              ? (state as ProfileUpdateSuccess).user
              : null);

    try {
      await _profileRepository.changePassword(
        event.oldPassword,
        event.newPassword,
      );

      emit(const ProfilePasswordChangeSuccess());

      Fluttertoast.showToast(
        msg: "Password changed. Please log in again.",
        backgroundColor: Colors.green.shade600,
        textColor: Colors.white,
      );

      // Force user to log in again with their new credentials
      _authBloc.add(const AuthLogoutRequested());
    } catch (e) {
      if (currentUser != null) {
        emit(ProfileLoaded(currentUser));
      } else {
        emit(ProfileError(e.toString()));
      }

      Fluttertoast.showToast(
        msg: e.toString(),
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  Future<void> _onAddressesFetchRequested(
    ProfileAddressesFetchRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(const ProfileLoading());
    try {
      final addresses = await _profileRepository.getAddresses();
      emit(ProfileAddressesLoaded(addresses));
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }

  Future<void> _onAddressAddRequested(
    ProfileAddressAddRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(const ProfileLoading());
    try {
      await _profileRepository.addAddress(
        event.addressLine1,
        event.state,
        event.city,
        event.area,
        event.isDefault,
      );
      emit(const ProfileAddressActionSuccess("Address added successfully!"));
      add(ProfileAddressesFetchRequested()); // Refresh the list
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }

  Future<void> _onAddressDeleteRequested(
    ProfileAddressDeleteRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(const ProfileLoading());
    try {
      await _profileRepository.deleteAddress(event.addressId);
      emit(const ProfileAddressActionSuccess("Address deleted."));
      add(ProfileAddressesFetchRequested()); // Refresh the list
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }
}
