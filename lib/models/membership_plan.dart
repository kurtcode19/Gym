// lib/models/membership_plan.dart
import 'package:uuid/uuid.dart';

class MembershipPlan {
  final String planId;
  final String planName;
  final double monthlyFee;
  final int duration; // Duration in months

  MembershipPlan({
    String? planId,
    required this.planName,
    required this.monthlyFee,
    required this.duration,
  }) : planId = planId ?? const Uuid().v4();

  Map<String, dynamic> toJson() {
    return {
      'plan_id': planId,
      'plan_name': planName,
      'monthly_fee': monthlyFee,
      'duration': duration,
    };
  }

  factory MembershipPlan.fromJson(Map<String, dynamic> json) {
    return MembershipPlan(
      planId: json['plan_id'],
      planName: json['plan_name'],
      monthlyFee: json['monthly_fee'],
      duration: json['duration'],
    );
  }

  MembershipPlan copyWith({
    String? planId,
    String? planName,
    double? monthlyFee,
    int? duration,
  }) {
    return MembershipPlan(
      planId: planId ?? this.planId,
      planName: planName ?? this.planName,
      monthlyFee: monthlyFee ?? this.monthlyFee,
      duration: duration ?? this.duration,
    );
  }
}