import 'package:equatable/equatable.dart';

import '../../data/models/delivery_task_model.dart';

// PROD ARCHITECTURE FIX: Upgraded to 'sealed class' for exhaustive matching
sealed class DeliveryState extends Equatable {
  const DeliveryState();

  @override
  List<Object?> get props => [];
}

class DeliveryInitial extends DeliveryState {
  const DeliveryInitial();
}

class DeliveryLoading extends DeliveryState {
  const DeliveryLoading();
}

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

class DeliveryStatusUpdating extends DeliveryState {
  const DeliveryStatusUpdating();
}

class DeliveryStatusUpdated extends DeliveryState {
  final String message;

  const DeliveryStatusUpdated(this.message);

  @override
  List<Object?> get props => [message];
}

class DeliveryQRLoading extends DeliveryState {
  const DeliveryQRLoading();
}

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

class DeliveryProfileLoading extends DeliveryState {
  const DeliveryProfileLoading();
}

class DeliveryProfileLoaded extends DeliveryState {
  final DeliveryBoyProfile profile;

  const DeliveryProfileLoaded({required this.profile});

  @override
  List<Object?> get props => [profile];
}

class DeliveryPasswordChanging extends DeliveryState {
  const DeliveryPasswordChanging();
}

class DeliveryPasswordChanged extends DeliveryState {
  final String message;

  const DeliveryPasswordChanged(this.message);

  @override
  List<Object?> get props => [message];
}
