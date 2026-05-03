import 'dart:io';

import 'package:equatable/equatable.dart';

sealed class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

class ProfileFetchRequested extends ProfileEvent {
  const ProfileFetchRequested();
}

class ProfileUpdateRequested extends ProfileEvent {
  final String email;
  final File? imageFile;

  const ProfileUpdateRequested({required this.email, this.imageFile});

  @override
  List<Object?> get props => [email, imageFile];
}

class ProfilePasswordChangeRequested extends ProfileEvent {
  final String oldPassword;
  final String newPassword;

  const ProfilePasswordChangeRequested({
    required this.oldPassword,
    required this.newPassword,
  });

  @override
  List<Object?> get props => [oldPassword, newPassword];
}
