import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/mesh_gradient_background.dart';
import '../../data/models/delivery_task_model.dart';
import '../bloc/delivery_bloc.dart';
import '../bloc/delivery_event.dart';
import '../bloc/delivery_state.dart';

// Assuming you have a custom RadioGroup widget in your project
// If not, ensure you have the implementation for it.
class DeliveryTaskDetailScreen extends StatefulWidget {
  final DeliveryTask task;

  const DeliveryTaskDetailScreen({super.key, required this.task});

  @override
  State<DeliveryTaskDetailScreen> createState() =>
      _DeliveryTaskDetailScreenState();
}

class _DeliveryTaskDetailScreenState extends State<DeliveryTaskDetailScreen> {
  String getNextStatus() {
    switch (widget.task.status) {
      case 'ASSIGNED':
        return 'PICKED';
      case 'PICKED':
        return 'OUT_FOR_DELIVERY';
      case 'OUT_FOR_DELIVERY':
        return 'DELIVERED';
      default:
        return '';
    }
  }

  String getButtonLabel() {
    final isReturn = widget.task.type == 'RETURN_PICKUP';
    switch (widget.task.status) {
      case 'ASSIGNED':
        return isReturn ? 'Mark as Picked Up' : 'Mark as Picked from Store';
      case 'PICKED':
        return 'Start Delivery';
      case 'OUT_FOR_DELIVERY':
        return isReturn ? 'Return to Warehouse' : 'Mark as Delivered';
      default:
        return 'Completed';
    }
  }

  void _handleUpdateStatus() {
    final nextStatus = getNextStatus();
    if (nextStatus.isEmpty) return;

    if (nextStatus == 'DELIVERED' &&
        widget.task.paymentMethod == 'COD' &&
        widget.task.type == 'DELIVERY') {
      _showCodPaymentBottomSheet();
    } else {
      context.read<DeliveryBloc>().add(
        UpdateDeliveryTaskStatus(
          assignmentId: widget.task.assignmentId,
          status: nextStatus,
        ),
      );
    }
  }

  void _showCodPaymentBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) {
        String selectedMode = 'CASH';
        final utrController = TextEditingController();
        String? utrError;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Collect Payment',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '₹${widget.task.cashToCollect}',
                    style: const TextStyle(
                      fontSize: 32,
                      color: Colors.green,
                      fontWeight: FontWeight.w900,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  RadioGroup<String>(
                    groupValue: selectedMode,
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() => selectedMode = val);
                      }
                    },
                    child: Row(
                      children: const [
                        Expanded(
                          child: RadioListTile<String>(
                            title: Text(
                              'Cash',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            value: 'CASH',
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<String>(
                            title: Text(
                              'QR Code',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            value: 'QR',
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (selectedMode == 'QR') ...[
                    const SizedBox(height: 16),
                    TextField(
                      controller: utrController,
                      decoration: InputDecoration(
                        labelText: 'Enter 12-Digit UTR Number',
                        errorText: utrError,
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: const Icon(Icons.numbers_rounded),
                      ),
                      keyboardType: TextInputType.number,
                      maxLength: 12,
                    ),
                  ],

                  const SizedBox(height: 30),
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.green, Color(0xFF1B5E20)],
                      ),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        if (selectedMode == 'QR' &&
                            utrController.text.length < 4) {
                          setModalState(
                            () => utrError = 'Please enter a valid UTR',
                          );
                          return;
                        }
                        Navigator.pop(context);
                        context.read<DeliveryBloc>().add(
                          UpdateDeliveryTaskStatus(
                            assignmentId: widget.task.assignmentId,
                            status: 'DELIVERED',
                            codPaymentMode: selectedMode,
                            utrNumber: selectedMode == 'QR'
                                ? utrController.text
                                : null,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text(
                        'Confirm Payment & Delivery',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DeliveryBloc, DeliveryState>(
      listener: (context, state) {
        if (state is DeliveryStatusUpdated) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.green,
            ),
          );
          context.pop();
        } else if (state is DeliveryError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      builder: (context, state) {
        final isUpdating = state is DeliveryStatusUpdating;

        return MeshGradientBackground(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              title: Text(
                'Order #${widget.task.orderId}',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: true,
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              child: Column(
                children: [
                  _buildCustomerCard(),
                  const SizedBox(height: 16),
                  _buildItemsList(),
                  const SizedBox(height: 16),
                  _buildPaymentSummary(),
                ],
              ),
            ),

            // 🟢 BEAUTIFUL ACTION BUTTON DESIGN
            bottomSheet:
                widget.task.status == 'DELIVERED' ||
                    widget.task.status == 'FAILED'
                ? null
                : Container(
                    height: 110,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 20,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 20,
                          offset: const Offset(0, -10),
                        ),
                      ],
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isUpdating
                              ? [Colors.grey, Colors.grey]
                              : [
                                  const Color(0xFFFF7043),
                                  const Color(0xFFF4511E),
                                ],
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          if (!isUpdating)
                            BoxShadow(
                              color: const Color(
                                0xFFFF7043,
                              ).withValues(alpha: 0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: isUpdating ? null : _handleUpdateStatus,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: isUpdating
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                getButtonLabel(),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                      ),
                    ),
                  ),
          ),
        );
      },
    );
  }

  // Helper widgets (_buildCustomerCard, _buildItemsList, _buildPaymentSummary)
  // stay the same as previous logic but with slightly improved padding/styling.

  Widget _buildCustomerCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Customer Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const Divider(height: 30),
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.deepOrangeAccent.withValues(
                    alpha: .1,
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Colors.deepOrangeAccent,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.task.customerName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.task.phone,
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.call, color: Colors.green, size: 20),
                    onPressed: () {},
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.location_on,
                  color: Colors.redAccent,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.task.address?.formattedAddress ??
                        'No address provided',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[800],
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsList() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.task.type == 'RETURN_PICKUP'
                  ? 'Items to Pickup'
                  : 'Items to Deliver',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const Divider(height: 30),
            ...widget.task.items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 15),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 55,
                        height: 55,
                        color: Colors.grey[100],
                        child: item.productImageUrl.isNotEmpty
                            ? Image.network(
                                item.productImageUrl,
                                fit: BoxFit.cover,
                              )
                            : const Icon(Icons.inventory_2, color: Colors.grey),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.productName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Quantity: ${item.quantity}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentSummary() {
    final isPrepaid =
        widget.task.paymentMethod != 'COD' || widget.task.cashToCollect == 0;
    return Card(
      elevation: 0,
      color: isPrepaid ? Colors.green[50] : const Color(0xFFFFF3E0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Payment Method',
                  style: TextStyle(color: Colors.grey[700], fontSize: 13),
                ),
                const SizedBox(height: 5),
                Text(
                  widget.task.paymentMethod,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  widget.task.type == 'RETURN_PICKUP'
                      ? 'To Refund'
                      : 'To Collect',
                  style: TextStyle(color: Colors.grey[700], fontSize: 13),
                ),
                const SizedBox(height: 5),
                Text(
                  widget.task.type == 'RETURN_PICKUP'
                      ? '₹${widget.task.cashToRefund}'
                      : '₹${widget.task.cashToCollect}',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: isPrepaid ? Colors.green[700] : Colors.deepOrange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
