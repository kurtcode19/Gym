// lib/providers/equipment_provider.dart
import 'package:flutter/material.dart';
import 'package:gym/models/equipment.dart'; // Corrected import
import 'package:gym/providers/database_helper.dart'; // Corrected import
import 'package:intl/intl.dart';

class EquipmentProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper;
  List<Equipment> _equipmentList = [];
  List<Equipment> _filteredEquipmentList = [];
  bool _isLoading = false;

  EquipmentProvider(this._dbHelper) {
    fetchEquipment();
  }

  List<Equipment> get equipmentList => _filteredEquipmentList;
  bool get isLoading => _isLoading;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> fetchEquipment() async {
    _setLoading(true);
    try {
      final equipmentMaps = await _dbHelper.getEquipment();
      _equipmentList = equipmentMaps.map((map) => Equipment.fromJson(map)).toList();
      _filteredEquipmentList = List.from(_equipmentList);
    } catch (e) {
      print('Error fetching equipment: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addEquipment(Equipment equipment) async {
    try {
      await _dbHelper.insertEquipment(equipment.toJson());
      _equipmentList.add(equipment);
      _filteredEquipmentList = List.from(_equipmentList);
      notifyListeners();
    } catch (e) {
      print('Error adding equipment: $e');
    }
  }

  Future<void> updateEquipment(Equipment equipment) async {
    try {
      await _dbHelper.updateEquipment(equipment.toJson());
      final index = _equipmentList.indexWhere((e) => e.equipmentId == equipment.equipmentId);
      if (index != -1) {
        _equipmentList[index] = equipment;
        _filteredEquipmentList = List.from(_equipmentList);
        notifyListeners();
      }
    } catch (e) {
      print('Error updating equipment: $e');
    }
  }

  Future<void> deleteEquipment(String equipmentId) async {
    try {
      await _dbHelper.deleteEquipment(equipmentId);
      _equipmentList.removeWhere((e) => e.equipmentId == equipmentId);
      _filteredEquipmentList.removeWhere((e) => e.equipmentId == equipmentId);
      notifyListeners();
    } catch (e) {
      print('Error deleting equipment: $e');
    }
  }

  void searchEquipment(String query) {
    if (query.isEmpty) {
      _filteredEquipmentList = List.from(_equipmentList);
    } else {
      _filteredEquipmentList = _equipmentList.where((equipment) {
        final lowerCaseQuery = query.toLowerCase();
        return equipment.equipmentName.toLowerCase().contains(lowerCaseQuery) ||
               (equipment.condition?.toLowerCase().contains(lowerCaseQuery) ?? false) ||
               DateFormat('yyyy-MM-dd').format(equipment.purchaseDate).contains(lowerCaseQuery);
      }).toList();
    }
    notifyListeners();
  }
}