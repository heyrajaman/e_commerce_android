class DeliveryTasksResponse {
  final List<DeliveryTask> active;
  final List<DeliveryTask> history;

  DeliveryTasksResponse({required this.active, required this.history});

  factory DeliveryTasksResponse.fromJson(Map<String, dynamic> json) {
    return DeliveryTasksResponse(
      active:
          (json['active'] as List?)
              ?.map((e) => DeliveryTask.fromJson(e))
              .toList() ??
          [],
      history:
          (json['history'] as List?)
              ?.map((e) => DeliveryTask.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class DeliveryTask {
  final String assignmentId;
  final String status;
  final String type; // "DELIVERY" or "RETURN_PICKUP"
  final double cashToCollect;
  final double cashToRefund;
  final double amount;
  final String paymentMethod;
  final String orderId;
  final String customerName;
  final DeliveryAddress? address;
  final String phone;
  final DateTime date;
  final DateTime updatedAt;
  final List<DeliveryTaskItem> items;

  DeliveryTask({
    required this.assignmentId,
    required this.status,
    required this.type,
    required this.cashToCollect,
    required this.cashToRefund,
    required this.amount,
    required this.paymentMethod,
    required this.orderId,
    required this.customerName,
    this.address,
    required this.phone,
    required this.date,
    required this.updatedAt,
    required this.items,
  });

  factory DeliveryTask.fromJson(Map<String, dynamic> json) {
    return DeliveryTask(
      assignmentId: json['assignmentId'].toString(),
      status: json['status'] ?? '',
      type: json['type'] ?? 'DELIVERY',
      cashToCollect: (json['cashToCollect'] ?? 0).toDouble(),
      cashToRefund: (json['cashToRefund'] ?? 0).toDouble(),
      amount: (json['amount'] ?? 0).toDouble(),
      paymentMethod: json['paymentMethod'] ?? '',
      orderId: json['orderId'].toString(),
      customerName: json['customerName'] ?? 'Guest',
      address: json['address'] != null
          ? DeliveryAddress.fromJson(json['address'])
          : null,
      phone: json['phone'] ?? '',
      date: DateTime.parse(json['date']),
      updatedAt: DateTime.parse(json['updatedAt']),
      items:
          (json['items'] as List?)
              ?.map((e) => DeliveryTaskItem.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class DeliveryTaskItem {
  final String id;
  final String productId;
  final int quantity;
  final double price;
  final String status;

  // Added these three to match your backend perfectly for Return Pickups!
  final String? refundStatus;
  final String? returnReason;
  final String? refundMethod;
  final String productName;
  final String productImageUrl;

  DeliveryTaskItem({
    required this.id,
    required this.productId,
    required this.quantity,
    required this.price,
    required this.status,
    this.refundStatus,
    this.returnReason,
    this.refundMethod,
    required this.productName,
    required this.productImageUrl,
  });

  factory DeliveryTaskItem.fromJson(Map<String, dynamic> json) {
    final productMap = json['Product'] as Map<String, dynamic>? ?? {};

    return DeliveryTaskItem(
      id: json['id'].toString(),
      productId: json['productId'].toString(),
      quantity: json['quantity'] ?? 1,
      price: (json['price'] ?? 0).toDouble(),
      status: json['status'] ?? '',
      refundStatus: json['refundStatus'],
      returnReason: json['returnReason'],
      refundMethod: json['refundMethod'],
      productName: productMap['name'] ?? 'Unknown Product',
      productImageUrl: productMap['imageUrl'] ?? '',
    );
  }
}

class DeliveryAddress {
  final String addressLine1;
  final String area; // 🟢 ADDED to match backend
  final String city;
  final String state;

  DeliveryAddress({
    required this.addressLine1,
    required this.area,
    required this.city,
    required this.state,
  });

  factory DeliveryAddress.fromJson(Map<String, dynamic> json) {
    return DeliveryAddress(
      addressLine1: json['addressLine1'] ?? '',
      area: json['area'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
    );
  }

  String get formattedAddress {
    final parts = [
      addressLine1,
      area,
      city,
      state,
    ].where((part) => part.isNotEmpty).toList();
    return parts.join(', ');
  }
}
