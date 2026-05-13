import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/order_bloc.dart';
import '../bloc/order_event.dart';

class ReturnRequestModal extends StatefulWidget {
  final String orderId;
  final String itemId;
  final String paymentMethod;

  const ReturnRequestModal({
    super.key,
    required this.orderId,
    required this.itemId,
    required this.paymentMethod,
  });

  @override
  State<ReturnRequestModal> createState() => _ReturnRequestModalState();
}

class _ReturnRequestModalState extends State<ReturnRequestModal> {
  String? _selectedReason;
  String _comments = '';

  String? _refundMethod; // For COD: BANK_TRANSFER or WAREHOUSE_COLLECT
  final _bankNameController = TextEditingController();
  final _accountController = TextEditingController();
  final _ifscController = TextEditingController();

  final List<String> _returnReasons = [
    "Received wrong item",
    "Item was damaged or defective",
    "Item doesn't match the description",
    "Quality is not as expected",
    "Missing parts or accessories",
    "Other",
  ];

  bool get _isCashPayment => widget.paymentMethod == 'COD';

  void _submitRequest() {
    if (_selectedReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a reason for the return')),
      );
      return;
    }

    if (_isCashPayment) {
      if (_refundMethod == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a refund method')),
        );
        return;
      }
      if (_refundMethod == 'BANK_TRANSFER' &&
          (_bankNameController.text.isEmpty ||
              _accountController.text.isEmpty ||
              _ifscController.text.isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill in all bank details')),
        );
        return;
      }
    }

    final reason = _selectedReason == 'Other' ? _comments : _selectedReason!;

    Map<String, dynamic>? bankDetails;
    if (_isCashPayment && _refundMethod == 'BANK_TRANSFER') {
      bankDetails = {
        'bankName': _bankNameController.text,
        'accountNo': _accountController.text,
        'ifsc': _ifscController.text,
      };
    }

    context.read<OrderBloc>().add(
      OrderRequestReturnEvent(
        orderId: widget.orderId,
        itemId: widget.itemId,
        reason: reason,
        paymentMethod: widget.paymentMethod,
        refundMethod: _refundMethod,
        bankDetails: bankDetails,
      ),
    );

    Navigator.pop(context); // Close the modal
  }

  @override
  void dispose() {
    _bankNameController.dispose();
    _accountController.dispose();
    _ifscController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Request Return',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Text(
                _isCashPayment
                    ? 'Since you paid via Cash/COD, please specify how you would like to receive your refund below.'
                    : 'Once approved, the refund will be automatically credited to your original payment source.',
                style: TextStyle(color: Colors.blue.shade800, fontSize: 13),
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'Why are you returning this?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // 🟢 FIXED: Wrapped the Return Reasons in a RadioGroup
            RadioGroup<String>(
              groupValue: _selectedReason,
              onChanged: (val) => setState(() => _selectedReason = val),
              child: Column(
                children: _returnReasons
                    .map(
                      (reason) => RadioListTile<String>(
                        title: Text(
                          reason,
                          style: const TextStyle(fontSize: 14),
                        ),
                        value: reason,
                        activeColor: Colors.orange,
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                    )
                    .toList(),
              ),
            ),

            if (_selectedReason == 'Other')
              Padding(
                padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Please specify the reason...',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  maxLines: 2,
                  onChanged: (val) => _comments = val,
                ),
              ),

            if (_isCashPayment) ...[
              const Divider(height: 30),
              const Text(
                'How do you want your refund?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              // 🟢 FIXED: Wrapped the Refund Methods in a RadioGroup
              RadioGroup<String>(
                groupValue: _refundMethod,
                onChanged: (val) => setState(() => _refundMethod = val),
                child: Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text(
                          'Bank Transfer',
                          style: TextStyle(fontSize: 13),
                        ),
                        value: 'BANK_TRANSFER',
                        activeColor: Colors.orange,
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text(
                          'Store Collect',
                          style: TextStyle(fontSize: 13),
                        ),
                        value: 'WAREHOUSE_COLLECT',
                        activeColor: Colors.orange,
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                    ),
                  ],
                ),
              ),

              if (_refundMethod == 'BANK_TRANSFER')
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: _bankNameController,
                        decoration: const InputDecoration(
                          hintText: 'Bank Name (e.g. HDFC)',
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _accountController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: 'Account Number',
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _ifscController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(
                          hintText: 'IFSC Code',
                          isDense: true,
                        ),
                      ),
                    ],
                  ),
                ),
            ],

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade600,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: _submitRequest,
                child: const Text(
                  'Submit Request',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
