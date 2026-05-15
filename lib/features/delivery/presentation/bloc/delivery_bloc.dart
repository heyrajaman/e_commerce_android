import 'dart:developer' as developer; // PROD FIX: Secure logging

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/delivery_task_model.dart';
import '../../data/repositories/delivery_repository.dart';
import 'delivery_event.dart';
import 'delivery_state.dart';

class DeliveryBloc extends Bloc<DeliveryEvent, DeliveryState> {
  final DeliveryRepository repository;

  DeliveryBloc({required this.repository}) : super(DeliveryInitial()) {
    on<FetchDeliveryTasks>(_onFetchDeliveryTasks);
    on<UpdateDeliveryTaskStatus>(_onUpdateDeliveryTaskStatus);
    on<FetchDeliveryQRCode>(_onFetchDeliveryQRCode);
    on<FilterActiveTasks>(_onFilterActiveTasks);
    on<FetchDeliveryProfile>(_onFetchDeliveryProfile);
    on<ChangeDeliveryPassword>(_onChangeDeliveryPassword);
  }

  Future<void> _onFetchDeliveryTasks(
    FetchDeliveryTasks event,
    Emitter<DeliveryState> emit,
  ) async {
    emit(DeliveryLoading());
    try {
      final response = await repository.getMyTasks();
      emit(
        DeliveryLoaded(
          allActiveTasks: response.active,
          filteredActiveTasks: response.active,
          historyTasks: response.history,
          activeFilter: 'All',
        ),
      );
    } catch (e, stack) {
      developer.log(
        'Delivery tasks fetch failed',
        error: e,
        stackTrace: stack,
        name: 'DeliveryBloc',
      );
      // SONARQUBE FIX: Removed hacky string manipulation since the repo now throws clean ServerExceptions
      emit(DeliveryError(e.toString()));
    }
  }

  Future<void> _onUpdateDeliveryTaskStatus(
    UpdateDeliveryTaskStatus event,
    Emitter<DeliveryState> emit,
  ) async {
    // PROD UX FIX: Cache the current state so we don't destroy the UI if the update fails
    DeliveryLoaded? previousState;
    if (state is DeliveryLoaded) {
      previousState = state as DeliveryLoaded;
    }

    emit(DeliveryStatusUpdating());
    try {
      await repository.updateTaskStatus(
        assignmentId: event.assignmentId,
        status: event.status,
        codPaymentMode: event.codPaymentMode,
        utrNumber: event.utrNumber,
      );

      emit(const DeliveryStatusUpdated("Task status updated!"));
      add(FetchDeliveryTasks());
    } catch (e, stack) {
      developer.log(
        'Update task status failed',
        error: e,
        stackTrace: stack,
        name: 'DeliveryBloc',
      );
      emit(DeliveryError(e.toString()));

      // If we had a previous state, restore it immediately so the screen doesn't stay blank
      if (previousState != null) {
        emit(previousState);
      } else {
        add(FetchDeliveryTasks());
      }
    }
  }

  Future<void> _onFetchDeliveryQRCode(
    FetchDeliveryQRCode event,
    Emitter<DeliveryState> emit,
  ) async {
    emit(DeliveryQRLoading());
    try {
      final qrString = await repository.getDeliveryQRCode(event.orderId);
      emit(DeliveryQRLoaded(qrString: qrString));
    } catch (e, stack) {
      developer.log(
        'QR Code fetch failed',
        error: e,
        stackTrace: stack,
        name: 'DeliveryBloc',
      );
      emit(DeliveryQRError(e.toString()));
    }
  }

  void _onFilterActiveTasks(
    FilterActiveTasks event,
    Emitter<DeliveryState> emit,
  ) {
    final currentState = state;
    if (currentState is DeliveryLoaded) {
      List<DeliveryTask> filtered;

      if (event.filter == 'All') {
        filtered = currentState.allActiveTasks;
      } else {
        String targetStatus = '';

        if (event.filter == 'Assigned') {
          targetStatus = 'ASSIGNED';
        }
        if (event.filter == 'Picked') {
          targetStatus = 'PICKED';
        }
        if (event.filter == 'Out for Delivery') {
          targetStatus = 'OUT_FOR_DELIVERY';
        }

        filtered = currentState.allActiveTasks
            .where((task) => task.status == targetStatus)
            .toList();
      }

      emit(
        currentState.copyWith(
          filteredActiveTasks: filtered,
          activeFilter: event.filter,
        ),
      );
    }
  }

  Future<void> _onFetchDeliveryProfile(
    FetchDeliveryProfile event,
    Emitter<DeliveryState> emit,
  ) async {
    emit(DeliveryProfileLoading());
    try {
      final profile = await repository.getDeliveryProfile();
      emit(DeliveryProfileLoaded(profile: profile));
    } catch (e, stack) {
      developer.log(
        'Profile fetch failed',
        error: e,
        stackTrace: stack,
        name: 'DeliveryBloc',
      );
      emit(DeliveryError(e.toString()));
    }
  }

  Future<void> _onChangeDeliveryPassword(
    ChangeDeliveryPassword event,
    Emitter<DeliveryState> emit,
  ) async {
    emit(DeliveryPasswordChanging());
    try {
      await repository.changePassword(
        oldPassword: event.oldPassword,
        newPassword: event.newPassword,
      );
      emit(const DeliveryPasswordChanged("Password updated successfully!"));
      add(FetchDeliveryProfile());
    } catch (e, stack) {
      developer.log(
        'Password change failed',
        error: e,
        stackTrace: stack,
        name: 'DeliveryBloc',
      );
      emit(DeliveryError(e.toString()));
      add(FetchDeliveryProfile());
    }
  }
}
