import 'package:equatable/equatable.dart';

enum OrderStatus {
  pending,
  confirmed,
  shipped,
  delivered,
  cancelled;

  // Helper to parse from JSON string
  static OrderStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed': return OrderStatus.confirmed;
      case 'shipped': return OrderStatus.shipped;
      case 'delivered': return OrderStatus.delivered;
      case 'cancelled': return OrderStatus.cancelled;
      case 'pending':
      default:
        return OrderStatus.pending;
    }
  }

  // Helper to convert to JSON string
  String toJsonString() => name;
}

class ShippingAddressModel extends Equatable {
  final String fullName;
  final String phone;
  final String addressLine1;
  final String? addressLine2;
  final String city;
  final String state;
  final String pincode;

  const ShippingAddressModel({
    required this.fullName,
    required this.phone,
    required this.addressLine1,
    this.addressLine2,
    required this.city,
    required this.state,
    required this.pincode,
  });

  factory ShippingAddressModel.fromJson(Map<String, dynamic> json) {
    return ShippingAddressModel(
      fullName: json['fullName'] ?? '',
      phone: json['phone'] ?? '',
      addressLine1: json['addressLine1'] ?? '',
      addressLine2: json['addressLine2'],
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      pincode: json['pincode'] ?? '',
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
      'pincode': pincode,
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
    pincode,
  ];
}

class OrderItemModel extends Equatable {
  final String productId;
  final String name;
  final String image;
  final double price;
  final int quantity;

  const OrderItemModel({
    required this.productId,
    required this.name,
    required this.image,
    required this.price,
    required this.quantity,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      productId: json['productId'] ?? json['product'] ?? '',
      name: json['name'] ?? '',
      image: json['image'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      quantity: json['quantity'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'name': name,
      'image': image,
      'price': price,
      'quantity': quantity,
    };
  }

  @override
  List<Object?> get props => [productId, name, image, price, quantity];
}

class OrderModel extends Equatable {
  final String id;
  final List<OrderItemModel> items;
  final ShippingAddressModel shippingAddress;
  final String paymentMethod;
  final double totalAmount;
  final OrderStatus status;
  final DateTime createdAt;
  final String? trackingInfo;

  const OrderModel({
    required this.id,
    required this.items,
    required this.shippingAddress,
    required this.paymentMethod,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
    this.trackingInfo,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['_id'] ?? json['id'] ?? '',
      items: json['items'] != null
          ? List<OrderItemModel>.from(
        (json['items'] as List).map((x) => OrderItemModel.fromJson(x)),
      )
          : [],
      shippingAddress: ShippingAddressModel.fromJson(json['shippingAddress'] ?? {}),
      paymentMethod: json['paymentMethod'] ?? 'COD',
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      status: OrderStatus.fromString(json['status'] ?? 'pending'),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      trackingInfo: json['trackingInfo'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'items': items.map((x) => x.toJson()).toList(),
      'shippingAddress': shippingAddress.toJson(),
      'paymentMethod': paymentMethod,
      'totalAmount': totalAmount,
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
    status,
    createdAt,
    trackingInfo,
  ];
}