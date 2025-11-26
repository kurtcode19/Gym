import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import 'package:gym/providers/trainer_provider.dart';
import 'package:gym/providers/class_provider.dart';
import 'package:gym/providers/expense_provider.dart';
import 'package:gym/models/expense.dart';

class TrainerPayoutScreen extends StatefulWidget {
  const TrainerPayoutScreen({super.key});

  @override
  State<TrainerPayoutScreen> createState() => _TrainerPayoutScreenState();
}

class _TrainerPayoutScreenState extends State<TrainerPayoutScreen> {
  String? _selectedTrainerId;
  DateTimeRange _dateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 30)),
    end: DateTime.now(),
  );

  @override
  Widget build(BuildContext context) {
    final trainerProvider = Provider.of<TrainerProvider>(context);
    final classProvider = Provider.of<ClassProvider>(context);
    
    // Calculation Logic
    int sessionCount = 0;
    double totalPay = 0.0;
    double rate = 0.0;

    if (_selectedTrainerId != null) {
      final trainer = trainerProvider.trainers.firstWhere((t) => t.trainerId == _selectedTrainerId);
      rate = trainer.ratePerSession;
      sessionCount = trainerProvider.getSessionCount(
        _selectedTrainerId!, 
        classProvider.classes, 
        _dateRange.start, 
        _dateRange.end
      );
      totalPay = sessionCount * rate;
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Trainer Payroll', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Date Filter
            Center(
              child: ActionChip(
                avatar: const Icon(Icons.calendar_today, size: 16),
                label: Text('${DateFormat('MMM d').format(_dateRange.start)} - ${DateFormat('MMM d').format(_dateRange.end)}'),
                onPressed: () async {
                  final picked = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                    initialDateRange: _dateRange,
                  );
                  if (picked != null) setState(() => _dateRange = picked);
                },
              ),
            ),
            const SizedBox(height: 20),

            // 2. Select Trainer
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Select Trainer',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
                prefixIcon: const Icon(Icons.person),
              ),
              value: _selectedTrainerId,
              items: trainerProvider.trainers.map((t) => DropdownMenuItem(
                value: t.trainerId,
                child: Text('${t.firstName} ${t.lastName}'),
              )).toList(),
              onChanged: (val) => setState(() => _selectedTrainerId = val),
            ),

            const SizedBox(height: 30),

            // 3. Summary Card
            if (_selectedTrainerId != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2193b0), Color(0xFF6dd5ed)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
                ),
                child: Column(
                  children: [
                    const Text("Total Payable", style: TextStyle(color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 8),
                    Text(
                      NumberFormat.currency(symbol: '₱').format(totalPay),
                      style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text("$sessionCount Classes", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 8),
                          const Text("×", style: TextStyle(color: Colors.white70)),
                          const SizedBox(width: 8),
                          Text(NumberFormat.currency(symbol: '₱').format(rate), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text("Select a trainer to calculate pay", style: TextStyle(color: Colors.grey)),
                ),
              ),

            const Spacer(),

            // 4. Pay Button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: (_selectedTrainerId == null || totalPay == 0) ? null : () {
                  _confirmPayout(context, totalPay, sessionCount);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  disabledBackgroundColor: Colors.grey[300],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text("Record Payout", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmPayout(BuildContext context, double amount, int sessions) {
    final trainer = Provider.of<TrainerProvider>(context, listen: false).trainers
        .firstWhere((t) => t.trainerId == _selectedTrainerId);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirm Payout"),
        content: Text("This will create an Expense record of ${NumberFormat.currency(symbol: '₱').format(amount)} for ${trainer.firstName}."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              // 1. Create Expense
              final newExpense = Expense(
                expenseId: const Uuid().v4(),
                category: 'Salaries',
                description: 'Payout: ${trainer.firstName} ($sessions classes)',
                amount: amount,
                expenseDate: DateTime.now(),
              );

              // 2. Save
              await Provider.of<ExpenseProvider>(context, listen: false).addExpense(newExpense);
              
              if (mounted) {
                Navigator.pop(ctx); // Close dialog
                Navigator.pop(context); // Go back
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Payout recorded successfully!")),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text("Confirm & Save", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }
}