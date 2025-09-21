// lib/models/product.dart
import 'package:uuid/uuid.dart';

class Product {
  final String productId;
  final String? categoryId; // Can be null if no category is assigned
  final String productName;
  final String? description;
  final double unitPrice;
  final int stockQuantity;
  final String? status; // e.g., 'Available', 'Out of Stock', 'Discontinued'

  Product({
    String? productId,
    this.categoryId,
    required this.productName,
    this.description,
    required this.unitPrice,
    required this.stockQuantity,
    this.status = 'Available',
  }) : productId = productId ?? const Uuid().v4();

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'category_id': categoryId,
      'product_name': productName,
      'description': description,
      'unit_price': unitPrice,
      'stock_quantity': stockQuantity,
      'status': status,
    };
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      productId: json['product_id'],
      categoryId: json['category_id'],
      productName: json['product_name'],
      description: json['description'],
      unitPrice: json['unit_price'],
      stockQuantity: json['stock_quantity'],
      status: json['status'],
    );
  }

  Product copyWith({
    String? productId,
    String? categoryId,
    String? productName,
    String? description,
    double? unitPrice,
    int? stockQuantity,
    String? status,
  }) {
    return Product(
      productId: productId ?? this.productId,
      categoryId: categoryId ?? this.categoryId,
      productName: productName ?? this.productName,
      description: description ?? this.description,
      unitPrice: unitPrice ?? this.unitPrice,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      status: status ?? this.status,
    );
  }
}