import 'package:equatable/equatable.dart';

// PROD ARCHITECTURE FIX: Upgraded to 'sealed class' for exhaustive matching
sealed class DeliveryEvent extends Equatable {
  const DeliveryEvent();

  @override
  List<Object?> get props => [];
}

class FetchDeliveryTasks extends DeliveryEvent {
  // PROD MEMORY FIX: Added const constructor
  const FetchDeliveryTasks();
}

class UpdateDeliveryTaskStatus extends DeliveryEvent {
  final String assignmentId;
  final String status;
  final String? codPaymentMode;
  final String? utrNumber;

  const UpdateDeliveryTaskStatus({
    required this.assignmentId,
    required this.status,
    this.codPaymentMode,
    this.utrNumber,
  });

  @override
  List<Object?> get props => [assignmentId, status, codPaymentMode, utrNumber];
}

class FetchDeliveryQRCode extends DeliveryEvent {
  final String orderId;

  const FetchDeliveryQRCode({required this.orderId});

  @override
  List<Object?> get props => [orderId];
}

class FilterActiveTasks extends DeliveryEvent {
  final String filter;

  // SONARQUBE FIX: Switched to named parameters for consistency
  const FilterActiveTasks({required this.filter});

  @override
  List<Object?> get props => [filter];
}

class FetchDeliveryProfile extends DeliveryEvent {
  // PROD MEMORY FIX: Added const constructor
  const FetchDeliveryProfile();
}

class ChangeDeliveryPassword extends DeliveryEvent {
  final String oldPassword;
  final String newPassword;

  const ChangeDeliveryPassword({
    required this.oldPassword,
    required this.newPassword,
  });

  @override
  List<Object?> get props => [oldPassword, newPassword];
}
