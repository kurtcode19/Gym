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
      prefixIcon: Icon(icon, color: Colors.blueGrey),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      filled: true,
      fillColor: Colors.grey.shade50,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.expense != null;

    Map<String, dynamic> initialValues = {};
    if (isEditing) {
      initialValues = {
        'category': widget.expense!.category,
        'description': widget.expense!.description,
        'amount': widget.expense!.amount.toString(),
        'expense_date': widget.expense!.expenseDate,
      };
    } else {
      initialValues = {
        'amount': '',
        'expense_date': DateTime.now(),
      };
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Expense' : 'Record Expense'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: FormBuilder(
            key: _formKey,
            initialValue: initialValues,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('Classification'),
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.grey.shade200)),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        FormBuilderDropdown<String>(
                          name: 'category',
                          decoration: _fieldDecoration('Category', Icons.category),
                          validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                          items: const [
                            DropdownMenuItem(value: 'Rent', child: Text('Rent')),
                            DropdownMenuItem(value: 'Utilities', child: Text('Utilities')),
                            DropdownMenuItem(value: 'Salaries', child: Text('Salaries')),
                            DropdownMenuItem(value: 'Maintenance', child: Text('Maintenance')),
                            DropdownMenuItem(value: 'Supplies', child: Text('Supplies')),
                            DropdownMenuItem(value: 'Marketing', child: Text('Marketing')),
                            DropdownMenuItem(value: 'Other', child: Text('Other')),
                          ],
                        ),
                        const SizedBox(height: 16),
                        FormBuilderTextField(
                          name: 'description',
                          decoration: _fieldDecoration('Description (Optional)', Icons.description),
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                _buildSectionHeader('Cost & Date'),

                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.grey.shade200)),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        FormBuilderTextField(
                          name: 'amount',
                          decoration: _fieldDecoration('Amount', Icons.attach_money),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Required';
                            if (double.tryParse(value) == null) return 'Invalid number';
                            if (double.parse(value) <= 0) return 'Must be positive';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        FormBuilderDateTimePicker(
                          name: 'expense_date',
                          decoration: _fieldDecoration('Date', Icons.calendar_today),
                          inputType: InputType.date,
                          format: DateFormat('yyyy-MM-dd'),
                          validator: (value) => value == null ? 'Required' : null,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  height: 55,
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
                          if (isEditing) {
                            await Provider.of<ExpenseProvider>(context, listen: false).updateExpense(newExpense);
                            if (context.mounted) _showSnackBar('Expense updated successfully!');
                          } else {
                            await Provider.of<ExpenseProvider>(context, listen: false).addExpense(newExpense);
                            if (context.mounted) _showSnackBar('Expense added successfully!');
                          }
                          if (context.mounted) Navigator.of(context).pop();
                        } catch (e) {
                          if (context.mounted) _showSnackBar('Error: $e', isError: true);
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent, // Red for expenses
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 2,
                    ),
                    child: Text(
                      isEditing ? 'Save Changes' : 'Record Expense',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.grey[700],
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}