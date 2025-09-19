// lib/models/customer.dart
import 'package:uuid/uuid.dart';

class Customer {
  final String customerId;
  final String firstName;
  final String lastName;
  final String email;
  final String? phoneNumber;
  final DateTime dateJoined;
  final String? address;
  final String? emergencyContactPhone;

  Customer({
    String? customerId, // Nullable for new customers, auto-generated
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phoneNumber,
    DateTime? dateJoined, // Nullable for new customers, defaults to now
    this.address,
    this.emergencyContactPhone,
  })  : customerId = customerId ?? const Uuid().v4(),
        dateJoined = dateJoined ?? DateTime.now();

  // Convert a Customer object into a Map for SQLite insertion/update
  Map<String, dynamic> toJson() {
    return {
      'customer_id': customerId,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'phone_number': phoneNumber,
      'date_joined': dateJoined.millisecondsSinceEpoch ~/ 1000, // Unix timestamp
      'address': address,
      'emergency_contact_phone': emergencyContactPhone,
    };
  }

  // Create a Customer object from a Map (e.g., from SQLite query result)
  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      customerId: json['customer_id'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      email: json['email'],
      phoneNumber: json['phone_number'],
      dateJoined: DateTime.fromMillisecondsSinceEpoch(json['date_joined'] * 1000),
      address: json['address'],
      emergencyContactPhone: json['emergency_contact_phone'],
    );
  }

  // Helper for updating customer details (e.g., in provider)
  Customer copyWith({
    String? customerId,
    String? firstName,
    String? lastName,
    String? email,
    String? phoneNumber,
    DateTime? dateJoined,
    String? address,
    String? emergencyContactPhone,
  }) {
    return Customer(
      customerId: customerId ?? this.customerId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      dateJoined: dateJoined ?? this.dateJoined,
      address: address ?? this.address,
      emergencyContactPhone: emergencyContactPhone ?? this.emergencyContactPhone,
    );
  }
}