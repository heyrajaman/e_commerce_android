class DeliveryTasksResponse {
  final List<DeliveryTask> active;
  final List<DeliveryTask> history;

  DeliveryTasksResponse({required this.active, required this.history});

  factory DeliveryTasksResponse.fromJson(Map<String, dynamic> json) {
    return DeliveryTasksResponse(
      active:
          (json['active'] as List?)
              ?.map((e) => DeliveryTask.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      history:
          (json['history'] as List?)
              ?.map((e) => DeliveryTask.fromJson(e as Map<String, dynamic>))
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
      status: json['status']?.toString() ?? '',
      type: json['type']?.toString() ?? 'DELIVERY',

      // PROD FIX: Safely cast to num first to prevent int-to-double cast crashes
      cashToCollect: (json['cashToCollect'] as num?)?.toDouble() ?? 0.0,
      cashToRefund: (json['cashToRefund'] as num?)?.toDouble() ?? 0.0,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,

      paymentMethod: json['paymentMethod']?.toString() ?? '',
      orderId: json['orderId'].toString(),
      customerName: json['customerName']?.toString() ?? 'Guest',
      address: json['address'] != null
          ? DeliveryAddress.fromJson(json['address'] as Map<String, dynamic>)
          : null,
      phone: json['phone']?.toString() ?? '',

      // PROD FIX: Safe Date parsing to prevent null reference crashes
      date: json['date'] != null
          ? DateTime.tryParse(json['date'].toString())?.toLocal() ??
                DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())?.toLocal() ??
                DateTime.now()
          : DateTime.now(),

      items:
          (json['items'] as List?)
              ?.map((e) => DeliveryTaskItem.fromJson(e as Map<String, dynamic>))
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

    String extractedImageUrl = '';
    if (productMap['images'] != null &&
        (productMap['images'] as List).isNotEmpty) {
      extractedImageUrl = productMap['images'].toString();
    }

    return DeliveryTaskItem(
      id: json['id'].toString(),
      productId: json['productId'].toString(),
      quantity: json['quantity'] as int? ?? 1,

      // PROD FIX: Safely parse num
      price: (json['price'] as num?)?.toDouble() ?? 0.0,

      status: json['status']?.toString() ?? '',
      refundStatus: json['refundStatus']?.toString(),
      returnReason: json['returnReason']?.toString(),
      refundMethod: json['refundMethod']?.toString(),
      productName: productMap['name']?.toString() ?? 'Unknown Product',
      productImageUrl: extractedImageUrl,
    );
  }
}

class DeliveryAddress {
  final String addressLine1;
  final String area;
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
      addressLine1: json['addressLine1']?.toString() ?? '',
      area: json['area']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
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

class DeliveryBoyProfile {
  final String id;
  final String name;
  final String phone;
  final String city;
  final String state;
  final int dailyOrderLimit;
  final List<String> assignedAreas;

  DeliveryBoyProfile({
    required this.id,
    required this.name,
    required this.phone,
    required this.city,
    required this.state,
    required this.dailyOrderLimit,
    required this.assignedAreas,
  });

  factory DeliveryBoyProfile.fromJson(Map<String, dynamic> json) {
    return DeliveryBoyProfile(
      id: json['id'].toString(),
      name: json['name']?.toString() ?? 'Unknown',
      phone: json['phone']?.toString() ?? 'N/A',
      city: json['city']?.toString() ?? 'N/A',
      state: json['state']?.toString() ?? 'N/A',
      dailyOrderLimit: json['maxOrders'] as int? ?? 0,

      assignedAreas:
          (json['assignedAreas'] as List?)?.map((e) => e.toString()).toList() ??
          [],
    );
  }
}
