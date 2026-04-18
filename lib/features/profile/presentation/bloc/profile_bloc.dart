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
  final AuthBloc _authBloc; // Injected to easily force a logout on password change

  ProfileBloc({
    required ProfileRepository profileRepository,
    required AuthBloc authBloc,
  })  : _profileRepository = profileRepository,
        _authBloc = authBloc,
        super(const ProfileInitial()) {
    on<ProfileFetchRequested>(_onProfileFetchRequested);
    on<ProfileUpdateRequested>(_onProfileUpdateRequested);
    on<ProfilePasswordChangeRequested>(_onProfilePasswordChangeRequested);
  }

  Future<void> _onProfileFetchRequested(
      ProfileFetchRequested event,
      Emitter<ProfileState> emit,
      ) async {
    emit(const ProfileLoading());
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
      final updatedUser = await _profileRepository.updateProfile(
        event.name,
        event.phone,
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
        : (state is ProfileUpdateSuccess ? (state as ProfileUpdateSuccess).user : null);

    try {
      await _profileRepository.changePassword(event.oldPassword, event.newPassword);

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
}