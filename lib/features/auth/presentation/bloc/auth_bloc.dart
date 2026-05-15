import 'dart:developer' as developer;

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/services/storage_service.dart';
import '../../data/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  final StorageService _storageService;

  AuthBloc({
    required AuthRepository authRepository,
    required StorageService storageService,
  }) : _authRepository = authRepository,
       _storageService = storageService,
       super(const AuthInitial()) {
    on<AuthCheckStatusRequested>(_onCheckStatusRequested);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthRegisterRequested>(_onRegisterRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthDeliveryLoginRequested>(_onDeliveryLoginRequested);
  }

  Future<void> _onCheckStatusRequested(
    AuthCheckStatusRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final token = await _storageService.getToken();
      if (token == null || token.isEmpty) {
        emit(const AuthUnauthenticated());
        return;
      }

      // Token exists, verify it by fetching the user profile
      final user = await _authRepository.getMe();
      emit(AuthAuthenticated(user));
    } catch (e, stack) {
      developer.log(
        'Auth check failed. User may be offline or token invalid.',
        error: e,
        stackTrace: stack,
        name: 'AuthBloc',
      );
      // PROD FIX: Do NOT clear storage here! If the user is just offline,
      // we don't want to delete their session. If the token is actually invalid (401),
      // the ApiClient interceptor will handle clearing the storage automatically.
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final user = await _authRepository.login(event.phone, event.password);
      emit(AuthAuthenticated(user));
    } catch (e, stack) {
      developer.log(
        'Login failed',
        error: e,
        stackTrace: stack,
        name: 'AuthBloc',
      );
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final user = await _authRepository.register(
        event.name,
        event.email,
        event.password,
        event.phone,
      );
      emit(AuthAuthenticated(user));
    } catch (e, stack) {
      developer.log(
        'Registration failed',
        error: e,
        stackTrace: stack,
        name: 'AuthBloc',
      );
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      // The AuthRepository.logout() now safely handles both the API call
      // AND the local storage clearing inside its own finally block.
      await _authRepository.logout();
    } catch (e, stack) {
      developer.log(
        'Logout encountered an error',
        error: e,
        stackTrace: stack,
        name: 'AuthBloc',
      );
    } finally {
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onDeliveryLoginRequested(
    AuthDeliveryLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final user = await _authRepository.loginDeliveryBoy(
        event.phone,
        event.password,
      );
      emit(AuthAuthenticated(user));
    } catch (e, stack) {
      developer.log(
        'Delivery login failed',
        error: e,
        stackTrace: stack,
        name: 'AuthBloc',
      );
      emit(AuthError(e.toString()));
    }
  }
}
