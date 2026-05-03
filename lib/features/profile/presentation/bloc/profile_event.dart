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

class ProfileAddressesFetchRequested extends ProfileEvent {}

class ProfileAddressAddRequested extends ProfileEvent {
  final String addressLine1;
  final String state;
  final String city;
  final String area;
  final bool isDefault;

  const ProfileAddressAddRequested({
    required this.addressLine1,
    required this.state,
    required this.city,
    required this.area,
    required this.isDefault,
  });

  @override
  List<Object?> get props => [addressLine1, state, city, area, isDefault];
}

class ProfileAddressDeleteRequested extends ProfileEvent {
  final String addressId;

  const ProfileAddressDeleteRequested(this.addressId);

  @override
  List<Object?> get props => [addressId];
}
