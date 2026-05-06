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
  final List<DeliveryTask> allActiveTasks;
  final List<DeliveryTask> filteredActiveTasks;
  final List<DeliveryTask> historyTasks;
  final String activeFilter;

  const DeliveryLoaded({
    required this.allActiveTasks,
    required this.filteredActiveTasks,
    required this.historyTasks,
    this.activeFilter = 'All',
  });

  @override
  List<Object?> get props => [
    allActiveTasks,
    filteredActiveTasks,
    historyTasks,
    activeFilter,
  ];

  DeliveryLoaded copyWith({
    List<DeliveryTask>? allActiveTasks,
    List<DeliveryTask>? filteredActiveTasks,
    List<DeliveryTask>? historyTasks,
    String? activeFilter,
  }) {
    return DeliveryLoaded(
      allActiveTasks: allActiveTasks ?? this.allActiveTasks,
      filteredActiveTasks: filteredActiveTasks ?? this.filteredActiveTasks,
      historyTasks: historyTasks ?? this.historyTasks,
      activeFilter: activeFilter ?? this.activeFilter,
    );
  }
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

class DeliveryQRLoading extends DeliveryState {}

class DeliveryQRLoaded extends DeliveryState {
  final String qrString;

  const DeliveryQRLoaded({required this.qrString});

  @override
  List<Object?> get props => [qrString];
}

class DeliveryQRError extends DeliveryState {
  final String message;

  const DeliveryQRError(this.message);

  @override
  List<Object?> get props => [message];
}

class DeliveryProfileLoading extends DeliveryState {}

class DeliveryProfileLoaded extends DeliveryState {
  final DeliveryBoyProfile profile;

  const DeliveryProfileLoaded({required this.profile});

  @override
  List<Object?> get props => [profile];
}

class DeliveryPasswordChanging extends DeliveryState {}

class DeliveryPasswordChanged extends DeliveryState {
  final String message;

  const DeliveryPasswordChanged(this.message);

  @override
  List<Object?> get props => [message];
}
