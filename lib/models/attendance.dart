// lib/models/attendance.dart
import 'package:uuid/uuid.dart';

class Attendance {
  final String attendanceId;
  final String memberId; // FK to CUSTOMER customer_id
  final DateTime checkinTime;
  final DateTime? checkoutTime;
  final DateTime date; // Date of attendance (for summary/filtering)
  final String? facilityUsed; // e.g., 'Gym Floor', 'Pool', 'Basketball Court'

  Attendance({
    String? attendanceId,
    required this.memberId,
    required this.checkinTime,
    this.checkoutTime,
    DateTime? date,
    this.facilityUsed,
  })  : attendanceId = attendanceId ?? const Uuid().v4(),
        date = date ?? DateTime(checkinTime.year, checkinTime.month, checkinTime.day); // Default to checkin date

  Map<String, dynamic> toJson() {
    return {
      'attendance_id': attendanceId,
      'member_id': memberId,
      'checkin_time': checkinTime.millisecondsSinceEpoch ~/ 1000,
      'checkout_time': checkoutTime!.millisecondsSinceEpoch ~/ 1000,
      'date': date.millisecondsSinceEpoch ~/ 1000,
      'facility_used': facilityUsed,
    };
  }

  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      attendanceId: json['attendance_id'],
      memberId: json['member_id'],
      checkinTime: DateTime.fromMillisecondsSinceEpoch(json['checkin_time'] * 1000),
      checkoutTime: json['checkout_time'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['checkout_time'] * 1000)
          : null,
      date: DateTime.fromMillisecondsSinceEpoch(json['date'] * 1000),
      facilityUsed: json['facility_used'],
    );
  }

  Attendance copyWith({
    String? attendanceId,
    String? memberId,
    DateTime? checkinTime,
    DateTime? checkoutTime,
    DateTime? date,
    String? facilityUsed,
  }) {
    return Attendance(
      attendanceId: attendanceId ?? this.attendanceId,
      memberId: memberId ?? this.memberId,
      checkinTime: checkinTime ?? this.checkinTime,
      checkoutTime: checkoutTime ?? this.checkoutTime,
      date: date ?? this.date,
      facilityUsed: facilityUsed ?? this.facilityUsed,
    );
  }
}