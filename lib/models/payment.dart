// lib/models/payment.dart
import 'package:uuid/uuid.dart';

class Payment {
  final String paymentId;
  final String membershipId;
  final double amount;
  final String method; // e.g., 'Cash', 'Card', 'Bank Transfer'
  final DateTime paymentDate;
  final String status; // e.g., 'Completed', 'Failed', 'Refunded'

  Payment({
    String? paymentId,
    required this.membershipId,
    required this.amount,
    required this.method,
    DateTime? paymentDate,
    this.status = 'Completed',
  })  : paymentId = paymentId ?? const Uuid().v4(),
        paymentDate = paymentDate ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'payment_id': paymentId,
      'membership_id': membershipId,
      'amount': amount,
      'method': method,
      'payment_date': paymentDate.millisecondsSinceEpoch ~/ 1000,
      'status': status,
    };
  }

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      paymentId: json['payment_id'],
      membershipId: json['membership_id'],
      amount: json['amount'],
      method: json['method'],
      paymentDate: DateTime.fromMillisecondsSinceEpoch(json['payment_date'] * 1000),
      status: json['status'],
    );
  }

  Payment copyWith({
    String? paymentId,
    String? membershipId,
    double? amount,
    String? method,
    DateTime? paymentDate,
    String? status,
  }) {
    return Payment(
      paymentId: paymentId ?? this.paymentId,
      membershipId: membershipId ?? this.membershipId,
      amount: amount ?? this.amount,
      method: method ?? this.method,
      paymentDate: paymentDate ?? this.paymentDate,
      status: status ?? this.status,
    );
  }
}