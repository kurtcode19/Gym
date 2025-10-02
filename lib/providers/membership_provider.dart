// lib/providers/membership_provider.dart - UPDATED CONTENT

import 'package:flutter/material.dart';
import 'package:gym/models/membership.dart';
import 'package:gym/providers/database_helper.dart';

// A simple model to hold joined membership data for display
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

  MembershipProvider(this._dbHelper) {
    fetchMemberships();
  }

  List<DetailedMembership> get memberships => _filteredMemberships;
  bool get isLoading => _isLoading;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> fetchMemberships() async {
    _setLoading(true);
    try {
      final membershipMaps = await _dbHelper.getDetailedMemberships();
      _memberships = membershipMaps.map((map) => DetailedMembership.fromMap(map)).toList();
      _filteredMemberships = List.from(_memberships);
    } catch (e) {
      print('Error fetching detailed memberships: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addMembership(Membership membership) async {
    try {
      await _dbHelper.insertMembership(membership.toJson());
      await fetchMemberships(); // Re-fetch all to get the detailed view
    } catch (e) {
      print('Error adding membership: $e');
    }
  }

  // Existing update method, now with an added status change parameter
  Future<void> updateMembership(Membership membership) async {
    try {
      await _dbHelper.updateMembership(membership.toJson());
      await fetchMemberships(); // Re-fetch all to get the detailed view
    } catch (e) {
      print('Error updating membership: $e');
    }
  }

  // NEW: Method to specifically update the status of a membership
  Future<void> setMembershipStatus(String membershipId, String newStatus) async {
    try {
      final currentMembership = _memberships.firstWhere(
        (dm) => dm.membership.membershipId == membershipId,
        orElse: () => throw Exception('Membership not found with ID: $membershipId'),
      ).membership;

      if (currentMembership.status != newStatus) {
        final updatedMembership = currentMembership.copyWith(status: newStatus);
        await _dbHelper.updateMembership(updatedMembership.toJson());
        await fetchMemberships(); // Refresh list after update
      }
    } catch (e) {
      print('Error setting membership status: $e');
    }
  }

  Future<void> deleteMembership(String membershipId) async {
    try {
      await _dbHelper.deleteMembership(membershipId);
      _memberships.removeWhere((m) => m.membership.membershipId == membershipId);
      _filteredMemberships.removeWhere((m) => m.membership.membershipId == membershipId);
      notifyListeners();
    } catch (e) {
      print('Error deleting membership: $e');
    }
  }

  void searchMemberships(String query) {
    if (query.isEmpty) {
      _filteredMemberships = List.from(_memberships);
    } else {
      _filteredMemberships = _memberships.where((membership) {
        final lowerCaseQuery = query.toLowerCase();
        return membership.customerFirstName.toLowerCase().contains(lowerCaseQuery) ||
               membership.customerLastName.toLowerCase().contains(lowerCaseQuery) ||
               membership.planName.toLowerCase().contains(lowerCaseQuery) ||
               membership.membership.status.toLowerCase().contains(lowerCaseQuery);
      }).toList();
    }
    notifyListeners();
  }
}