// lib/providers/class_provider.dart
import 'package:flutter/material.dart';
import 'package:gym/models/class.dart';
import 'package:gym/providers/database_helper.dart';

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
  List<DetailedGymClass> _classes = [];
  List<DetailedGymClass> _filteredClasses = [];
  bool _isLoading = false;

  ClassProvider(this._dbHelper) {
    fetchGymClasses();
  }

  List<DetailedGymClass> get classes => _filteredClasses;
  bool get isLoading => _isLoading;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> fetchGymClasses() async {
    _setLoading(true);
    try {
      final classMaps = await _dbHelper.getClasses();
      _classes = classMaps.map((map) => DetailedGymClass.fromMap(map)).toList();
      _filteredClasses = List.from(_classes);
    } catch (e) {
      print('Error fetching gym classes: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addGymClass(GymClass gymClass) async {
    try {
      await _dbHelper.insertClass(gymClass.toJson());
      await fetchGymClasses(); // Re-fetch to update detailed view
    } catch (e) {
      print('Error adding gym class: $e');
    }
  }

  Future<void> updateGymClass(GymClass gymClass) async {
    try {
      await _dbHelper.updateClass(gymClass.toJson());
      await fetchGymClasses(); // Re-fetch to update detailed view
    } catch (e) {
      print('Error updating gym class: $e');
    }
  }

  Future<void> deleteGymClass(String classId) async {
    try {
      await _dbHelper.deleteClass(classId);
      _classes.removeWhere((c) => c.gymClass.classId == classId);
      _filteredClasses.removeWhere((c) => c.gymClass.classId == classId);
      notifyListeners();
    } catch (e) {
      print('Error deleting gym class: $e');
    }
  }

  void searchGymClasses(String query) {
    if (query.isEmpty) {
      _filteredClasses = List.from(_classes);
    } else {
      _filteredClasses = _classes.where((gymClass) {
        final lowerCaseQuery = query.toLowerCase();
        return gymClass.gymClass.className.toLowerCase().contains(lowerCaseQuery) ||
               (gymClass.trainerFirstName?.toLowerCase().contains(lowerCaseQuery) ?? false) ||
               (gymClass.trainerLastName?.toLowerCase().contains(lowerCaseQuery) ?? false);
      }).toList();
    }
    notifyListeners();
  }
}