// lib/providers/expense_provider.dart
import 'package:flutter/material.dart';
import 'package:gym/models/expense.dart'; // Corrected import
import 'package:gym/providers/database_helper.dart'; // Corrected import
import 'package:intl/intl.dart';

class ExpenseProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper;
  List<Expense> _expenses = [];
  List<Expense> _filteredExpenses = [];
  bool _isLoading = false;

  ExpenseProvider(this._dbHelper) {
    fetchExpenses();
  }

  List<Expense> get expenses => _filteredExpenses;
  bool get isLoading => _isLoading;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> fetchExpenses() async {
    _setLoading(true);
    try {
      final expenseMaps = await _dbHelper.getExpenses();
      _expenses = expenseMaps.map((map) => Expense.fromJson(map)).toList();
      _filteredExpenses = List.from(_expenses);
    } catch (e) {
      print('Error fetching expenses: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addExpense(Expense expense) async {
    try {
      await _dbHelper.insertExpense(expense.toJson());
      _expenses.add(expense);
      _filteredExpenses = List.from(_expenses);
      notifyListeners();
    } catch (e) {
      print('Error adding expense: $e');
    }
  }

  Future<void> updateExpense(Expense expense) async {
    try {
      await _dbHelper.updateExpense(expense.toJson());
      final index = _expenses.indexWhere((e) => e.expenseId == expense.expenseId);
      if (index != -1) {
        _expenses[index] = expense;
        _filteredExpenses = List.from(_expenses);
        notifyListeners();
      }
    } catch (e) {
      print('Error updating expense: $e');
    }
  }

  Future<void> deleteExpense(String expenseId) async {
    try {
      await _dbHelper.deleteExpense(expenseId);
      _expenses.removeWhere((e) => e.expenseId == expenseId);
      _filteredExpenses.removeWhere((e) => e.expenseId == expenseId);
      notifyListeners();
    } catch (e) {
      print('Error deleting expense: $e');
    }
  }

  void searchExpenses(String query) {
    if (query.isEmpty) {
      _filteredExpenses = List.from(_expenses);
    } else {
      _filteredExpenses = _expenses.where((expense) {
        final lowerCaseQuery = query.toLowerCase();
        return expense.category.toLowerCase().contains(lowerCaseQuery) ||
               (expense.description?.toLowerCase().contains(lowerCaseQuery) ?? false) ||
               DateFormat('yyyy-MM-dd').format(expense.expenseDate).contains(lowerCaseQuery);
      }).toList();
    }
    notifyListeners();
  }
}