// lib/models/class_booking.dart
import 'package:uuid/uuid.dart';

class ClassBooking {
  final String bookingId;
  final String customerId; // FK to CUSTOMER customer_id
  final String classId; // FK to CLASS class_id
  final DateTime bookingDate; // Date when the booking was made
  final String status; // e.g., 'Confirmed', 'Cancelled', 'Attended'

  ClassBooking({
    String? bookingId,
    required this.customerId,
    required this.classId,
    DateTime? bookingDate,
    required this.status,
  })  : bookingId = bookingId ?? const Uuid().v4(),
        bookingDate = bookingDate ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'booking_id': bookingId,
      'customer_id': customerId,
      'class_id': classId,
      'booking_date': bookingDate.millisecondsSinceEpoch ~/ 1000,
      'status': status,
    };
  }

  factory ClassBooking.fromJson(Map<String, dynamic> json) {
    return ClassBooking(
      bookingId: json['booking_id'],
      customerId: json['customer_id'],
      classId: json['class_id'],
      bookingDate: DateTime.fromMillisecondsSinceEpoch(json['booking_date'] * 1000),
      status: json['status'],
    );
  }

  ClassBooking copyWith({
    String? bookingId,
    String? customerId,
    String? classId,
    DateTime? bookingDate,
    String? status,
  }) {
    return ClassBooking(
      bookingId: bookingId ?? this.bookingId,
      customerId: customerId ?? this.customerId,
      classId: classId ?? this.classId,
      bookingDate: bookingDate ?? this.bookingDate,
      status: status ?? this.status,
    );
  }
}