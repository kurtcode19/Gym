// lib/providers/customer_provider.dart
import 'package:flutter/material.dart';
import 'package:gym/models/customer.dart';
import 'package:gym/providers/database_helper.dart'; // Access the singleton

class CustomerProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper;
  List<Customer> _customers = [];
  List<Customer> _filteredCustomers = []; // For search functionality
  bool _isLoading = false;

  CustomerProvider(this._dbHelper) {
    fetchCustomers(); // Fetch customers when the provider is initialized
  }

  List<Customer> get customers => _filteredCustomers; // Expose filtered list
  bool get isLoading => _isLoading;

  // Set loading state and notify listeners
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // Fetch all customers from the database
  Future<void> fetchCustomers() async {
    _setLoading(true);
    try {
      final customerMaps = await _dbHelper.getCustomers();
      _customers = customerMaps.map((map) => Customer.fromJson(map)).toList();
      _filteredCustomers = List.from(_customers); // Initialize filtered list
    } catch (e) {
      print('Error fetching customers: $e');
      // Handle error, e.g., show a snackbar
    } finally {
      _setLoading(false);
    }
  }

  // Add a new customer to the database and update state
  Future<void> addCustomer(Customer customer) async {
    try {
      await _dbHelper.insertCustomer(customer.toJson());
      _customers.add(customer);
      _filteredCustomers = List.from(_customers); // Update filtered list
      notifyListeners();
    } catch (e) {
      print('Error adding customer: $e');
    }
  }

  // Update an existing customer in the database and update state
  Future<void> updateCustomer(Customer customer) async {
    try {
      await _dbHelper.updateCustomer(customer.toJson());
      final index = _customers.indexWhere((c) => c.customerId == customer.customerId);
      if (index != -1) {
        _customers[index] = customer;
        _filteredCustomers = List.from(_customers); // Update filtered list
        notifyListeners();
      }
    } catch (e) {
      print('Error updating customer: $e');
    }
  }

  // Delete a customer from the database and update state
  Future<void> deleteCustomer(String customerId) async {
    try {
      await _dbHelper.deleteCustomer(customerId);
      _customers.removeWhere((c) => c.customerId == customerId);
      _filteredCustomers.removeWhere((c) => c.customerId == customerId); // Update filtered list
      notifyListeners();
    } catch (e) {
      print('Error deleting customer: $e');
    }
  }

  // Search customers locally by first name, last name, or email
  void searchCustomers(String query) {
    if (query.isEmpty) {
      _filteredCustomers = List.from(_customers);
    } else {
      _filteredCustomers = _customers.where((customer) {
        final lowerCaseQuery = query.toLowerCase();
        return customer.firstName.toLowerCase().contains(lowerCaseQuery) ||
               customer.lastName.toLowerCase().contains(lowerCaseQuery) ||
               (customer.email.toLowerCase().contains(lowerCaseQuery));
      }).toList();
    }
    notifyListeners();
  }
}