// lib/providers/trainer_package_provider.dart

import 'package:flutter/material.dart';
import 'package:gym/models/trainer_package.dart';
import 'package:gym/providers/database_helper.dart';

class DetailedTrainerPackage {
  final TrainerPackage package;
  final String customerName;
  final String trainerName;

  DetailedTrainerPackage(
    this.package,
    this.customerName,
    this.trainerName,
  );
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

  // -------------------------------------------------------------
  // FETCH PACKAGES
  // -------------------------------------------------------------
  Future<void> fetchPackages() async {
    _isLoading = true;
    notifyListeners();

    try {
      final rows = await _dbHelper.getTrainerPackages();
      _packages = rows.map((row) {
        return DetailedTrainerPackage(
          TrainerPackage.fromJson(row),
          "${row['c_first']} ${row['c_last']}",
          "${row['t_first']} ${row['t_last']}",
        );
      }).toList();
    } catch (e) {
      print("Error fetching trainer packages: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // -------------------------------------------------------------
  // ADD PACKAGE
  // -------------------------------------------------------------
  Future<void> addPackage(TrainerPackage pkg) async {
    try {
      await _dbHelper.insertTrainerPackage(pkg.toJson());
    } catch (e) {
      print("Error adding package: $e");
    }
    await fetchPackages();
  }

  // -------------------------------------------------------------
  // UPDATE PACKAGE
  // -------------------------------------------------------------
  Future<void> updatePackage(TrainerPackage pkg) async {
    try {
      await _dbHelper.updateTrainerPackage(pkg.toJson());
    } catch (e) {
      print("Error updating package: $e");
    }
    await fetchPackages();
  }

  // -------------------------------------------------------------
  // DELETE PACKAGE
  // -------------------------------------------------------------
  Future<void> deletePackage(String id) async {
    try {
      await _dbHelper.deleteTrainerPackage(id);
    } catch (e) {
      print("Error deleting package: $e");
    }
    await fetchPackages();
  }

  // -------------------------------------------------------------
  // CONSUME SESSION
  // -------------------------------------------------------------
  Future<void> useSession(String packageId) async {
    try {
      final db = await _dbHelper.database;
      await db.rawUpdate(
        """
        UPDATE TRAINER_PACKAGE
        SET sessions_used = sessions_used + 1
        WHERE package_id = ?
        """,
        [packageId],
      );
    } catch (e) {
      print("Error updating sessions: $e");
    }
    await fetchPackages();
  }

  // -------------------------------------------------------------
  // GET PACKAGES FOR SPECIFIC CUSTOMER
  // (Fix for your error in AddTrainerPackageScreen)
  // -------------------------------------------------------------
  List<TrainerPackage> getPackagesForCustomer(String customerId) {
    return _packages
        .map((p) => p.package)
        .where((pkg) => pkg.customerId == customerId)
        .toList();
  }

  // -------------------------------------------------------------
  // CHECK IF CUSTOMER HAS UNFULFILLED SESSIONS
  // -------------------------------------------------------------
  bool customerHasUnfulfilledSessions(String customerId) {
    final userPackages = getPackagesForCustomer(customerId);

    for (var pkg in userPackages) {
      if (pkg.totalSessions != -1) {
        if (pkg.sessionsRemaining > 0 && pkg.status == "Active") {
          return true;
        }
      }
    }
    return false;
  }

  // -------------------------------------------------------------
  // CHECK IF CUSTOMER HAS AN ACTIVE PACKAGE
  // -------------------------------------------------------------
  bool customerHasActivePackage(String customerId) {
    return getPackagesForCustomer(customerId)
        .any((p) => p.status == "Active");
  }

  // -------------------------------------------------------------
  // CHECK IF CUSTOMER HAS ANY PACKAGE OVERLAP (Unlimited Time Package)
  // -------------------------------------------------------------
  bool customerHasActiveUnlimited(String customerId) {
    return getPackagesForCustomer(customerId)
        .any((p) => p.totalSessions == -1 && p.status == "Active");
  }

  // -------------------------------------------------------------
  // CHECK IF CUSTOMER HAS ANY EXPIRED BUT UNFULFILLED PACKAGE
  // -------------------------------------------------------------
  bool customerHasExpiredButUnfinished(String customerId) {
    final now = DateTime.now();

    return getPackagesForCustomer(customerId).any(
      (pkg) =>
          pkg.totalSessions != -1 &&
          pkg.endDate.isBefore(now) &&
          pkg.sessionsRemaining > 0,
    );
  }

  // -------------------------------------------------------------
  // GET ACTIVE PACKAGE COUNT
  // -------------------------------------------------------------
  int activePackageCount(String customerId) {
    return getPackagesForCustomer(customerId)
        .where((p) => p.status == "Active")
        .length;
  }
}
