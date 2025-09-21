// lib/providers/payment_provider.dart
import 'package:flutter/material.dart';
import 'package:gym/models/payment.dart';
import 'package:gym/providers/database_helper.dart';
import 'package:gym/models/membership.dart'; // For membership details
import 'package:gym/models/customer.dart'; // For customer details

// Model to hold joined payment data for display
class DetailedPayment {
  final Payment payment;
  final String customerFirstName;
  final String customerLastName;
  final DateTime membershipStartDate;
  final DateTime membershipEndDate;
  final String membershipStatus;

  DetailedPayment({
    required this.payment,
    required this.customerFirstName,
    required this.customerLastName,
    required this.membershipStartDate,
    required this.membershipEndDate,
    required this.membershipStatus,
  });

  factory DetailedPayment.fromMap(Map<String, dynamic> map) {
    return DetailedPayment(
      payment: Payment.fromJson(map),
      customerFirstName: map['customer_first_name'],
      customerLastName: map['customer_last_name'],
      membershipStartDate: DateTime.fromMillisecondsSinceEpoch(map['membership_start_date'] * 1000),
      membershipEndDate: DateTime.fromMillisecondsSinceEpoch(map['membership_end_date'] * 1000),
      membershipStatus: map['membership_status'],
    );
  }
}

class PaymentProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper;
  List<DetailedPayment> _payments = [];
  List<DetailedPayment> _filteredPayments = [];
  bool _isLoading = false;

  PaymentProvider(this._dbHelper) {
    fetchPayments();
  }

  List<DetailedPayment> get payments => _filteredPayments;
  bool get isLoading => _isLoading;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> fetchPayments() async {
    _setLoading(true);
    try {
      final paymentMaps = await _dbHelper.getDetailedPayments();
      _payments = paymentMaps.map((map) => DetailedPayment.fromMap(map)).toList();
      _filteredPayments = List.from(_payments);
    } catch (e) {
      print('Error fetching detailed payments: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addPayment(Payment payment) async {
    try {
      await _dbHelper.insertPayment(payment.toJson());
      await fetchPayments(); // Re-fetch to get the detailed view
    } catch (e) {
      print('Error adding payment: $e');
    }
  }

  Future<void> updatePayment(Payment payment) async {
    try {
      await _dbHelper.updatePayment(payment.toJson());
      await fetchPayments(); // Re-fetch to get the detailed view
    } catch (e) {
      print('Error updating payment: $e');
    }
  }

  Future<void> deletePayment(String paymentId) async {
    try {
      await _dbHelper.deletePayment(paymentId);
      _payments.removeWhere((p) => p.payment.paymentId == paymentId);
      _filteredPayments.removeWhere((p) => p.payment.paymentId == paymentId);
      notifyListeners();
    } catch (e) {
      print('Error deleting payment: $e');
    }
  }

  void searchPayments(String query) {
    if (query.isEmpty) {
      _filteredPayments = List.from(_payments);
    } else {
      _filteredPayments = _payments.where((detailedPayment) {
        final lowerCaseQuery = query.toLowerCase();
        return detailedPayment.customerFirstName.toLowerCase().contains(lowerCaseQuery) ||
               detailedPayment.customerLastName.toLowerCase().contains(lowerCaseQuery) ||
               detailedPayment.payment.method.toLowerCase().contains(lowerCaseQuery) ||
               detailedPayment.payment.status.toLowerCase().contains(lowerCaseQuery);
      }).toList();
    }
    notifyListeners();
  }
}