import 'package:equatable/equatable.dart';

class CartItemModel extends Equatable {
  final String id;
  final String productId;
  final int vendorId;
  final String name;
  final String image;
  final double price;
  final int quantity;
  final int stock;

  const CartItemModel({
    required this.id,
    required this.productId,
    required this.vendorId,
    required this.name,
    required this.image,
    required this.price,
    required this.quantity,
    required this.stock,
  });

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    final productData = json['Product'] as Map<String, dynamic>;

    return CartItemModel(
      id: json['id'].toString(),
      productId: (json['productId'] ?? json['product'] ?? '').toString(),
      vendorId: json['vendorId'] ?? 0,
      name: productData['name'] as String,
      image: productData['imageUrl'] as String,
      price: (json['price'] as num).toDouble(),
      quantity: json['quantity'] as int,
      stock: productData['availableStock'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'vendorId': vendorId,
      'name': name,
      'image': image,
      'price': price,
      'quantity': quantity,
      'stock': stock,
    };
  }

  // Helper to create a copy of the item with a new quantity (useful for optimistic UI updates)
  CartItemModel copyWith({
    String? id,
    String? productId,
    int? vendorId,
    String? name,
    String? image,
    double? price,
    int? quantity,
    int? stock,
  }) {
    return CartItemModel(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      vendorId: vendorId ?? this.vendorId,
      name: name ?? this.name,
      image: image ?? this.image,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      stock: stock ?? this.stock,
    );
  }

  @override
  List<Object?> get props => [
    id,
    productId,
    vendorId,
    name,
    image,
    price,
    quantity,
    stock,
  ];
}

class CartModel extends Equatable {
  final List<CartItemModel> items;

  const CartModel({required this.items});

  // Computed Getters
  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);

  double get subtotal =>
      items.fold(0.0, (sum, item) => sum + (item.price * item.quantity));

  bool get isEmpty => items.isEmpty;

  factory CartModel.fromJson(Map<String, dynamic> json) {
    return CartModel(
      items: json['items'] != null
          ? List<CartItemModel>.from(
              (json['items'] as List).map((x) => CartItemModel.fromJson(x)),
            )
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {'items': items.map((x) => x.toJson()).toList()};
  }

  // Helper to copy the cart with updated items
  CartModel copyWith({List<CartItemModel>? items}) {
    return CartModel(items: items ?? this.items);
  }

  @override
  List<Object?> get props => [items];
}
