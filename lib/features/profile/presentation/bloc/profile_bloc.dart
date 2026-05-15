import 'dart:developer' as developer; // PROD FIX: Secure logging

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
  final AuthBloc _authBloc;

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
    } catch (e, stack) {
      developer.log(
        'Profile fetch failed',
        error: e,
        stackTrace: stack,
        name: 'ProfileBloc',
      );
      emit(ProfileError(e.toString()));
    }
  }

  Future<void> _onProfileUpdateRequested(
    ProfileUpdateRequested event,
    Emitter<ProfileState> emit,
  ) async {
    if (state is ProfileLoaded) {
      emit(ProfileUpdating((state as ProfileLoaded).user));
    } else if (state is ProfileUpdateSuccess) {
      emit(ProfileUpdating((state as ProfileUpdateSuccess).user));
    }

    try {
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
    } catch (e, stack) {
      developer.log(
        'Profile update failed',
        error: e,
        stackTrace: stack,
        name: 'ProfileBloc',
      );
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
    final currentUser = (state is ProfileLoaded)
        ? (state as ProfileLoaded).user
        : (state is ProfileUpdateSuccess
              ? (state as ProfileUpdateSuccess).user
              : null);

    // PROD UX FIX: Emit the updating state so the UI button shows a loading spinner!
    if (currentUser != null) {
      emit(ProfileUpdating(currentUser));
    }

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

      _authBloc.add(const AuthLogoutRequested());
    } catch (e, stack) {
      developer.log(
        'Password change failed',
        error: e,
        stackTrace: stack,
        name: 'ProfileBloc',
      );
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
    } catch (e, stack) {
      developer.log(
        'Addresses fetch failed',
        error: e,
        stackTrace: stack,
        name: 'ProfileBloc',
      );
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
      add(ProfileAddressesFetchRequested());
    } catch (e, stack) {
      developer.log(
        'Address add failed',
        error: e,
        stackTrace: stack,
        name: 'ProfileBloc',
      );
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
      add(ProfileAddressesFetchRequested());
    } catch (e, stack) {
      developer.log(
        'Address delete failed',
        error: e,
        stackTrace: stack,
        name: 'ProfileBloc',
      );
      emit(ProfileError(e.toString()));
    }
  }
}
