import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import 'package:gym/providers/trainer_provider.dart';
import 'package:gym/providers/class_provider.dart';
import 'package:gym/providers/pt_provider.dart';
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
    final theme = Theme.of(context);
    final trainerProvider = Provider.of<TrainerProvider>(context);
    final ptProvider = Provider.of<PTProvider>(context);

    // ----------- PAYROLL CALCULATION LOGIC -----------
    int sessionCount = 0;
    double totalPay = 0.0;
    double rate = 0.0;

    if (_selectedTrainerId != null) {
      final trainer = trainerProvider.trainers.firstWhere(
        (t) => t.trainerId == _selectedTrainerId,
      );

      rate = trainer.ratePerSession;

      sessionCount = ptProvider.countEligibleSessions(
        _selectedTrainerId!,
        _dateRange.start,
        _dateRange.end,
      );

      totalPay = sessionCount * rate;
    }

    // ------------------------------------------------------
    // UI LAYOUT
    // ------------------------------------------------------
    return Scaffold(
      backgroundColor: Colors.grey[100],

      // ⭐ PREMIUM APP BAR
      appBar: AppBar(
        title: const Text(
          "Trainer Payroll",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 3,
        shadowColor: Colors.black26,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),

      body: Column(
        children: [
          // ⭐ PREMIUM HEADER (Date range chip)
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            decoration: BoxDecoration(
              color: theme.primaryColor.withOpacity(.08),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(22),
                bottomRight: Radius.circular(22),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(.05),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                )
              ],
            ),
            child: Center(
              child: InkWell(
                borderRadius: BorderRadius.circular(30),
                onTap: _selectRange,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.grey.shade300),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(.05),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.calendar_month,
                          color: theme.primaryColor, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        "${DateFormat('MMM d').format(_dateRange.start)} - "
                        "${DateFormat('MMM d').format(_dateRange.end)}",
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // BODY CONTENT
          Expanded(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ⭐ TRAINER SELECTION
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: "Select Trainer",
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14)),
                      filled: true,
                      fillColor: Colors.white,
                      prefixIcon: const Icon(Icons.person),
                    ),
                    value: _selectedTrainerId,
                    items: trainerProvider.trainers
                        .map(
                          (t) => DropdownMenuItem(
                            value: t.trainerId,
                            child:
                                Text("${t.firstName} ${t.lastName}"),
                          ),
                        )
                        .toList(),
                    onChanged: (val) =>
                        setState(() => _selectedTrainerId = val),
                  ),

                  const SizedBox(height: 25),

                  // ⭐ PAY SUMMARY OR EMPTY MESSAGE
                  if (_selectedTrainerId == null)
                    _emptyMessage()
                  else
                    _paySummaryCard(totalPay, sessionCount, rate),

                  const SizedBox(height: 70),
                ],
              ),
            ),
          ),
        ],
      ),

      // ⭐ FAB PAYOUT BUTTON
      floatingActionButtonLocation:
          FloatingActionButtonLocation.centerFloat,
      floatingActionButton: SizedBox(
        width: MediaQuery.of(context).size.width * 0.92,
        height: 55,
        child: ElevatedButton(
          onPressed: (_selectedTrainerId == null || totalPay == 0)
              ? null
              : () => _confirmPayout(context, totalPay, sessionCount),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            disabledBackgroundColor: Colors.grey.shade300,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            elevation: 4,
          ),
          child: const Text(
            "Record Payout",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ⭐ When no trainer selected
  Widget _emptyMessage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          "Select a trainer to calculate pay",
          style: TextStyle(color: Colors.grey.shade600),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ⭐ Premium Summary Card
  Widget _paySummaryCard(double totalPay, int sessionCount, double rate) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2193b0), Color(0xFF6dd5ed)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(.25),
            blurRadius: 12,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Column(
        children: [
          const Text(
            "Total Payable",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            NumberFormat.currency(symbol: "₱").format(totalPay),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 38,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "$sessionCount PT Sessions",
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 10),
                const Text("×",
                    style: TextStyle(color: Colors.white70)),
                const SizedBox(width: 10),
                Text(
                  NumberFormat.currency(symbol: "₱").format(rate),
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ⭐ DATE PICKER
  void _selectRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: _dateRange,
    );

    if (picked != null) {
      setState(() => _dateRange = picked);
    }
  }

  // ---------------------------------------------------------------------------
  // ⭐ CONFIRM PAYOUT DIALOG
  void _confirmPayout(
      BuildContext context, double amount, int sessions) async {
    final trainer =
        Provider.of<TrainerProvider>(context, listen: false)
            .trainers
            .firstWhere((t) => t.trainerId == _selectedTrainerId);

    final ptProvider = Provider.of<PTProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirm Payout"),
        content: Text(
          "This will record ₱${amount.toStringAsFixed(2)} for "
          "${trainer.firstName} ($sessions PT sessions).",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () async {
              // Create Expense
              final newExpense = Expense(
                expenseId: const Uuid().v4(),
                category: "Salaries",
                description:
                    "PT Payout: ${trainer.firstName} ($sessions sessions)",
                amount: amount,
                expenseDate: DateTime.now(),
              );

              await Provider.of<ExpenseProvider>(context, listen: false)
                  .addExpense(newExpense);

              // Mark PT sessions as paid
              await ptProvider.markSessionsAsTrainerPaid(
                _selectedTrainerId!,
                _dateRange.start,
                _dateRange.end,
              );

              if (mounted) {
                Navigator.pop(ctx);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Payout recorded successfully!")),
                );
              }
            },
            child:
                const Text("Confirm & Save", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
