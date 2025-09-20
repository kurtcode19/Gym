// lib/providers/class_booking_provider.dart
import 'package:flutter/material.dart';
import 'package:gym/models/class_booking.dart';
import 'package:gym/providers/database_helper.dart';
import 'package:gym/models/class.dart'; // Import GymClass to get schedule details

// Model to hold joined class booking data for display
class DetailedClassBooking {
  final ClassBooking booking;
  final String customerFirstName;
  final String customerLastName;
  final String className;
  final DateTime classScheduleTime;
  final int classDurationMinutes;
  final String? trainerFirstName;
  final String? trainerLastName;

  DetailedClassBooking({
    required this.booking,
    required this.customerFirstName,
    required this.customerLastName,
    required this.className,
    required this.classScheduleTime,
    required this.classDurationMinutes,
    this.trainerFirstName,
    this.trainerLastName,
  });

  factory DetailedClassBooking.fromMap(Map<String, dynamic> map) {
    return DetailedClassBooking(
      booking: ClassBooking.fromJson(map),
      customerFirstName: map['customer_first_name'],
      customerLastName: map['customer_last_name'],
      className: map['class_name'],
      classScheduleTime: DateTime.fromMillisecondsSinceEpoch(map['class_schedule_time'] * 1000),
      classDurationMinutes: map['class_duration_minutes'],
      trainerFirstName: map['trainer_first_name'],
      trainerLastName: map['trainer_last_name'],
    );
  }

  String get customerFullName => '$customerFirstName $customerLastName';
  String get trainerFullName {
    if (trainerFirstName != null && trainerLastName != null) {
      return '$trainerFirstName $trainerLastName';
    }
    return 'N/A';
  }
}

class ClassBookingProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper;
  List<DetailedClassBooking> _bookings = [];
  List<DetailedClassBooking> _filteredBookings = [];
  bool _isLoading = false;

  ClassBookingProvider(this._dbHelper) {
    fetchClassBookings();
  }

  List<DetailedClassBooking> get bookings => _filteredBookings;
  bool get isLoading => _isLoading;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> fetchClassBookings() async {
    _setLoading(true);
    try {
      final bookingMaps = await _dbHelper.getClassBookings();
      _bookings = bookingMaps.map((map) => DetailedClassBooking.fromMap(map)).toList();
      _filteredBookings = List.from(_bookings);
    } catch (e) {
      print('Error fetching class bookings: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addClassBooking(ClassBooking booking) async {
    try {
      await _dbHelper.insertClassBooking(booking.toJson());
      await fetchClassBookings(); // Re-fetch to update detailed view
    } catch (e) {
      print('Error adding class booking: $e');
    }
  }

  Future<void> updateClassBooking(ClassBooking booking) async {
    try {
      await _dbHelper.updateClassBooking(booking.toJson());
      await fetchClassBookings(); // Re-fetch to update detailed view
    } catch (e) {
      print('Error updating class booking: $e');
    }
  }

  Future<void> deleteClassBooking(String bookingId) async {
    try {
      await _dbHelper.deleteClassBooking(bookingId);
      _bookings.removeWhere((b) => b.booking.bookingId == bookingId);
      _filteredBookings.removeWhere((b) => b.booking.bookingId == bookingId);
      notifyListeners();
    } catch (e) {
      print('Error deleting class booking: $e');
    }
  }

  void searchClassBookings(String query) {
    if (query.isEmpty) {
      _filteredBookings = List.from(_bookings);
    } else {
      _filteredBookings = _bookings.where((booking) {
        final lowerCaseQuery = query.toLowerCase();
        return booking.customerFirstName.toLowerCase().contains(lowerCaseQuery) ||
               booking.customerLastName.toLowerCase().contains(lowerCaseQuery) ||
               booking.className.toLowerCase().contains(lowerCaseQuery) ||
               booking.booking.status.toLowerCase().contains(lowerCaseQuery);
      }).toList();
    }
    notifyListeners();
  }
}