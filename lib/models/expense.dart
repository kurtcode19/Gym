// lib/models/expense.dart
import 'package:uuid/uuid.dart';

class Expense {
  final String expenseId;
  final String category; // e.g., 'Rent', 'Utilities', 'Salaries', 'Maintenance'
  final String? description;
  final double amount;
  final DateTime expenseDate;

  Expense({
    String? expenseId,
    required this.category,
    this.description,
    required this.amount,
    DateTime? expenseDate,
  })  : expenseId = expenseId ?? const Uuid().v4(),
        expenseDate = expenseDate ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'expense_id': expenseId,
      'category': category,
      'description': description,
      'amount': amount,
      'expense_date': expenseDate.millisecondsSinceEpoch ~/ 1000,
    };
  }

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      expenseId: json['expense_id'],
      category: json['category'],
      description: json['description'],
      amount: json['amount'],
      expenseDate: DateTime.fromMillisecondsSinceEpoch(json['expense_date'] * 1000),
    );
  }

  Expense copyWith({
    String? expenseId,
    String? category,
    String? description,
    double? amount,
    DateTime? expenseDate,
  }) {
    return Expense(
      expenseId: expenseId ?? this.expenseId,
      category: category ?? this.category,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      expenseDate: expenseDate ?? this.expenseDate,
    );
  }
}