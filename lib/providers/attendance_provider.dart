// lib/providers/attendance_provider.dart
import 'package:flutter/material.dart';
import 'package:gym/models/attendance.dart';
import 'package:gym/providers/database_helper.dart';
import 'package:gym/models/customer.dart';
import 'package:intl/intl.dart'; // For customer names

// Model to hold joined attendance data for display
class DetailedAttendance {
  final Attendance attendance;
  final String customerFirstName;
  final String customerLastName;

  DetailedAttendance({
    required this.attendance,
    required this.customerFirstName,
    required this.customerLastName,
  });

  factory DetailedAttendance.fromMap(Map<String, dynamic> map) {
    return DetailedAttendance(
      attendance: Attendance.fromJson(map),
      customerFirstName: map['customer_first_name'],
      customerLastName: map['customer_last_name'],
    );
  }
}

class AttendanceProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper;
  List<DetailedAttendance> _attendanceRecords = [];
  List<DetailedAttendance> _filteredAttendanceRecords = [];
  bool _isLoading = false;

  AttendanceProvider(this._dbHelper) {
    fetchAttendanceRecords();
  }

  List<DetailedAttendance> get attendanceRecords => _filteredAttendanceRecords;
  bool get isLoading => _isLoading;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> fetchAttendanceRecords() async {
    _setLoading(true);
    try {
      final attendanceMaps = await _dbHelper.getDetailedAttendanceRecords();
      _attendanceRecords = attendanceMaps.map((map) => DetailedAttendance.fromMap(map)).toList();
      _filteredAttendanceRecords = List.from(_attendanceRecords);
    } catch (e) {
      print('Error fetching detailed attendance records: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addAttendance(Attendance attendance) async {
    try {
      await _dbHelper.insertAttendance(attendance.toJson());
      await fetchAttendanceRecords(); // Re-fetch to get the detailed view
    } catch (e) {
      print('Error adding attendance record: $e');
    }
  }

  Future<void> updateAttendance(Attendance attendance) async {
    try {
      await _dbHelper.updateAttendance(attendance.toJson());
      await fetchAttendanceRecords(); // Re-fetch to get the detailed view
    } catch (e) {
      print('Error updating attendance record: $e');
    }
  }

  Future<void> deleteAttendance(String attendanceId) async {
    try {
      await _dbHelper.deleteAttendance(attendanceId);
      _attendanceRecords.removeWhere((a) => a.attendance.attendanceId == attendanceId);
      _filteredAttendanceRecords.removeWhere((a) => a.attendance.attendanceId == attendanceId);
      notifyListeners();
    } catch (e) {
      print('Error deleting attendance record: $e');
    }
  }

  void searchAttendanceRecords(String query) {
    if (query.isEmpty) {
      _filteredAttendanceRecords = List.from(_attendanceRecords);
    } else {
      _filteredAttendanceRecords = _attendanceRecords.where((detailedAttendance) {
        final lowerCaseQuery = query.toLowerCase();
        return detailedAttendance.customerFirstName.toLowerCase().contains(lowerCaseQuery) ||
               detailedAttendance.customerLastName.toLowerCase().contains(lowerCaseQuery) ||
               (detailedAttendance.attendance.facilityUsed?.toLowerCase().contains(lowerCaseQuery) ?? false) ||
               DateFormat('yyyy-MM-dd').format(detailedAttendance.attendance.date).contains(lowerCaseQuery);
      }).toList();
    }
    notifyListeners();
  }
}