// lib/models/trainer.dart
import 'package:uuid/uuid.dart';

class Trainer {
  final String trainerId;
  final String firstName;
  final String lastName;
  final String? email;
  final String? phoneNumber;
  final DateTime hireDate;

  Trainer({
    String? trainerId,
    required this.firstName,
    required this.lastName,
    this.email,
    this.phoneNumber,
    DateTime? hireDate,
  })  : trainerId = trainerId ?? const Uuid().v4(),
        hireDate = hireDate ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'trainer_id': trainerId,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'phone_number': phoneNumber,
      'hire_date': hireDate.millisecondsSinceEpoch ~/ 1000,
    };
  }

  factory Trainer.fromJson(Map<String, dynamic> json) {
    return Trainer(
      trainerId: json['trainer_id'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      email: json['email'],
      phoneNumber: json['phone_number'],
      hireDate: DateTime.fromMillisecondsSinceEpoch(json['hire_date'] * 1000),
    );
  }

  Trainer copyWith({
    String? trainerId,
    String? firstName,
    String? lastName,
    String? email,
    String? phoneNumber,
    DateTime? hireDate,
  }) {
    return Trainer(
      trainerId: trainerId ?? this.trainerId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      hireDate: hireDate ?? this.hireDate,
    );
  }
}