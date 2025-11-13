// lib/providers/class_booking_provider.dart - UPDATED CONTENT

import 'package:flutter/material.dart';
import 'package:gym/models/class_booking.dart';
import 'package:gym/providers/database_helper.dart';
import 'package:gym/models/class.dart'; // Import Class to get schedule details

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
  List<DetailedClassBooking> _allBookings = []; // Keep all bookings
  List<DetailedClassBooking> _filteredBookings = []; // For search results
  bool _isLoading = false;

  ClassBookingProvider(this._dbHelper) {
    fetchClassBookings();
  }

  List<DetailedClassBooking> get bookings => _filteredBookings; // Returns current search results
  List<DetailedClassBooking> get allBookings => _allBookings; // Allows raw access to all data
  bool get isLoading => _isLoading;

  // NEW: Getter to get a set of unique dates that have bookings
  Set<DateTime> get bookingDates {
    return _allBookings.map((db) {
      final date = db.classScheduleTime; // Use class schedule time for calendar events
      return DateTime.utc(date.year, date.month, date.day); // Normalize to UTC date-only
    }).toSet();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> fetchClassBookings() async {
    _setLoading(true);
    try {
      final bookingMaps = await _dbHelper.getDetailedClassBookings();
      _allBookings = bookingMaps.map((map) => DetailedClassBooking.fromMap(map)).toList();
      _filteredBookings = List.from(_allBookings); // Initialize filtered with all
    } catch (e) {
      print('Error fetching class bookings: $e');
    } finally {
      _setLoading(false);
    }
  }

  // NEW: Get bookings for a specific day
  List<DetailedClassBooking> getBookingsForDay(DateTime day) {
    return _allBookings.where((db) {
      final classDate = db.classScheduleTime; // Use class schedule time for events
      return classDate.year == day.year &&
             classDate.month == day.month &&
             classDate.day == day.day;
    }).toList();
  }

  // NEW: Get booking counts for a given month (for stats cards)
  Map<String, int> getBookingCountsForMonth(DateTime month) {
    final startOfMonth = DateTime.utc(month.year, month.month, 1);
    final endOfMonth = DateTime.utc(month.year, month.month + 1, 0, 23, 59, 59);

    final bookingsInMonth = _allBookings.where((db) =>
        db.classScheduleTime.isAfter(startOfMonth.subtract(const Duration(days: 1))) &&
        db.classScheduleTime.isBefore(endOfMonth.add(const Duration(days: 1)))
    );

    int confirmed = 0;
    int cancelled = 0;
    int attended = 0;
    int noShow = 0;

    for (var booking in bookingsInMonth) {
      switch (booking.booking.status.toLowerCase()) {
        case 'confirmed': confirmed++; break;
        case 'cancelled': cancelled++; break;
        case 'attended': attended++; break;
        case 'no show': noShow++; break;
      }
    }

    return {
      'Confirmed': confirmed,
      'Cancelled': cancelled,
      'Attended': attended,
      'No Show': noShow,
    };
  }

  Future<void> addClassBooking(ClassBooking booking) async {
    try {
      await _dbHelper.insertClassBooking(booking.toJson());
      await fetchClassBookings(); // Re-fetch to update all data and notify listeners
    } catch (e) {
      print('Error adding class booking: $e');
      rethrow;
    }
  }

  Future<void> updateClassBooking(ClassBooking booking) async {
    try {
      await _dbHelper.updateClassBooking(booking.toJson());
      await fetchClassBookings(); // Re-fetch to update all data and notify listeners
    } catch (e) {
      print('Error updating class booking: $e');
      rethrow;
    }
  }

  Future<void> deleteClassBooking(String bookingId) async {
    try {
      await _dbHelper.deleteClassBooking(bookingId);
      await fetchClassBookings(); // Re-fetch to update all data and notify listeners
    } catch (e) {
      print('Error deleting class booking: $e');
    }
  }

  // This search method is now for general filtering if needed, not primary calendar interaction
  void searchClassBookings(String query) {
    if (query.isEmpty) {
      _filteredBookings = List.from(_allBookings);
    } else {
      _filteredBookings = _allBookings.where((booking) {
        final lowerCaseQuery = query.toLowerCase();
        return booking.customerFirstName.toLowerCase().contains(lowerCaseQuery) ||
               booking.customerLastName.toLowerCase().contains(lowerCaseQuery) ||
               booking.className.toLowerCase().contains(lowerCaseQuery) ||
               booking.booking.status.toLowerCase().contains(lowerCaseQuery) ||
               (booking.trainerFirstName?.toLowerCase().contains(lowerCaseQuery) ?? false) ||
               (booking.trainerLastName?.toLowerCase().contains(lowerCaseQuery) ?? false);
      }).toList();
    }
    notifyListeners();
  }
}