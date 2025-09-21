// lib/models/sale.dart
import 'package:uuid/uuid.dart';

class Sale {
  final String saleId;
  final String customerId;
  final DateTime saleDate;
  final double totalAmount;
  final String? paymentMethod; // e.g., 'Cash', 'Card', 'Online'

  Sale({
    String? saleId,
    required this.customerId,
    DateTime? saleDate,
    required this.totalAmount,
    this.paymentMethod,
  })  : saleId = saleId ?? const Uuid().v4(),
        saleDate = saleDate ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'sale_id': saleId,
      'customer_id': customerId,
      'sale_date': saleDate.millisecondsSinceEpoch ~/ 1000,
      'total_amount': totalAmount,
      'payment_method': paymentMethod,
    };
  }

  factory Sale.fromJson(Map<String, dynamic> json) {
    return Sale(
      saleId: json['sale_id'],
      customerId: json['customer_id'],
      saleDate: DateTime.fromMillisecondsSinceEpoch(json['sale_date'] * 1000),
      totalAmount: json['total_amount'],
      paymentMethod: json['payment_method'],
    );
  }

  Sale copyWith({
    String? saleId,
    String? customerId,
    DateTime? saleDate,
    double? totalAmount,
    String? paymentMethod,
  }) {
    return Sale(
      saleId: saleId ?? this.saleId,
      customerId: customerId ?? this.customerId,
      saleDate: saleDate ?? this.saleDate,
      totalAmount: totalAmount ?? this.totalAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
    );
  }
}