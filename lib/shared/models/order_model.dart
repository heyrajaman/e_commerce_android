import 'package:equatable/equatable.dart';

enum OrderStatus {
  pending,
  confirmed,
  shipped,
  delivered,
  cancelled,
  returned; // 🟢 Added 'returned' to the enum

  // Helper to parse from JSON string
  static OrderStatus fromString(String status) {
    switch (status.toUpperCase()) {
      case 'PACKED':
        return OrderStatus.confirmed;
      case 'OUT_FOR_DELIVERY':
        return OrderStatus.shipped;
      case 'DELIVERED':
        return OrderStatus.delivered;
      case 'CANCELLED':
      case 'PARTIALLY_CANCELLED':
        return OrderStatus.cancelled;
      case 'RETURN_REQUESTED':
      case 'RETURNED':
        return OrderStatus.returned;
      case 'PROCESSING':
      case 'PENDING':
      default:
        return OrderStatus.pending;
    }
  }

  String toJsonString() => name;
}

class ShippingAddressModel extends Equatable {
  final String fullName;
  final String phone;
  final String addressLine1;
  final String? addressLine2;
  final String city;
  final String state;

  const ShippingAddressModel({
    required this.fullName,
    required this.phone,
    required this.addressLine1,
    this.addressLine2,
    required this.city,
    required this.state,
  });

  factory ShippingAddressModel.fromJson(Map<String, dynamic> json) {
    return ShippingAddressModel(
      fullName: json['fullName']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      addressLine1:
          json['addressLine1']?.toString() ?? json['address']?.toString() ?? '',
      addressLine2: json['addressLine2']?.toString(),
      city: json['city']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'phone': phone,
      'addressLine1': addressLine1,
      'addressLine2': addressLine2,
      'city': city,
      'state': state,
    };
  }

  @override
  List<Object?> get props => [
    fullName,
    phone,
    addressLine1,
    addressLine2,
    city,
    state,
  ];
}

class OrderItemModel extends Equatable {
  final String itemId;
  final String productId;
  final String name;
  final String image;
  final double price;
  final int quantity;

  const OrderItemModel({
    required this.itemId,
    required this.productId,
    required this.name,
    required this.image,
    required this.price,
    required this.quantity,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      itemId: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      productId:
          json['productId']?.toString() ?? json['product']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      image: json['image']?.toString() ?? '',
      price: (json['price'] ?? 0).toDouble(),
      quantity: json['quantity'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': itemId,
      'productId': productId,
      'name': name,
      'image': image,
      'price': price,
      'quantity': quantity,
    };
  }

  @override
  List<Object?> get props => [itemId, productId, name, image, price, quantity];
}

class OrderModel extends Equatable {
  final String id;
  final List<OrderItemModel> items;
  final ShippingAddressModel shippingAddress;
  final String paymentMethod;
  final double totalAmount;
  final double shippingCharge;
  final OrderStatus status;
  final DateTime createdAt;
  final String? trackingInfo;

  const OrderModel({
    required this.id,
    required this.items,
    required this.shippingAddress,
    required this.paymentMethod,
    required this.totalAmount,
    required this.shippingCharge,
    required this.status,
    required this.createdAt,
    this.trackingInfo,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    // 🟢 FIX: Look for 'OrderItems', 'orderItems', AND 'items' to fix the "0 items" bug
    final itemsList =
        json['items'] ?? json['OrderItems'] ?? json['orderItems'] ?? [];

    return OrderModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      items: List<OrderItemModel>.from(
        (itemsList as List).map((x) => OrderItemModel.fromJson(x)),
      ),
      shippingAddress: ShippingAddressModel.fromJson(
        json['shippingAddress'] ?? json['address'] ?? {},
      ),
      paymentMethod: json['paymentMethod']?.toString() ?? 'COD',
      totalAmount: (json['totalAmount'] ?? json['amount'] ?? 0).toDouble(),
      shippingCharge: (json['shippingCharge'] ?? 0).toDouble(),
      status: OrderStatus.fromString(json['status']?.toString() ?? 'pending'),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      trackingInfo: json['trackingInfo']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'items': items.map((x) => x.toJson()).toList(),
      'shippingAddress': shippingAddress.toJson(),
      'paymentMethod': paymentMethod,
      'totalAmount': totalAmount,
      'shippingCharge': shippingCharge,
      'status': status.toJsonString(),
      'createdAt': createdAt.toIso8601String(),
      'trackingInfo': trackingInfo,
    };
  }

  @override
  List<Object?> get props => [
    id,
    items,
    shippingAddress,
    paymentMethod,
    totalAmount,
    shippingCharge,
    status,
    createdAt,
    trackingInfo,
  ];
}
