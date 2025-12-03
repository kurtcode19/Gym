class PTSession {
  final String sessionId;
  final String trainerId;
  final String customerId;
  final String? packageId;
  final DateTime startTime;
  final int durationMinutes;
  final double cost;
  final String status;
  final bool isPaid;          // <-- BOOL!
  final bool trainerPaid;     // <-- BOOL!
  final String? notes;

  PTSession({
    required this.sessionId,
    required this.trainerId,
    required this.customerId,
    this.packageId,
    required this.startTime,
    required this.durationMinutes,
    required this.cost,
    required this.status,
    required this.isPaid,
    required this.trainerPaid,
    this.notes,
  });

  factory PTSession.fromJson(Map<String, dynamic> json) {
    return PTSession(
      sessionId: json['session_id'],
      trainerId: json['trainer_id'],
      customerId: json['customer_id'],
      packageId: json['package_id'],
      startTime: DateTime.fromMillisecondsSinceEpoch(json['start_time']),
      durationMinutes: json['duration_minutes'],
      cost: json['cost']?.toDouble() ?? 0,
      status: json['status'],
      isPaid: json['is_paid'] == 1,             // <-- FIX
      trainerPaid: json['trainer_paid'] == 1,   // <-- FIX
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'session_id': sessionId,
      'trainer_id': trainerId,
      'customer_id': customerId,
      'package_id': packageId,
      'start_time': startTime.millisecondsSinceEpoch,
      'duration_minutes': durationMinutes,
      'cost': cost,
      'status': status,
      'is_paid': isPaid ? 1 : 0,               // <-- FIX
      'trainer_paid': trainerPaid ? 1 : 0,     // <-- FIX
      'notes': notes,
    };
  }
}
