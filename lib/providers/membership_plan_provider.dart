// lib/providers/membership_plan_provider.dart - UPDATED CONTENT
import 'package:flutter/material.dart';
import 'package:gym/models/membership_plan.dart'; // Corrected import
import 'package:gym/providers/database_helper.dart'; // Corrected import

class MembershipPlanProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper;
  List<MembershipPlan> _plans = [];
  List<MembershipPlan> _filteredPlans = [];
  bool _isLoading = false;

  MembershipPlanProvider(this._dbHelper) {
    fetchMembershipPlans();
  }

  List<MembershipPlan> get plans => _filteredPlans;
  bool get isLoading => _isLoading;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> fetchMembershipPlans() async {
    _setLoading(true);
    try {
      final planMaps = await _dbHelper.getMembershipPlans();
      _plans = planMaps.map((map) => MembershipPlan.fromJson(map)).toList();
      _filteredPlans = List.from(_plans);
    } catch (e) {
      print('Error fetching membership plans: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addMembershipPlan(MembershipPlan plan) async {
    try {
      await _dbHelper.insertMembershipPlan(plan.toJson());
      _plans.add(plan);
      _filteredPlans = List.from(_plans);
      notifyListeners();
    } catch (e) {
      print('Error adding membership plan: $e');
    }
  }

  Future<void> updateMembershipPlan(MembershipPlan plan) async {
    try {
      await _dbHelper.updateMembershipPlan(plan.toJson());
      final index = _plans.indexWhere((p) => p.planId == plan.planId);
      if (index != -1) {
        _plans[index] = plan;
        _filteredPlans = List.from(_plans);
        notifyListeners();
      }
    } catch (e) {
      print('Error updating membership plan: $e');
    }
  }

  Future<void> deleteMembershipPlan(String planId) async {
    try {
      await _dbHelper.deleteMembershipPlan(planId);
      _plans.removeWhere((p) => p.planId == planId);
      _filteredPlans.removeWhere((p) => p.planId == planId);
      notifyListeners();
    } catch (e) {
      print('Error deleting membership plan: $e');
    }
  }

  void searchMembershipPlans(String query) {
    if (query.isEmpty) {
      _filteredPlans = List.from(_plans);
    } else {
      _filteredPlans = _plans.where((plan) {
        final lowerCaseQuery = query.toLowerCase();
        return plan.planName.toLowerCase().contains(lowerCaseQuery) ||
               plan.durationUnit.toDisplayString().toLowerCase().contains(lowerCaseQuery) ||
               plan.durationValue.toString().contains(lowerCaseQuery);
      }).toList();
    }
    notifyListeners();
  }
}