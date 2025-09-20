// lib/providers/attendance_provider.dart
import 'package:flutter/material.dart';
import 'package:gym/models/attendance.dart';
import 'package:gym/providers/database_helper.dart';

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
  List<DetailedAttendance> _records = [];
  List<DetailedAttendance> _filteredRecords = [];
  bool _isLoading = false;

  AttendanceProvider(this._dbHelper) {
    fetchAttendanceRecords();
  }

  List<DetailedAttendance> get records => _filteredRecords;
  bool get isLoading => _isLoading;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> fetchAttendanceRecords() async {
    _setLoading(true);
    try {
      final recordMaps = await _dbHelper.getAttendanceRecords();
      _records = recordMaps.map((map) => DetailedAttendance.fromMap(map)).toList();
      _filteredRecords = List.from(_records);
    } catch (e) {
      print('Error fetching attendance records: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addAttendance(Attendance attendance) async {
    try {
      await _dbHelper.insertAttendance(attendance.toJson());
      await fetchAttendanceRecords(); // Re-fetch to update detailed view
    } catch (e) {
      print('Error adding attendance: $e');
    }
  }

  Future<void> updateAttendance(Attendance attendance) async {
    try {
      await _dbHelper.updateAttendance(attendance.toJson());
      await fetchAttendanceRecords(); // Re-fetch to update detailed view
    } catch (e) {
      print('Error updating attendance: $e');
    }
  }

  Future<void> deleteAttendance(String attendanceId) async {
    try {
      await _dbHelper.deleteAttendance(attendanceId);
      _records.removeWhere((r) => r.attendance.attendanceId == attendanceId);
      _filteredRecords.removeWhere((r) => r.attendance.attendanceId == attendanceId);
      notifyListeners();
    } catch (e) {
      print('Error deleting attendance: $e');
    }
  }

  void searchAttendance(String query) {
    if (query.isEmpty) {
      _filteredRecords = List.from(_records);
    } else {
      _filteredRecords = _records.where((record) {
        final lowerCaseQuery = query.toLowerCase();
        return record.customerFirstName.toLowerCase().contains(lowerCaseQuery) ||
               record.customerLastName.toLowerCase().contains(lowerCaseQuery) ||
               (record.attendance.facilityUsed?.toLowerCase().contains(lowerCaseQuery) ?? false);
      }).toList();
    }
    notifyListeners();
  }
}