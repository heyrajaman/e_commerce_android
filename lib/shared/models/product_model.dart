import 'package:equatable/equatable.dart';

class ProductModel extends Equatable {
  final String id;
  final String name;
  final String description;
  final double price;
  final double? discountPrice;
  final List<String> images;
  final String category;
  final int stock;
  final String vendorId;
  final double rating;
  final int reviewCount;

  const ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.discountPrice,
    required this.images,
    required this.category,
    required this.stock,
    required this.vendorId,
    required this.rating,
    required this.reviewCount,
  });

  /// Helper getter to determine if the product is actively on sale
  bool get isOnSale => discountPrice != null && discountPrice! < price;

  /// Returns the discountPrice if on sale, otherwise the regular price
  double get effectivePrice => isOnSale ? discountPrice! : price;

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown Product',
      description: json['description']?.toString() ?? '',

      // Safely parse numbers
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      discountPrice: json['discountPrice'] != null
          ? double.tryParse(json['discountPrice'].toString())
          : null,

      images: json['images'] != null ? List<String>.from(json['images']) : [],

      category: json['Category'] != null
          ? json['Category']['name']?.toString() ?? ''
          : (json['category']?.toString() ?? ''),

      stock:
          int.tryParse(
            json['availableStock']?.toString() ??
                json['stock']?.toString() ??
                '0',
          ) ??
          0,

      vendorId:
          json['vendorId']?.toString() ?? json['vendor']?.toString() ?? '',

      rating: double.tryParse(json['rating']?.toString() ?? '0') ?? 0.0,
      reviewCount:
          int.tryParse(
            json['reviewCount']?.toString() ??
                json['numOfReviews']?.toString() ??
                '0',
          ) ??
          0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'discountPrice': discountPrice,
      'images': images,
      'category': category,
      'stock': stock,
      'vendorId': vendorId,
      'rating': rating,
      'reviewCount': reviewCount,
    };
  }

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    price,
    discountPrice,
    images,
    category,
    stock,
    vendorId,
    rating,
    reviewCount,
  ];
}
