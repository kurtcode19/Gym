// lib/models/class.dart
import 'package:uuid/uuid.dart';

class GymClass { // Renamed to GymClass to avoid conflict with 'class' keyword
  final String classId;
  final String? trainerId; // FK to TRAINER trainer_id
  final String className;
  final DateTime scheduleTime; // Specific DateTime including time
  final int durationMinutes; // Duration in minutes

  GymClass({
    String? classId,
    this.trainerId,
    required this.className,
    required this.scheduleTime,
    required this.durationMinutes,
  }) : classId = classId ?? const Uuid().v4();

  Map<String, dynamic> toJson() {
    return {
      'class_id': classId,
      'trainer_id': trainerId,
      'class_name': className,
      'schedule_time': scheduleTime.millisecondsSinceEpoch ~/ 1000,
      'duration_minutes': durationMinutes,
    };
  }

  factory GymClass.fromJson(Map<String, dynamic> json) {
    return GymClass(
      classId: json['class_id'],
      trainerId: json['trainer_id'],
      className: json['class_name'],
      scheduleTime: DateTime.fromMillisecondsSinceEpoch(json['schedule_time'] * 1000),
      durationMinutes: json['duration_minutes'],
    );
  }

  GymClass copyWith({
    String? classId,
    String? trainerId,
    String? className,
    DateTime? scheduleTime,
    int? durationMinutes,
  }) {
    return GymClass(
      classId: classId ?? this.classId,
      trainerId: trainerId ?? this.trainerId,
      className: className ?? this.className,
      scheduleTime: scheduleTime ?? this.scheduleTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
    );
  }
}