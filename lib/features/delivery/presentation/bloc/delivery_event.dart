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
