// lib/models/sale_item.dart
import 'package:uuid/uuid.dart';

class SaleItem {
  final String saleItemId;
  final String saleId;
  final String productId;
  final int quantity;
  final double unitPrice; // Price at the time of sale (can differ from current product price)

  SaleItem({
    String? saleItemId,
    required this.saleId,
    required this.productId,
    required this.quantity,
    required this.unitPrice,
  }) : saleItemId = saleItemId ?? const Uuid().v4();

  Map<String, dynamic> toJson() {
    return {
      'sale_item_id': saleItemId,
      'sale_id': saleId,
      'product_id': productId,
      'quantity': quantity,
      'unit_price': unitPrice,
    };
  }

  factory SaleItem.fromJson(Map<String, dynamic> json) {
    return SaleItem(
      saleItemId: json['sale_item_id'],
      saleId: json['sale_id'],
      productId: json['product_id'],
      quantity: json['quantity'],
      unitPrice: json['unit_price'],
    );
  }

  SaleItem copyWith({
    String? saleItemId,
    String? saleId,
    String? productId,
    int? quantity,
    double? unitPrice,
  }) {
    return SaleItem(
      saleItemId: saleItemId ?? this.saleItemId,
      saleId: saleId ?? this.saleId,
      productId: productId ?? this.productId,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
    );
  }
}