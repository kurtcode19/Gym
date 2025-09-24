// lib/screens/expenses_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gym/providers/expense_provider.dart'; // Corrected import
import 'package:gym/models/expense.dart'; // Corrected import
import 'package:gym/screens/add_expense_screen.dart'; // Corrected import
import 'package:intl/intl.dart';

class ExpensesScreen extends StatelessWidget {
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search expenses...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (query) {
                Provider.of<ExpenseProvider>(context, listen: false).searchExpenses(query);
              },
            ),
          ),
          Expanded(
            child: Consumer<ExpenseProvider>(
              builder: (context, expenseProvider, child) {
                if (expenseProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (expenseProvider.expenses.isEmpty) {
                  return const Center(child: Text('No expenses recorded.'));
                } else {
                  return ListView.builder(
                    itemCount: expenseProvider.expenses.length,
                    itemBuilder: (context, index) {
                      final expense = expenseProvider.expenses[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context).colorScheme.error, // Red for expenses
                            child: Text(
                              expense.category[0].toUpperCase(),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(expense.category),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(expense.description ?? 'No description'),
                              Text('Date: ${DateFormat('MMM d, yyyy').format(expense.expenseDate)}'),
                            ],
                          ),
                          isThreeLine: true,
                          trailing: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                NumberFormat.currency(symbol: '\$').format(expense.amount),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                                onPressed: () {
                                  _confirmDelete(context, expenseProvider, expense);
                                },
                              ),
                            ],
                          ),
                          onTap: () {
                            // Navigate to edit screen
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddExpenseScreen(expense: expense),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddExpenseScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _confirmDelete(BuildContext context, ExpenseProvider expenseProvider, Expense expense) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Expense'),
          content: Text('Are you sure you want to delete this expense for "${expense.category}" (${NumberFormat.currency(symbol: '\$').format(expense.amount)})?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () {
                expenseProvider.deleteExpense(expense.expenseId);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Expense deleted.')),
                );
              },
            ),
          ],
        );
      },
    );
  }
}