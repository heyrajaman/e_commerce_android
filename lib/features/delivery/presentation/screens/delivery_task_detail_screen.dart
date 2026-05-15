import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/utils/app_extensions.dart';
import '../../../../shared/widgets/mesh_gradient_background.dart';
import '../../data/models/delivery_task_model.dart';
import '../bloc/delivery_bloc.dart';
import '../bloc/delivery_event.dart';
import '../bloc/delivery_state.dart';

// Assuming you have a custom RadioGroup widget in your project
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
    // PROD MEMORY FIX: Added const constructor
    context.read<DeliveryBloc>().add(const FetchDeliveryTasks());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      elevation: 10,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) => _CodPaymentBottomSheet(task: widget.task),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) {
          // PROD MEMORY FIX: Added const constructor
          context.read<DeliveryBloc>().add(const FetchDeliveryTasks());
        }
      },
      child: MeshGradientBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: BlocConsumer<DeliveryBloc, DeliveryState>(
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
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.red,
                  ),
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
                              onPressed: isUpdating
                                  ? null
                                  : _handleUpdateStatus,
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
          ),
        ),
      ),
    );
  }

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
                        style: TextStyle(color: Colors.grey, fontSize: 14),
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
                      color: Colors.grey,
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
                        color: Colors.grey,
                        child: item.productImageUrl.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: item.productImageUrl.toEmulatorUrl,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.deepOrangeAccent,
                                  ),
                                ),
                                errorWidget: (context, url, error) =>
                                    const Icon(
                                      Icons.image_not_supported_outlined,
                                      color: Colors.grey,
                                    ),
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
                            style: TextStyle(color: Colors.grey, fontSize: 13),
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
      color: isPrepaid ? Colors.green : const Color(0xFFFFF3E0),
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
                  style: TextStyle(color: Colors.grey, fontSize: 13),
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
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 5),
                Text(
                  widget.task.type == 'RETURN_PICKUP'
                      ? '₹${widget.task.cashToRefund}'
                      : '₹${widget.task.cashToCollect}',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: isPrepaid ? Colors.green : Colors.deepOrange,
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

// SONARQUBE FIX: Extracted into a StatefulWidget to properly dispose of the UTR TextEditingController
class _CodPaymentBottomSheet extends StatefulWidget {
  final DeliveryTask task;

  const _CodPaymentBottomSheet({required this.task});

  @override
  State<_CodPaymentBottomSheet> createState() => _CodPaymentBottomSheetState();
}

class _CodPaymentBottomSheetState extends State<_CodPaymentBottomSheet> {
  String _selectedMode = 'CASH';
  final _utrController = TextEditingController();
  String? _utrError;

  @override
  void dispose() {
    _utrController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
        left: 24,
        right: 24,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Header
          const Text(
            'Collect Payment',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),

          // Amount
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '₹${widget.task.cashToCollect}',
              style: TextStyle(
                fontSize: 36,
                color: Colors.green.shade700,
                fontWeight: FontWeight.w900,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),

          // Radio Selection
          RadioGroup<String>(
            groupValue: _selectedMode,
            onChanged: (val) {
              if (val != null) {
                setState(() => _selectedMode = val);
                if (val == 'QR') {
                  context.read<DeliveryBloc>().add(
                    FetchDeliveryQRCode(orderId: widget.task.orderId),
                  );
                }
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
                    activeColor: Colors.green,
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: Text(
                      'QR Code',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    value: 'QR',
                    activeColor: Colors.green,
                  ),
                ),
              ],
            ),
          ),

          // QR Code Section
          if (_selectedMode == 'QR') ...[
            const SizedBox(height: 16),
            BlocBuilder<DeliveryBloc, DeliveryState>(
              buildWhen: (previous, current) =>
                  current is DeliveryQRLoading ||
                  current is DeliveryQRLoaded ||
                  current is DeliveryQRError,
              builder: (context, state) {
                if (state is DeliveryQRLoading) {
                  return const Padding(
                    padding: EdgeInsets.all(30.0),
                    child: Center(
                      child: CircularProgressIndicator(color: Colors.green),
                    ),
                  );
                } else if (state is DeliveryQRLoaded) {
                  return Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withValues(alpha: 0.15),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                          border: Border.all(
                            color: Colors.green.shade200,
                            width: 2,
                          ),
                        ),
                        child: QrImageView(
                          data: state.qrString,
                          version: QrVersions.auto,
                          size: 200.0,
                          backgroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.qr_code_scanner,
                            size: 18,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Scan using any UPI App',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                } else if (state is DeliveryQRError) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Failed to generate QR Code.\nPlease check backend Razorpay keys.',
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            const SizedBox(height: 24),

            // UTR Input
            TextField(
              controller: _utrController,
              decoration: InputDecoration(
                labelText: 'Enter 12-Digit UTR (Optional)',
                hintText: 'Manual verification',
                errorText: _utrError,
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(
                  Icons.numbers_rounded,
                  color: Colors.grey,
                ),
              ),
              keyboardType: TextInputType.number,
              maxLength: 12,
            ),
          ],

          const SizedBox(height: 24),

          // Submit Button
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade600, Colors.green.shade800],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: () {
                // PROD UX FIX: Dismiss keyboard
                FocusScope.of(context).unfocus();
                Navigator.pop(context);

                context.read<DeliveryBloc>().add(
                  UpdateDeliveryTaskStatus(
                    assignmentId: widget.task.assignmentId,
                    status: 'DELIVERED',
                    codPaymentMode: _selectedMode,
                    utrNumber:
                        _selectedMode == 'QR' && _utrController.text.isNotEmpty
                        ? _utrController.text
                        : null,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 20),
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Confirm Payment & Delivery',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
