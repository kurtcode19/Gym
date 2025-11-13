// lib/providers/class_provider.dart - UPDATED CONTENT

import 'package:flutter/material.dart';
import 'package:gym/models/class.dart';
import 'package:gym/providers/database_helper.dart';
import 'package:gym/models/trainer.dart';

// Model to hold joined class data for display
class DetailedGymClass {
  final GymClass gymClass; // Using 'Class' as the model type as per schema
  final String? trainerFirstName;
  final String? trainerLastName;

  DetailedGymClass({
    required this.gymClass,
    this.trainerFirstName,
    this.trainerLastName,
  });

  factory DetailedGymClass.fromMap(Map<String, dynamic> map) {
    return DetailedGymClass(
      gymClass: GymClass.fromJson(map), // Using Class.fromJson
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
  List<DetailedGymClass> _allClasses = []; // Stores all fetched classes
  List<DetailedGymClass> _filteredClasses = []; // Stores currently filtered classes
  bool _isLoading = false;

  ClassProvider(this._dbHelper) {
    fetchGymClasses(); // Fetch all classes on initialization
  }

  List<DetailedGymClass> get classes => _filteredClasses;
  bool get isLoading => _isLoading;

  // NEW: Getter to get a set of unique dates that have classes
  Set<DateTime> get classDates {
    return _allClasses.map((dc) {
      final date = dc.gymClass.scheduleTime;
      return DateTime.utc(date.year, date.month, date.day); // Use UTC to normalize dates
    }).toSet();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // Fetches all detailed classes, populating _allClasses
  Future<void> fetchGymClasses() async {
    _setLoading(true);
    try {
      final classMaps = await _dbHelper.getDetailedClasses();
      _allClasses = classMaps.map((map) => DetailedGymClass.fromMap(map)).toList();
      _filteredClasses = List.from(_allClasses); // Initially, filtered list is all classes
      // Apply the initial filter again if needed, or simply notify
      notifyListeners();
    } catch (e) {
      print('Error fetching gym classes: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Method to filter classes by date and/or trainer ID and/or name
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

  Future<void> addGymClass(GymClass gymClass) async {
    try {
      await _dbHelper.insertClass(gymClass.toJson());
      await fetchGymClasses(); // Re-fetch all to update the _allClasses and trigger re-filtering
    } catch (e) {
      print('Error adding gym class: $e');
      rethrow;
    }
  }

  Future<void> updateGymClass(GymClass gymClass) async {
    try {
      await _dbHelper.updateClass(gymClass.toJson());
      await fetchGymClasses(); // Re-fetch all to update the _allClasses and trigger re-filtering
    } catch (e) {
      print('Error updating gym class: $e');
      rethrow;
    }
  }

  Future<void> deleteGymClass(String classId) async {
    try {
      await _dbHelper.deleteClass(classId);
      _allClasses.removeWhere((c) => c.gymClass.classId == classId);
      _filteredClasses.removeWhere((c) => c.gymClass.classId == classId); // Also remove from current view
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