import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/delivery_repository.dart';
import 'delivery_event.dart';
import 'delivery_state.dart';

class DeliveryBloc extends Bloc<DeliveryEvent, DeliveryState> {
  final DeliveryRepository repository;

  DeliveryBloc({required this.repository}) : super(DeliveryInitial()) {
    on<FetchDeliveryTasks>(_onFetchDeliveryTasks);
    on<UpdateDeliveryTaskStatus>(_onUpdateDeliveryTaskStatus);
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
          activeTasks: response.active,
          historyTasks: response.history,
        ),
      );
    } catch (e) {
      // Clean up the error message string
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
}
