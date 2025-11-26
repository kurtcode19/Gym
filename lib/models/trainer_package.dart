import 'package:uuid/uuid.dart';

class TrainerPackage {
  final String packageId;
  final String customerId;
  final String trainerId;
  final String packageName; // e.g., "10 Sessions", "Monthly Unlimited"
  final double price;       // Amount paid by customer (e.g., 5000)
  final int totalSessions;  // Number of sessions allowed (-1 for unlimited)
  final int sessionsUsed;   // How many used so far
  final DateTime startDate;
  final DateTime endDate;
  final String status;      // Active, Completed, Expired

  TrainerPackage({
    String? packageId,
    required this.customerId,
    required this.trainerId,
    required this.packageName,
    required this.price,
    required this.totalSessions,
    this.sessionsUsed = 0,
    required this.startDate,
    required this.endDate,
    required this.status,
  }) : packageId = packageId ?? const Uuid().v4();

  // Helper to calculate remaining sessions
  int get sessionsRemaining => totalSessions == -1 ? 999 : (totalSessions - sessionsUsed);

  // Helper to auto-calculate status
  String get calculatedStatus {
    if (status == 'Cancelled') return 'Cancelled';
    if (endDate.isBefore(DateTime.now())) return 'Expired';
    if (totalSessions != -1 && sessionsUsed >= totalSessions) return 'Completed';
    return 'Active';
  }

  Map<String, dynamic> toJson() {
    return {
      'package_id': packageId,
      'customer_id': customerId,
      'trainer_id': trainerId,
      'package_name': packageName,
      'price': price,
      'total_sessions': totalSessions,
      'sessions_used': sessionsUsed,
      'start_date': startDate.millisecondsSinceEpoch ~/ 1000,
      'end_date': endDate.millisecondsSinceEpoch ~/ 1000,
      'status': status,
    };
  }

  factory TrainerPackage.fromJson(Map<String, dynamic> json) {
    return TrainerPackage(
      packageId: json['package_id'],
      customerId: json['customer_id'],
      trainerId: json['trainer_id'],
      packageName: json['package_name'],
      price: (json['price'] as num).toDouble(),
      totalSessions: json['total_sessions'],
      sessionsUsed: json['sessions_used'],
      startDate: DateTime.fromMillisecondsSinceEpoch(json['start_date'] * 1000),
      endDate: DateTime.fromMillisecondsSinceEpoch(json['end_date'] * 1000),
      status: json['status'],
    );
  }
}