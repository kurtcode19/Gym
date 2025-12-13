// lib/screens/add_expense_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:provider/provider.dart';
import 'package:gym/models/expense.dart';
import 'package:gym/providers/expense_provider.dart';
import 'package:intl/intl.dart';

class AddExpenseScreen extends StatefulWidget {
  final Expense? expense;

  const AddExpenseScreen({super.key, this.expense});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormBuilderState>();

  InputDecoration _fieldDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.redAccent),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.expense != null;

    final initialValues = isEditing
        ? {
            'category': widget.expense!.category,
            'description': widget.expense!.description,
            'amount': widget.expense!.amount.toString(),
            'expense_date': widget.expense!.expenseDate,
          }
        : {
            'amount': '',
            'expense_date': DateTime.now(),
          };

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),

      // ------------------------------- PREMIUM APP BAR -------------------------------
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 8,
        shadowColor: Colors.black.withOpacity(.12),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(
          isEditing ? "Edit Expense" : "Record Expense",
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: FormBuilder(
          key: _formKey,
          initialValue: initialValues,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionHeader("Classification"),

              // ---------------------------- CLASSIFICATION CARD ----------------------------
              Card(
                elevation: 3,
                shadowColor: Colors.black.withOpacity(.05),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      FormBuilderDropdown<String>(
                        name: 'category',
                        decoration: _fieldDecoration('Category', Icons.category),
                        items: const [
                          DropdownMenuItem(value: 'Rent', child: Text('Rent')),
                          DropdownMenuItem(
                              value: 'Utilities', child: Text('Utilities')),
                          DropdownMenuItem(
                              value: 'Salaries', child: Text('Salaries')),
                          DropdownMenuItem(
                              value: 'Maintenance', child: Text('Maintenance')),
                          DropdownMenuItem(
                              value: 'Supplies', child: Text('Supplies')),
                          DropdownMenuItem(
                              value: 'Marketing', child: Text('Marketing')),
                          DropdownMenuItem(value: 'Other', child: Text('Other')),
                        ],
                        validator: (v) =>
                            v == null || v.isEmpty ? "Required" : null,
                      ),

                      const SizedBox(height: 16),

                      FormBuilderTextField(
                        name: 'description',
                        maxLines: 2,
                        decoration: _fieldDecoration(
                            'Description (Optional)', Icons.description),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 28),
              _sectionHeader("Cost & Date"),

              // --------------------------- COST & DATE CARD ---------------------------
              Card(
                elevation: 3,
                shadowColor: Colors.black.withOpacity(.05),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      FormBuilderTextField(
                        name: 'amount',
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: _fieldDecoration('Amount', Icons.attach_money),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Required';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Invalid amount';
                          }
                          if (double.parse(value) <= 0) {
                            return 'Must be positive';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      FormBuilderDateTimePicker(
                        name: 'expense_date',
                        decoration:
                            _fieldDecoration('Date', Icons.calendar_today),
                        inputType: InputType.date,
                        format: DateFormat('yyyy-MM-dd'),
                        validator: (v) => v == null ? "Required" : null,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // ------------------------------ SUBMIT BUTTON ------------------------------
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState?.saveAndValidate() ?? false) {
                      final data = _formKey.currentState!.value;

                      final newExpense = Expense(
                        expenseId: isEditing ? widget.expense!.expenseId : null,
                        category: data['category'],
                        description: data['description'],
                        amount: double.parse(data['amount']),
                        expenseDate: data['expense_date'],
                      );

                      try {
                        final provider = Provider.of<ExpenseProvider>(context,
                            listen: false);

                        if (isEditing) {
                          await provider.updateExpense(newExpense);
                          _showSnackBar("Expense updated successfully!");
                        } else {
                          await provider.addExpense(newExpense);
                          _showSnackBar("Expense added successfully!");
                        }

                        if (context.mounted) Navigator.pop(context);
                      } catch (e) {
                        _showSnackBar("Error: $e", isError: true);
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(
                    isEditing ? "Save Changes" : "Record Expense",
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------- SECTION HEADER ----------------------------
  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: Colors.redAccent,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------- SNACKBAR ----------------------------
  void _showSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
