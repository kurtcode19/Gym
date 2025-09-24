// lib/screens/add_expense_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:provider/provider.dart';
import 'package:gym/models/expense.dart'; // Corrected import
import 'package:gym/providers/expense_provider.dart'; // Corrected import
import 'package:intl/intl.dart';

class AddExpenseScreen extends StatefulWidget {
  final Expense? expense; // Optional: for editing existing expense

  const AddExpenseScreen({super.key, this.expense});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormBuilderState>();

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
        'amount': '0.00',
        'expense_date': DateTime.now(),
      };
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Expense' : 'Add New Expense'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FormBuilder(
          key: _formKey,
          initialValue: initialValues,
          child: ListView(
            children: [
              FormBuilderDropdown<String>(
                name: 'category',
                decoration: const InputDecoration(labelText: 'Category'),
                validator: (value) => value == null || value.isEmpty ? 'Category cannot be empty' : null,
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
                decoration: const InputDecoration(labelText: 'Description (Optional)'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              FormBuilderTextField(
                name: 'amount',
                decoration: const InputDecoration(labelText: 'Amount (\$)', hintText: 'e.g., 100.00'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Amount cannot be empty';
                  if (double.tryParse(value) == null) return 'Invalid number';
                  if (double.parse(value) <= 0) return 'Amount must be positive';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              FormBuilderDateTimePicker(
                name: 'expense_date',
                decoration: const InputDecoration(labelText: 'Expense Date'),
                inputType: InputType.date,
                format: DateFormat('yyyy-MM-dd'),
                validator: (value) => value == null ? 'Expense date cannot be empty' : null,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
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

                    if (isEditing) {
                      await Provider.of<ExpenseProvider>(context, listen: false).updateExpense(newExpense);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Expense updated successfully!')),
                      );
                    } else {
                      await Provider.of<ExpenseProvider>(context, listen: false).addExpense(newExpense);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Expense added successfully!')),
                      );
                    }
                    Navigator.of(context).pop();
                  }
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
                child: Text(isEditing ? 'Update Expense' : 'Add Expense'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}