import 'package:equatable/equatable.dart';

import '../../../../shared/models/address_model.dart';
import '../../../../shared/models/user_model.dart';

sealed class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

class ProfileInitial extends ProfileState {
  const ProfileInitial();
}

class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

class ProfileLoaded extends ProfileState {
  final UserModel user;

  const ProfileLoaded(this.user);

  @override
  List<Object?> get props => [user];
}

class ProfileUpdating extends ProfileState {
  final UserModel user;

  const ProfileUpdating(this.user);

  @override
  List<Object?> get props => [user];
}

class ProfileUpdateSuccess extends ProfileState {
  final UserModel user;

  const ProfileUpdateSuccess(this.user);

  @override
  List<Object?> get props => [user];
}

class ProfilePasswordChangeSuccess extends ProfileState {
  const ProfilePasswordChangeSuccess();
}

class ProfileError extends ProfileState {
  final String message;

  const ProfileError(this.message);

  @override
  List<Object?> get props => [message];
}

// Make sure to import AddressModel!
class ProfileAddressesLoaded extends ProfileState {
  final List<AddressModel> addresses;

  const ProfileAddressesLoaded(this.addresses);

  @override
  List<Object?> get props => [addresses];
}

class ProfileAddressActionSuccess extends ProfileState {
  final String message;

  const ProfileAddressActionSuccess(this.message);

  @override
  List<Object?> get props => [message];
}
