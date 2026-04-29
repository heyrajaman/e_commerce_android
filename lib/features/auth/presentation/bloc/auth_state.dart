import 'package:equatable/equatable.dart';

import '../../../../shared/models/user_model.dart';

sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// The initial state when the app boots up before any checks are done
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// State when an API request (login, register, getMe) is in progress
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// State when a user is successfully logged in and we have their profile data
class AuthAuthenticated extends AuthState {
  final UserModel user;

  const AuthAuthenticated(this.user);

  @override
  List<Object?> get props => [user];
}

/// State when no user is logged in, or the token has expired
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// State when an error occurs during login, registration, or fetching profile
class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}
