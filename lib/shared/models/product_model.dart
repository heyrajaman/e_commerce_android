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
      // Handle both MongoDB '_id' and standard 'id'
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      discountPrice: json['discountPrice'] != null
          ? (json['discountPrice'] as num).toDouble()
          : null,
      images: json['images'] != null ? List<String>.from(json['images']) : [],
      category: json['Category'] != null
          ? json['Category']['name'] ?? ''
          : (json['category'] ?? ''),
      stock: json['availableStock'] ?? json['stock'] ?? 0,
      vendorId:
          json['vendorId']?.toString() ?? json['vendor']?.toString() ?? '',
      rating: (json['rating'] ?? 0).toDouble(),
      reviewCount: json['reviewCount'] ?? json['numOfReviews'] ?? 0,
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
