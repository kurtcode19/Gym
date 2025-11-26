// lib/models/membership.dart
import 'package:uuid/uuid.dart';

class Membership {
  final String membershipId;
  final String customerId;
  final String planId;
  final DateTime startDate;
  final DateTime endDate;
  final String status; // e.g., 'Active', 'Pending', 'Expired', 'Cancelled'
  // NEW FIELDS FOR TRAINER
  final String? trainerId;
  final double trainerFee;

  Membership({
    String? membershipId,
    required this.customerId,
    required this.planId,
    required this.startDate,
    required this.endDate,
    required this.status,
    this.trainerId,
    this.trainerFee = 0.0, // Default 0 if no trainer
  }) : membershipId = membershipId ?? const Uuid().v4();

  // Check if membership is expired based on end date
  bool get isExpired {
    return endDate.isBefore(DateTime.now());
  }

  // Get the appropriate status considering expiration
  String get calculatedStatus {
    if (status.toLowerCase() == 'cancelled') {
      return status; // Don't override cancelled status
    }
    return isExpired ? 'Expired' : status;
  }

  // Create a copy with automatically calculated status
  Membership withCalculatedStatus() {
    return copyWith(status: calculatedStatus);
  }

  Map<String, dynamic> toJson() {
    return {
      'membership_id': membershipId,
      'customer_id': customerId,
      'plan_id': planId,
      'start_date': startDate.millisecondsSinceEpoch ~/ 1000,
      'end_date': endDate.millisecondsSinceEpoch ~/ 1000,
      'status': status,
      'trainer_id': trainerId, // NEW
      'trainer_fee': trainerFee, // NEW
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
      trainerId: json['trainer_id'], // NEW
      trainerFee: (json['trainer_fee'] as num?)?.toDouble() ?? 0.0, // NEW
    );
  }

  Membership copyWith({
    String? membershipId,
    String? customerId,
    String? planId,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    String? trainerId, // NEW
    double? trainerFee, // NEW
  }) {
    return Membership(
      membershipId: membershipId ?? this.membershipId,
      customerId: customerId ?? this.customerId,
      planId: planId ?? this.planId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      trainerId: trainerId ?? this.trainerId,
      trainerFee: trainerFee ?? this.trainerFee,
    );
  }
}