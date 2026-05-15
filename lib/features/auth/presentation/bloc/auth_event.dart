import 'package:equatable/equatable.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object> get props => [];
}

/// Dispatched when the app starts to check if a valid token exists
class AuthCheckStatusRequested extends AuthEvent {
  const AuthCheckStatusRequested();
}

/// Dispatched when the user submits the login form
class AuthLoginRequested extends AuthEvent {
  final String phone;
  final String password;

  const AuthLoginRequested({required this.phone, required this.password});

  @override
  List<Object> get props => [phone, password];

  // PROD SECURITY FIX: Prevent plain-text passwords from leaking into system logs or analytics
  @override
  String toString() => 'AuthLoginRequested(phone: $phone, password: ***)';
}

/// Dispatched when the delivery boy submits the login form
class AuthDeliveryLoginRequested extends AuthEvent {
  final String phone;
  final String password;

  // SonarQube Fix: Converted to named parameters to maintain consistency with other events
  const AuthDeliveryLoginRequested({
    required this.phone,
    required this.password,
  });

  @override
  List<Object> get props => [phone, password];

  // PROD SECURITY FIX: Prevent plain-text passwords from leaking
  @override
  String toString() =>
      'AuthDeliveryLoginRequested(phone: $phone, password: ***)';
}

/// Dispatched when the user submits the registration form
class AuthRegisterRequested extends AuthEvent {
  final String name;
  final String email;
  final String password;
  final String phone;

  const AuthRegisterRequested({
    required this.name,
    required this.email,
    required this.password,
    required this.phone,
  });

  @override
  List<Object> get props => [name, email, password, phone];

  // PROD SECURITY FIX: Prevent plain-text passwords from leaking
  @override
  String toString() =>
      'AuthRegisterRequested(name: $name, email: $email, phone: $phone, password: ***)';
}

/// Dispatched when the user clicks the logout button
class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}
