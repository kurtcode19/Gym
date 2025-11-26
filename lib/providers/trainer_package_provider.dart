import 'package:flutter/material.dart';
import 'package:gym/models/trainer_package.dart';
import 'package:gym/providers/database_helper.dart';

class DetailedTrainerPackage {
  final TrainerPackage package;
  final String customerName;
  final String trainerName;

  DetailedTrainerPackage(this.package, this.customerName, this.trainerName);
}

class TrainerPackageProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper;
  List<DetailedTrainerPackage> _packages = [];
  bool _isLoading = false;

  TrainerPackageProvider(this._dbHelper) {
    fetchPackages();
  }

  List<DetailedTrainerPackage> get packages => _packages;
  bool get isLoading => _isLoading;

  Future<void> fetchPackages() async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = await _dbHelper.getTrainerPackages();
      _packages = data.map((row) {
        return DetailedTrainerPackage(
          TrainerPackage.fromJson(row),
          '${row['c_first']} ${row['c_last']}',
          '${row['t_first']} ${row['t_last']}',
        );
      }).toList();
    } catch (e) {
      print("Error fetching packages: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addPackage(TrainerPackage package) async {
    await _dbHelper.insertTrainerPackage(package.toJson());
    await fetchPackages();
  }
  
  // Method to consume a session (Call this when a class is booked!)
  Future<void> useSession(String packageId) async {
    final db = await _dbHelper.database;
    await db.rawUpdate(
      'UPDATE TRAINER_PACKAGE SET sessions_used = sessions_used + 1 WHERE package_id = ?',
      [packageId]
    );
    await fetchPackages();
  }
}