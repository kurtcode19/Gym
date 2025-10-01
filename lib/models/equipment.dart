// lib/models/equipment.dart
import 'package:uuid/uuid.dart';

class Equipment {
  final String equipmentId;
  final String equipmentName;
  final DateTime purchaseDate;
  final String? condition; // e.g., 'New', 'Good', 'Fair', 'Needs Repair', 'Out of Service'

  Equipment({
    String? equipmentId,
    required this.equipmentName,
    DateTime? purchaseDate,
    this.condition = 'Good',
  })  : equipmentId = equipmentId ?? const Uuid().v4(),
        purchaseDate = purchaseDate ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'equipment_id': equipmentId,
      'equipment_name': equipmentName,
      'purchase_date': purchaseDate.millisecondsSinceEpoch ~/ 1000,
      'condition': condition,
    };
  }

  factory Equipment.fromJson(Map<String, dynamic> json) {
    return Equipment(
      equipmentId: json['equipment_id'],
      equipmentName: json['equipment_name'],
      purchaseDate: DateTime.fromMillisecondsSinceEpoch(json['purchase_date'] * 1000),
      condition: json['condition'],
    );
  }

  Equipment copyWith({
    String? equipmentId,
    String? equipmentName,
    DateTime? purchaseDate,
    String? condition,
  }) {
    return Equipment(
      equipmentId: equipmentId ?? this.equipmentId,
      equipmentName: equipmentName ?? this.equipmentName,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      condition: condition ?? this.condition,
    );
  }
}