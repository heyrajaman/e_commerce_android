import 'package:equatable/equatable.dart';

import '../../data/models/delivery_task_model.dart';

abstract class DeliveryState extends Equatable {
  const DeliveryState();

  @override
  List<Object?> get props => [];
}

class DeliveryInitial extends DeliveryState {}

class DeliveryLoading extends DeliveryState {}

class DeliveryLoaded extends DeliveryState {
  final List<DeliveryTask> activeTasks;
  final List<DeliveryTask> historyTasks;

  const DeliveryLoaded({required this.activeTasks, required this.historyTasks});

  @override
  List<Object?> get props => [activeTasks, historyTasks];
}

class DeliveryError extends DeliveryState {
  final String message;

  const DeliveryError(this.message);

  @override
  List<Object?> get props => [message];
}

class DeliveryStatusUpdating extends DeliveryState {}

class DeliveryStatusUpdated extends DeliveryState {
  final String message;

  const DeliveryStatusUpdated(this.message);

  @override
  List<Object?> get props => [message];
}
