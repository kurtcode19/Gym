// lib/providers/class_booking_provider.dart - UPDATED CONTENT

import 'package:flutter/material.dart';
import 'package:gym/models/class_booking.dart';
import 'package:gym/providers/database_helper.dart';
import 'package:gym/models/class.dart';
import 'package:intl/intl.dart'; 

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
  String get trainerFullName => (trainerFirstName != null && trainerLastName != null) 
      ? '$trainerFirstName $trainerLastName' 
      : 'N/A';
}

class ClassBookingProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper;
  List<DetailedClassBooking> _allBookings = []; 
  List<DetailedClassBooking> _filteredBookings = []; 
  bool _isLoading = false;

  ClassBookingProvider(this._dbHelper) {
    fetchClassBookings();
  }

  List<DetailedClassBooking> get bookings => _filteredBookings; 
  List<DetailedClassBooking> get allBookings => _allBookings;
  bool get isLoading => _isLoading;

  Set<DateTime> get bookingDates {
    return _allBookings.map((db) {
      final date = db.classScheduleTime;
      return DateTime.utc(date.year, date.month, date.day); 
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
      _filteredBookings = List.from(_allBookings); 
    } catch (e) {
      print('Error fetching class bookings: $e');
    } finally {
      _setLoading(false);
    }
  }

  List<DetailedClassBooking> getBookingsForDay(DateTime day) {
    return _allBookings.where((db) {
      final classDate = db.classScheduleTime;
      return classDate.year == day.year &&
             classDate.month == day.month &&
             classDate.day == day.day;
    }).toList();
  }

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

    return {'Confirmed': confirmed, 'Cancelled': cancelled, 'Attended': attended, 'No Show': noShow};
  }

  // --- NEW: VALIDATION LOGIC ---
  // Requires the details of the Class being booked to check for time overlaps
  String? validateBooking(String customerId, GymClass targetClass, {String? excludeBookingId}) {
    // 1. Get all active bookings for this customer
    final customerBookings = _allBookings.where((b) => 
      b.booking.customerId == customerId && 
      b.booking.status != 'Cancelled' && 
      b.booking.bookingId != excludeBookingId // Skip itself if editing
    ).toList();

    // 2. Define Time Range for New Booking
    final newStart = targetClass.scheduleTime;
    final newEnd = newStart.add(Duration(minutes: targetClass.durationMinutes));

    // 3. Check for Overlap
    for (var existing in customerBookings) {
      final existingStart = existing.classScheduleTime;
      final existingEnd = existingStart.add(Duration(minutes: existing.classDurationMinutes));

      // Overlap Logic: (StartA < EndB) and (EndA > StartB)
      if (newStart.isBefore(existingEnd) && newEnd.isAfter(existingStart)) {
        return "Customer is already booked for '${existing.className}' at this time (${DateFormat('h:mm a').format(existingStart)}).";
      }
    }
    return null; // No conflict
  }

  Future<void> addClassBooking(ClassBooking booking) async {
    try {
      await _dbHelper.insertClassBooking(booking.toJson());
      await fetchClassBookings(); 
    } catch (e) {
      print('Error adding class booking: $e');
      rethrow;
    }
  }

  Future<void> updateClassBooking(ClassBooking booking) async {
    try {
      await _dbHelper.updateClassBooking(booking.toJson());
      await fetchClassBookings();
    } catch (e) {
      print('Error updating class booking: $e');
      rethrow;
    }
  }

  Future<void> deleteClassBooking(String bookingId) async {
    try {
      await _dbHelper.deleteClassBooking(bookingId);
      await fetchClassBookings();
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
