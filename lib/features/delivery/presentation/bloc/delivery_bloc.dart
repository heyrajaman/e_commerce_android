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
    } catch (e) {
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      emit(DeliveryError(errorMsg));
    }
  }

  Future<void> _onUpdateDeliveryTaskStatus(
    UpdateDeliveryTaskStatus event,
    Emitter<DeliveryState> emit,
  ) async {
    emit(DeliveryStatusUpdating());
    try {
      await repository.updateTaskStatus(
        assignmentId: event.assignmentId,
        status: event.status,
        codPaymentMode: event.codPaymentMode,
        utrNumber: event.utrNumber,
      );

      emit(const DeliveryStatusUpdated("Task status updated!"));

      // Immediately fetch the tasks again so the UI refreshes
      add(FetchDeliveryTasks());
    } catch (e) {
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      emit(DeliveryError(errorMsg));

      // If it fails, fetch tasks again to reset the UI
      add(FetchDeliveryTasks());
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
    } catch (e) {
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      emit(DeliveryQRError(errorMsg));
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
        // Map the UI filter names to your backend exact statuses
        String targetStatus = '';

        // 🟢 FIX 3: Added curly braces { } to satisfy the linter
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
    } catch (e) {
      emit(DeliveryError(e.toString().replaceAll('Exception: ', '')));
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
      // Fetch profile again to reset the state back to loaded
      add(FetchDeliveryProfile());
    } catch (e) {
      emit(DeliveryError(e.toString().replaceAll('Exception: ', '')));
      add(FetchDeliveryProfile()); // Reset UI
    }
  }
}
