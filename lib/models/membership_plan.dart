// lib/models/membership_plan.dart - UPDATED CONTENT
import 'package:uuid/uuid.dart';

enum DurationUnit {
  days,
  weeks,
  months,
  years,
}

extension DurationUnitExtension on DurationUnit {
  String toDisplayString() {
    return name[0].toUpperCase() + name.substring(1);
  }
}

class MembershipPlan {
  final String planId;
  final String planName;
  final double monthlyFee;
  final int durationValue; // e.g., 3, 6, 1
  final DurationUnit durationUnit; // e.g., Months, Years, Weeks

  MembershipPlan({
    String? planId,
    required this.planName,
    required this.monthlyFee,
    required this.durationValue,
    required this.durationUnit,
  }) : planId = planId ?? const Uuid().v4();

  // Helper to calculate the end date based on a start date and plan's duration
  DateTime calculateEndDate(DateTime startDate) {
    DateTime endDate = startDate;
    switch (durationUnit) {
      case DurationUnit.days:
        endDate = startDate.add(Duration(days: durationValue));
        break;
      case DurationUnit.weeks:
        endDate = startDate.add(Duration(days: durationValue * 7));
        break;
      case DurationUnit.months:
        endDate = DateTime(startDate.year, startDate.month + durationValue, startDate.day);
        break;
      case DurationUnit.years:
        endDate = DateTime(startDate.year + durationValue, startDate.month, startDate.day);
        break;
    }
    // Ensure the end date is inclusive of the last day, typically end of day
    return DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
  }

  Map<String, dynamic> toJson() {
    return {
      'plan_id': planId,
      'plan_name': planName,
      'monthly_fee': monthlyFee,
      'duration_value': durationValue,
      'duration_unit': durationUnit.name, // Store enum name as string
    };
  }

  factory MembershipPlan.fromJson(Map<String, dynamic> json) {
    return MembershipPlan(
      planId: json['plan_id'],
      planName: json['plan_name'],
      monthlyFee: json['monthly_fee'],
      durationValue: json['duration_value'],
      durationUnit: DurationUnit.values.firstWhere((e) => e.name == json['duration_unit']),
    );
  }

  MembershipPlan copyWith({
    String? planId,
    String? planName,
    double? monthlyFee,
    int? durationValue,
    DurationUnit? durationUnit,
  }) {
    return MembershipPlan(
      planId: planId ?? this.planId,
      planName: planName ?? this.planName,
      monthlyFee: monthlyFee ?? this.monthlyFee,
      durationValue: durationValue ?? this.durationValue,
      durationUnit: durationUnit ?? this.durationUnit,
    );
  }
}