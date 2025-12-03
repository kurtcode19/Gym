// lib/providers/membership_provider.dart

import 'package:flutter/material.dart';
import 'package:gym/models/membership.dart';
import 'package:gym/providers/database_helper.dart';

class DetailedMembership {
  final Membership membership;
  final String customerFirstName;
  final String customerLastName;
  final String planName;
  final double planMonthlyFee;

  DetailedMembership({
    required this.membership,
    required this.customerFirstName,
    required this.customerLastName,
    required this.planName,
    required this.planMonthlyFee,
  });

  factory DetailedMembership.fromMap(Map<String, dynamic> map) {
    return DetailedMembership(
      membership: Membership.fromJson(map),
      customerFirstName: map['customer_first_name'],
      customerLastName: map['customer_last_name'],
      planName: map['plan_name'],
      planMonthlyFee: map['plan_monthly_fee'],
    );
  }
}

class MembershipProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper;

  List<DetailedMembership> _memberships = [];
  List<DetailedMembership> _filteredMemberships = [];
  bool _isLoading = false;

  // NEW
  String currentFilter = "All";
  String _searchQuery = "";

  MembershipProvider(this._dbHelper) {
    fetchMemberships();
  }

  List<DetailedMembership> get memberships => _filteredMemberships;
  bool get isLoading => _isLoading;

  // -----------------------------
  // LOADING
  // -----------------------------
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // -----------------------------
  // FETCH MEMBERSHIPS
  // -----------------------------
  Future<void> fetchMemberships() async {
    _setLoading(true);
    try {
      final membershipMaps = await _dbHelper.getDetailedMemberships();
      _memberships = membershipMaps.map((map) => DetailedMembership.fromMap(map)).toList();

      // auto-update expired statuses
      await _checkAndUpdateExpiredMemberships();

      _applySearchAndFilter();
    } catch (e) {
      print('Error fetching memberships: $e');
    } finally {
      _setLoading(false);
    }
  }

  // -------------------------------------------
  // AUTO-EXPIRE MEMBERSHIPS PAST END DATE
  // -------------------------------------------
  Future<void> _checkAndUpdateExpiredMemberships() async {
    final now = DateTime.now();
    final toUpdate = <Membership>[];

    for (final dm in _memberships) {
      final m = dm.membership;

      if ((m.status.toLowerCase() == 'active' ||
           m.status.toLowerCase() == 'pending') &&
          m.endDate.isBefore(now)) {
        toUpdate.add(m.copyWith(status: "Expired"));
      }
    }

    for (final updated in toUpdate) {
      await _dbHelper.updateMembership(updated.toJson());
    }

    if (toUpdate.isNotEmpty) {
      final membershipMaps = await _dbHelper.getDetailedMemberships();
      _memberships = membershipMaps.map((map) => DetailedMembership.fromMap(map)).toList();
    }
  }

  // -------------------------------------------
  // PUBLIC CRUD
  // -------------------------------------------
  Future<void> addMembership(Membership membership) async {
    await _dbHelper.insertMembership(membership.toJson());
    await fetchMemberships();
  }

  Future<void> updateMembership(Membership membership) async {
    await _dbHelper.updateMembership(membership.toJson());
    await fetchMemberships();
  }

  Future<void> deleteMembership(String membershipId) async {
    await _dbHelper.deleteMembership(membershipId);
    _memberships.removeWhere((dm) => dm.membership.membershipId == membershipId);
    _applySearchAndFilter();
  }

  Future<void> setMembershipStatus(String membershipId, String newStatus) async {
    try {
      final dm = _memberships.firstWhere(
        (dm) => dm.membership.membershipId == membershipId,
      );

      final updated = dm.membership.copyWith(status: newStatus);
      await _dbHelper.updateMembership(updated.toJson());

      await fetchMemberships();
    } catch (e) {
      print("Status update failed: $e");
    }
  }

  // -------------------------------------------
  // SEARCH & FILTER ENGINE
  // -------------------------------------------
  void searchMemberships(String query) {
    _searchQuery = query.toLowerCase().trim();
    _applySearchAndFilter();
  }

  void applyFilter(String filter) {
    currentFilter = filter;
    _applySearchAndFilter();
  }

  void _applySearchAndFilter() {
    List<DetailedMembership> temp = List.from(_memberships);

    // ---------------- FILTERING ----------------
    final now = DateTime.now();

    switch (currentFilter) {
      case "Active":
        temp = temp.where((dm) => dm.membership.status.toLowerCase() == 'active').toList();
        break;

      case "Pending":
        temp = temp.where((dm) => dm.membership.status.toLowerCase() == 'pending').toList();
        break;

      case "Expired":
        temp = temp.where((dm) => dm.membership.status.toLowerCase() == 'expired').toList();
        break;

      case "Cancelled":
        temp = temp.where((dm) => dm.membership.status.toLowerCase() == 'cancelled').toList();
        break;

      case "Expiring Soon":
        final threshold = now.add(const Duration(days: 7));
        temp = temp.where((dm) {
          final m = dm.membership;
          return m.status.toLowerCase() == 'active' &&
              m.endDate.isBefore(threshold) &&
              !m.isExpired;
        }).toList();
        break;

      case "Expired This Month":
        temp = temp.where((dm) {
          final m = dm.membership;
          return m.status.toLowerCase() == 'expired' &&
              m.endDate.year == now.year &&
              m.endDate.month == now.month;
        }).toList();
        break;

      default:
        break; // "All"
    }

    // ---------------- SEARCH ----------------
    if (_searchQuery.isNotEmpty) {
      temp = temp.where((dm) {
        return dm.customerFirstName.toLowerCase().contains(_searchQuery) ||
               dm.customerLastName.toLowerCase().contains(_searchQuery) ||
               dm.planName.toLowerCase().contains(_searchQuery) ||
               dm.membership.status.toLowerCase().contains(_searchQuery);
      }).toList();
    }

    _filteredMemberships = temp;
    notifyListeners();
  }
}
