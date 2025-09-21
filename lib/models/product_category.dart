// lib/models/product_category.dart
import 'package:uuid/uuid.dart';

class ProductCategory {
  final String categoryId;
  final String categoryName;
  final String? description;
  final String? status; // e.g., 'Active', 'Inactive'

  ProductCategory({
    String? categoryId,
    required this.categoryName,
    this.description,
    this.status = 'Active',
  }) : categoryId = categoryId ?? const Uuid().v4();

  Map<String, dynamic> toJson() {
    return {
      'category_id': categoryId,
      'category_name': categoryName,
      'description': description,
      'status': status,
    };
  }

  factory ProductCategory.fromJson(Map<String, dynamic> json) {
    return ProductCategory(
      categoryId: json['category_id'],
      categoryName: json['category_name'],
      description: json['description'],
      status: json['status'],
    );
  }

  ProductCategory copyWith({
    String? categoryId,
    String? categoryName,
    String? description,
    String? status,
  }) {
    return ProductCategory(
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      description: description ?? this.description,
      status: status ?? this.status,
    );
  }
}