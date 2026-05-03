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
    // Safely extract the nested Product object, fallback to empty map if null
    final productData = json['Product'] as Map<String, dynamic>? ?? {};

    return CartItemModel(
      id: json['id']?.toString() ?? '',
      productId: (json['productId'] ?? json['product'] ?? '').toString(),

      // CRITICAL FIX: Pull vendorId from the nested productData, not the root json!
      vendorId:
          int.tryParse(
            (productData['vendorId'] ?? json['vendorId'])?.toString() ?? '0',
          ) ??
          0,

      name: productData['name']?.toString() ?? 'Unknown Product',
      image: productData['imageUrl']?.toString() ?? '',

      // Safely parse price whether it arrives as an int, double, or String
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,

      // Safely parse quantity and stock
      quantity: int.tryParse(json['quantity']?.toString() ?? '1') ?? 1,
      stock:
          int.tryParse(productData['availableStock']?.toString() ?? '0') ?? 0,
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

  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);

  double get subtotal =>
      items.fold(0.0, (sum, item) => sum + (item.price * item.quantity));

  bool get isEmpty => items.isEmpty;

  factory CartModel.fromJson(Map<String, dynamic> json) {
    return CartModel(
      // Safely map the items list to avoid crashes if it's null or missing
      items:
          (json['items'] as List<dynamic>?)
              ?.map((x) => CartItemModel.fromJson(x as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {'items': items.map((x) => x.toJson()).toList()};
  }

  CartModel copyWith({List<CartItemModel>? items}) {
    return CartModel(items: items ?? this.items);
  }

  @override
  List<Object?> get props => [items];
}
