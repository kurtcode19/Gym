// lib/providers/trainer_provider.dart
import 'package:flutter/material.dart';
import 'package:gym/models/trainer.dart';
import 'package:gym/providers/database_helper.dart';
import 'package:gym/providers/class_provider.dart'; // Import for DetailedGymClass

class TrainerProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper;
  List<Trainer> _trainers = [];
  List<Trainer> _filteredTrainers = [];
  bool _isLoading = false;

  TrainerProvider(this._dbHelper) {
    fetchTrainers();
  }

  List<Trainer> get trainers => _filteredTrainers;
  bool get isLoading => _isLoading;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> fetchTrainers() async {
    _setLoading(true);
    try {
      final trainerMaps = await _dbHelper.getTrainers();
      _trainers = trainerMaps.map((map) => Trainer.fromJson(map)).toList();
      _filteredTrainers = List.from(_trainers);
    } catch (e) {
      print('Error fetching trainers: $e');
    } finally {
      _setLoading(false);
    }
  }

  // --- PAYOUT CALCULATION LOGIC ---

  // Helper to count sessions in a date range
  int getSessionCount(String trainerId, List<DetailedGymClass> allClasses, DateTime start, DateTime end) {
    // Normalize dates to ensure inclusive comparison (start of day to end of day)
    final startDate = DateTime(start.year, start.month, start.day);
    final endDate = DateTime(end.year, end.month, end.day, 23, 59, 59);

    return allClasses.where((c) {
      // Check if class belongs to this trainer
      if (c.gymClass.trainerId != trainerId) return false;
      
      // Check date range
      final classTime = c.gymClass.scheduleTime;
      return classTime.isAfter(startDate) && classTime.isBefore(endDate);
    }).length;
  }

  // Helper to calculate total pay
  double calculateTotalPay(String trainerId, List<DetailedGymClass> allClasses, DateTime start, DateTime end) {
    final trainer = _trainers.firstWhere(
      (t) => t.trainerId == trainerId,
      orElse: () => Trainer(trainerId: '', firstName: '', lastName: '', hireDate: DateTime.now()), // Fallback
    );
    
    final count = getSessionCount(trainerId, allClasses, start, end);
    return count * trainer.ratePerSession;
  }

  // --------------------------------

  Future<void> addTrainer(Trainer trainer) async {
    try {
      await _dbHelper.insertTrainer(trainer.toJson());
      _trainers.add(trainer);
      _filteredTrainers = List.from(_trainers);
      notifyListeners();
    } catch (e) {
      print('Error adding trainer: $e');
    }
  }

  Future<void> updateTrainer(Trainer trainer) async {
    try {
      await _dbHelper.updateTrainer(trainer.toJson());
      final index = _trainers.indexWhere((t) => t.trainerId == trainer.trainerId);
      if (index != -1) {
        _trainers[index] = trainer;
        _filteredTrainers = List.from(_trainers);
        notifyListeners();
      }
    } catch (e) {
      print('Error updating trainer: $e');
    }
  }

  Future<void> deleteTrainer(String trainerId) async {
    try {
      await _dbHelper.deleteTrainer(trainerId);
      _trainers.removeWhere((t) => t.trainerId == trainerId);
      _filteredTrainers.removeWhere((t) => t.trainerId == trainerId);
      notifyListeners();
    } catch (e) {
      print('Error deleting trainer: $e');
    }
  }

  void searchTrainers(String query) {
    if (query.isEmpty) {
      _filteredTrainers = List.from(_trainers);
    } else {
      _filteredTrainers = _trainers.where((trainer) {
        final lowerCaseQuery = query.toLowerCase();
        return trainer.firstName.toLowerCase().contains(lowerCaseQuery) ||
               trainer.lastName.toLowerCase().contains(lowerCaseQuery) ||
               (trainer.email?.toLowerCase().contains(lowerCaseQuery) ?? false);
      }).toList();
    }
    notifyListeners();
  }
}