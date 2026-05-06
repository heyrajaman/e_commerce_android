import 'package:equatable/equatable.dart';

abstract class DeliveryEvent extends Equatable {
  const DeliveryEvent();

  @override
  List<Object?> get props => [];
}

class FetchDeliveryTasks extends DeliveryEvent {}

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

  const FilterActiveTasks(this.filter);

  @override
  List<Object?> get props => [filter];
}

class FetchDeliveryProfile extends DeliveryEvent {}

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
