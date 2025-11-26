// lib/providers/class_provider.dart - UPDATED CONTENT

import 'package:flutter/material.dart';
import 'package:gym/models/class.dart';
import 'package:gym/providers/database_helper.dart';
import 'package:gym/models/trainer.dart';

// Model to hold joined class data for display
class DetailedGymClass {
  final GymClass gymClass; 
  final String? trainerFirstName;
  final String? trainerLastName;

  DetailedGymClass({
    required this.gymClass,
    this.trainerFirstName,
    this.trainerLastName,
  });

  factory DetailedGymClass.fromMap(Map<String, dynamic> map) {
    return DetailedGymClass(
      gymClass: GymClass.fromJson(map),
      trainerFirstName: map['trainer_first_name'],
      trainerLastName: map['trainer_last_name'],
    );
  }

  String get trainerFullName {
    if (trainerFirstName != null && trainerLastName != null) {
      return '$trainerFirstName $trainerLastName';
    }
    return 'N/A';
  }
}

class ClassProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper;
  List<DetailedGymClass> _allClasses = []; 
  List<DetailedGymClass> _filteredClasses = []; 
  bool _isLoading = false;

  final TimeOfDay gymOpenTime = const TimeOfDay(hour: 6, minute: 0);
  final TimeOfDay gymCloseTime = const TimeOfDay(hour: 22, minute: 0);

  ClassProvider(this._dbHelper) {
    fetchGymClasses(); 
  }


  List<DetailedGymClass> get classes => _filteredClasses;
  bool get isLoading => _isLoading;

  Set<DateTime> get classDates {
    return _allClasses.map((dc) {
      final date = dc.gymClass.scheduleTime;
      return DateTime.utc(date.year, date.month, date.day); 
    }).toSet();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> fetchGymClasses() async {
    _setLoading(true);
    try {
      final classMaps = await _dbHelper.getDetailedClasses();
      _allClasses = classMaps.map((map) => DetailedGymClass.fromMap(map)).toList();
      _filteredClasses = List.from(_allClasses); 
      notifyListeners();
    } catch (e) {
      print('Error fetching gym classes: $e');
    } finally {
      _setLoading(false);
    }
  }

  void filterClasses({DateTime? date, String? trainerId, String? nameQuery}) {
    List<DetailedGymClass> currentFilteredList = List.from(_allClasses);

    if (date != null) {
      currentFilteredList = currentFilteredList.where((dc) {
        final classDate = DateTime(dc.gymClass.scheduleTime.year, dc.gymClass.scheduleTime.month, dc.gymClass.scheduleTime.day);
        return classDate.isAtSameMomentAs(DateTime(date.year, date.month, date.day));
      }).toList();
    }

    if (trainerId != null) {
      currentFilteredList = currentFilteredList.where((dc) => dc.gymClass.trainerId == trainerId).toList();
    }

    if (nameQuery != null && nameQuery.isNotEmpty) {
      final lowerCaseQuery = nameQuery.toLowerCase();
      currentFilteredList = currentFilteredList.where((dc) =>
        dc.gymClass.className.toLowerCase().contains(lowerCaseQuery) ||
        (dc.trainerFirstName?.toLowerCase().contains(lowerCaseQuery) ?? false) ||
        (dc.trainerLastName?.toLowerCase().contains(lowerCaseQuery) ?? false)
      ).toList();
    }

    _filteredClasses = currentFilteredList;
    notifyListeners();
  }

 String? validateClassSchedule(GymClass newClass) {
    // 1. Duration Trap
    if (newClass.durationMinutes < 30) {
      return "Class duration is too short. Minimum is 30 minutes.";
    }
    if (newClass.durationMinutes > 120) {
      return "Class duration is too long. Maximum is 120 minutes.";
    }

    final newStart = newClass.scheduleTime;
    final newEnd = newStart.add(Duration(minutes: newClass.durationMinutes));

    // 2. Check Operating Hours
    final startMinutes = newStart.hour * 60 + newStart.minute;
    final endMinutes = newEnd.hour * 60 + newEnd.minute;
    final openMinutes = gymOpenTime.hour * 60 + gymOpenTime.minute;
    final closeMinutes = gymCloseTime.hour * 60 + gymCloseTime.minute;

    if (startMinutes < openMinutes) return "Class starts before opening hours.";
    if (endMinutes > closeMinutes || newEnd.day != newStart.day) return "Class ends after closing hours.";

    // 3. Check for Conflicts
    for (var detailedClass in _allClasses) {
      final existingClass = detailedClass.gymClass;
      if (existingClass.classId == newClass.classId) continue; // Skip self

      final existingStart = existingClass.scheduleTime;
      final existingEnd = existingStart.add(Duration(minutes: existingClass.durationMinutes));

      // Overlap Check
      if (newStart.isBefore(existingEnd) && newEnd.isAfter(existingStart)) {
        // Trainer Conflict
        if (newClass.trainerId != null && newClass.trainerId == existingClass.trainerId) {
          return "Trainer is already booked for '${existingClass.className}' at this time.";
        }
        // Room/Space Conflict (Optional: Uncomment to enforce 1 class at a time in the whole gym)
        // return "Time slot conflicts with '${existingClass.className}'."; 
      }
    }
    return null; // Valid
  }
  // Validate a list of classes and return a list of errors (if any)
  List<String> validateBatchSchedule(List<GymClass> newClasses) {
    List<String> errors = [];
    for (var cls in newClasses) {
      String? error = validateClassSchedule(cls);
      if (error != null) {
        errors.add("${cls.scheduleTime.toString().split('.')[0]}: $error");
      }
    }
    return errors;
  }

  Future<void> addBatchGymClasses(List<GymClass> newClasses) async {
    final db = await _dbHelper.database;
    // Use a transaction for safety/speed
    await db.transaction((txn) async {
      for (var cls in newClasses) {
        await txn.insert('CLASS', cls.toJson());
      }
    });
    await fetchGymClasses();
  }
// Add this inside ClassProvider class
Future<void> deleteBatchGymClasses(List<String> classIds) async {
  final db = await _dbHelper.database;
  await db.transaction((txn) async {
    for (var id in classIds) {
      await txn.delete('CLASS', where: 'class_id = ?', whereArgs: [id]);
    }
  });
  // Update local state
  _allClasses.removeWhere((c) => classIds.contains(c.gymClass.classId));
  _filteredClasses.removeWhere((c) => classIds.contains(c.gymClass.classId));
  notifyListeners();
}

  Future<void> addGymClass(GymClass gymClass) async {
    try {
      await _dbHelper.insertClass(gymClass.toJson());
      await fetchGymClasses(); 
    } catch (e) {
      print('Error adding gym class: $e');
      rethrow;
    }
  }

  Future<void> updateGymClass(GymClass gymClass) async {
    try {
      await _dbHelper.updateClass(gymClass.toJson());
      await fetchGymClasses(); 
    } catch (e) {
      print('Error updating gym class: $e');
      rethrow;
    }
  }

  Future<void> deleteGymClass(String classId) async {
    try {
      await _dbHelper.deleteClass(classId);
      _allClasses.removeWhere((c) => c.gymClass.classId == classId);
      _filteredClasses.removeWhere((c) => c.gymClass.classId == classId);
      notifyListeners();
    } catch (e) {
      print('Error deleting gym class: $e');
    }
  }

  @override
  void searchGymClasses(String query) {
    filterClasses(nameQuery: query);
  }
}