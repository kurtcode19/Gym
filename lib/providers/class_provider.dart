// lib/providers/class_provider.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:gym/models/class.dart';
import 'package:gym/providers/database_helper.dart';

// Joined class model
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

  String get trainerFullName =>
      (trainerFirstName != null && trainerLastName != null)
          ? "$trainerFirstName $trainerLastName"
          : "N/A";
}

class ClassProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper;

  List<DetailedGymClass> _allClasses = [];
  List<DetailedGymClass> _filteredClasses = [];

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<DetailedGymClass> get classes => _filteredClasses;

  final TimeOfDay gymOpenTime = const TimeOfDay(hour: 6, minute: 0);  // 6 AM
  final TimeOfDay gymCloseTime = const TimeOfDay(hour: 22, minute: 0); // 10 PM

  ClassProvider(this._dbHelper) {
    fetchGymClasses();
  }

  // Return unique dates of scheduled classes
  Set<DateTime> get allClassDates {
    return _allClasses.map((dc) {
      final d = dc.gymClass.scheduleTime;
      return DateTime(d.year, d.month, d.day);
    }).toSet();
  }

  // -------------------------------
  // LOADING STATE
  // -------------------------------
  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }

  // -------------------------------
  // FETCH ALL CLASSES
  // -------------------------------
  Future<void> fetchGymClasses() async {
    _setLoading(true);
    try {
      final rows = await _dbHelper.getDetailedClasses();
      _allClasses = rows.map((e) => DetailedGymClass.fromMap(e)).toList();

      _filteredClasses = List.from(_allClasses);
      notifyListeners();
    } catch (e) {
      print("Error loading classes: $e");
    } finally {
      _setLoading(false);
    }
  }

  // -------------------------------
  // FILTER LOGIC
  // -------------------------------
  void filterClasses({DateTime? date, String? trainerId, String? nameQuery}) {
    List<DetailedGymClass> list = List.from(_allClasses);

    if (date != null) {
      list = list.where((dc) {
        final dt = dc.gymClass.scheduleTime;
        return dt.year == date.year &&
            dt.month == date.month &&
            dt.day == date.day;
      }).toList();
    }

    if (trainerId != null) {
      list = list.where((dc) => dc.gymClass.trainerId == trainerId).toList();
    }

    if (nameQuery != null && nameQuery.trim().isNotEmpty) {
      final q = nameQuery.toLowerCase();
      list = list.where((dc) {
        return dc.gymClass.className.toLowerCase().contains(q) ||
            (dc.trainerFirstName?.toLowerCase().contains(q) ?? false) ||
            (dc.trainerLastName?.toLowerCase().contains(q) ?? false);
      }).toList();
    }

    _filteredClasses = list;
    notifyListeners();
  }

  // -------------------------------
  // CORE: FULL CONFLICT VALIDATION
  // -------------------------------
  String? validateFullConflict(GymClass newClass, {String? excludeId}) {
    final newStart = newClass.scheduleTime;
    final newEnd =
        newStart.add(Duration(minutes: newClass.durationMinutes));

    // Validate duration
    if (newClass.durationMinutes < 30) {
      return "Class duration must be at least 30 minutes.";
    }
    if (newClass.durationMinutes > 180) {
      return "Class duration cannot exceed 180 minutes.";
    }

    // Validate gym hours
    final startMin = newStart.hour * 60 + newStart.minute;
    final endMin = newEnd.hour * 60 + newEnd.minute;
    final openMin = gymOpenTime.hour * 60 + gymOpenTime.minute;
    final closeMin = gymCloseTime.hour * 60 + gymCloseTime.minute;

    if (startMin < openMin) return "Class starts before gym opens.";
    if (endMin > closeMin) return "Class ends after gym closes.";

    // Check all existing scheduled classes
    for (final dc in _allClasses) {
      final existing = dc.gymClass;

      if (excludeId != null && excludeId == existing.classId) continue;

      final eStart = existing.scheduleTime;
      final eEnd = eStart.add(Duration(minutes: existing.durationMinutes));

      // Overlap?
      final overlap = newStart.isBefore(eEnd) && newEnd.isAfter(eStart);
      if (!overlap) continue;

      // 1. Trainer conflict
      if (newClass.trainerId != null &&
          newClass.trainerId == existing.trainerId) {
        return "Trainer is already teaching '${existing.className}' at "
            "${DateFormat('MMM d, h:mm a').format(eStart)}";
      }

      // 2. Same-class-name conflict (optional but recommended)
      if (newClass.className == existing.className) {
        return "'${newClass.className}' is already scheduled at "
            "${DateFormat('MMM d, h:mm a').format(eStart)}";
      }

      // 3. Global gym slot conflict
      return "Another class ('${existing.className}') is already scheduled at "
          "${DateFormat('MMM d, h:mm a').format(eStart)}";
    }

    return null; // NO CONFLICT
  }

  // -------------------------------
  // BATCH VALIDATION
  // -------------------------------
  List<String> validateBatchSchedule(List<GymClass> list) {
    List<String> errors = [];

    for (final cls in list) {
      final err = validateFullConflict(cls);
      if (err != null) {
        errors.add("${DateFormat('MMM d, h:mm a').format(cls.scheduleTime)} → $err");
      }
    }

    return errors;
  }
Future<void> addBatchGymClasses(List<GymClass> newClasses) async {
  final db = await _dbHelper.database;

  await db.transaction((txn) async {
    for (final cls in newClasses) {
      await txn.insert('CLASS', cls.toJson());
    }
  });

  await fetchGymClasses(); // reload list after insertion
}
  // -------------------------------
  // CRUD OPERATIONS
  // -------------------------------
  Future<void> addGymClass(GymClass cls) async {
    await _dbHelper.insertClass(cls.toJson());
    await fetchGymClasses();
  }

  Future<void> updateGymClass(GymClass cls) async {
    await _dbHelper.updateClass(cls.toJson());
    await fetchGymClasses();
  }
  
  Future<void> deleteGymClass(String id) async {
    await _dbHelper.deleteClass(id);
    _allClasses.removeWhere((c) => c.gymClass.classId == id);
    _filteredClasses.removeWhere((c) => c.gymClass.classId == id);
    notifyListeners();
  }

  Future<void> deleteBatchGymClasses(List<String> ids) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      for (var id in ids) {
        await txn.delete('CLASS', where: 'class_id = ?', whereArgs: [id]);
      }
    });

    _allClasses.removeWhere((c) => ids.contains(c.gymClass.classId));
    _filteredClasses.removeWhere((c) => ids.contains(c.gymClass.classId));
    notifyListeners();
  }

  // -------------------------------
  // SEARCH
  // -------------------------------
  void searchGymClasses(String query) {
    filterClasses(nameQuery: query);
  }
}
