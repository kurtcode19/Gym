// lib/models/membership.dart
import 'package:uuid/uuid.dart';

class Membership {
  final String membershipId;
  final String customerId;
  final String planId;
  final DateTime startDate;
  final DateTime endDate;
  final String status; // e.g., 'Active', 'Pending', 'Expired', 'Cancelled'

  Membership({
    String? membershipId,
    required this.customerId,
    required this.planId,
    required this.startDate,
    required this.endDate,
    required this.status,
  }) : membershipId = membershipId ?? const Uuid().v4();

  Map<String, dynamic> toJson() {
    return {
      'membership_id': membershipId,
      'customer_id': customerId,
      'plan_id': planId,
      'start_date': startDate.millisecondsSinceEpoch ~/ 1000,
      'end_date': endDate.millisecondsSinceEpoch ~/ 1000,
      'status': status,
    };
  }

  factory Membership.fromJson(Map<String, dynamic> json) {
    return Membership(
      membershipId: json['membership_id'],
      customerId: json['customer_id'],
      planId: json['plan_id'],
      startDate: DateTime.fromMillisecondsSinceEpoch(json['start_date'] * 1000),
      endDate: DateTime.fromMillisecondsSinceEpoch(json['end_date'] * 1000),
      status: json['status'],
    );
  }

  Membership copyWith({
    String? membershipId,
    String? customerId,
    String? planId,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
  }) {
    return Membership(
      membershipId: membershipId ?? this.membershipId,
      customerId: customerId ?? this.customerId,
      planId: planId ?? this.planId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
    );
  }
}