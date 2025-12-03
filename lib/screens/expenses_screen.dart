import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:gym/providers/expense_provider.dart';
import 'package:gym/models/expense.dart';
import 'package:gym/screens/add_expense_screen.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  bool _filtersExpanded = false;
  String _quickFilter = "All";
  DateTimeRange? _selectedRange;

  // --------------------------------------------------------------------
  // FILTER LOGIC
  // --------------------------------------------------------------------
  void _applyQuickFilter(String label) {
    final now = DateTime.now();
    late DateTime start;
    late DateTime end;

    if (label == "All") {
      setState(() {
        _quickFilter = "All";
        _selectedRange = null;
      });
      return;
    }

    if (label == "Today") {
      start = DateTime(now.year, now.month, now.day);
      end = start.add(const Duration(hours: 23, minutes: 59));
    } else if (label == "This Week") {
      start =
          DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
      end = start.add(const Duration(days: 6, hours: 23, minutes: 59));
    } else {
      start = DateTime(now.year, now.month, 1);
      end = DateTime(now.year, now.month + 1, 1).subtract(const Duration(seconds: 1));
    }

    setState(() {
      _quickFilter = label;
      _selectedRange = DateTimeRange(start: start, end: end);
    });
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 3),
      lastDate: DateTime(now.year + 3),
      initialDateRange: _selectedRange ??
          DateTimeRange(start: DateTime(now.year, now.month, 1), end: now),
    );

    if (picked != null) {
      setState(() {
        _selectedRange = picked;
        _quickFilter = "Custom";
      });
    }
  }

  bool _matchesFilters(Expense e) {
    if (_selectedRange != null) {
      if (e.expenseDate.isBefore(_selectedRange!.start) ||
          e.expenseDate.isAfter(_selectedRange!.end)) {
        return false;
      }
    }
    return true;
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Rent':
        return Icons.store_mall_directory;
      case 'Utilities':
        return Icons.electrical_services;
      case 'Salaries':
        return Icons.people_alt;
      case 'Maintenance':
        return Icons.build;
      case 'Supplies':
        return Icons.cleaning_services;
      case 'Marketing':
        return Icons.campaign;
      default:
        return Icons.receipt_long;
    }
  }

Widget _inlineFilter({
  required IconData icon,
  required String label,
  required String value,
  required VoidCallback onTap,
}) {
  return InkWell(
    onTap: onTap,
    child: Container(
      width: double.infinity, // 🔥 Prevents horizontal overflow
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 10),

          // Label
          Text(
            "$label:",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 6),

          // 🔥 This prevents overflow & makes it wrap or fade safely
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis, // <-- NO MORE OVERFLOW
              style: const TextStyle(fontSize: 14),
            ),
          ),

          const SizedBox(width: 6),
          const Icon(Icons.chevron_right, size: 16),
        ],
      ),
    ),
  );
}


  Widget _chip(String label) {
    final active = _quickFilter == label;
    return ChoiceChip(
      selected: active,
      label: Text(
        label,
        style: TextStyle(
          color: active ? Colors.white : Colors.black87,
          fontWeight: FontWeight.w600,
        ),
      ),
      selectedColor: Colors.redAccent,
      onSelected: (_) => _applyQuickFilter(label),
    );
  }

  void _confirmDelete(BuildContext ctx, ExpenseProvider provider, Expense e) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text("Delete Expense?"),
        content: Text("Remove ${e.category} • ₱${e.amount}?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              provider.deleteExpense(e.expenseId);
              Navigator.pop(ctx);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ====================================================================
  // UI
  // ====================================================================
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.grey[100],

      // ⭐ PREMIUM APP BAR
      appBar: AppBar(
        title: const Text(
          "Expenses",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 2,
        shadowColor: Colors.black26,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),

      body: Consumer<ExpenseProvider>(
        builder: (context, provider, _) {
          final filtered = provider.expenses.where(_matchesFilters).toList();
          final totalAmount =
              filtered.fold(0.0, (sum, e) => sum + e.amount);

          return Column(
            children: [
              // ⭐ PREMIUM FILTER / SEARCH HEADER
              // ⭐ PREMIUM COMPACT SEARCH + FILTER HEADER
Container(
  padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
  decoration: BoxDecoration(
    color: theme.primaryColor.withOpacity(.08),
    borderRadius: const BorderRadius.only(
      bottomLeft: Radius.circular(22),
      bottomRight: Radius.circular(22),
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(.04),
        blurRadius: 6,
        offset: const Offset(0, 3),
      )
    ],
  ),
  child: Column(
    children: [
      // -------------------------------------------------------
      // SEARCH BAR + FILTER TOGGLE INLINE
      // -------------------------------------------------------
      Row(
        children: [
          // SEARCH FIELD
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search expenses...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: provider.searchExpenses,
            ),
          ),

          const SizedBox(width: 10),

          // FILTER TOGGLE BUTTON (NOW INLINE)
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () =>
                setState(() => _filtersExpanded = !_filtersExpanded),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(.06),
                    blurRadius: 6,
                  )
                ],
              ),
              child: Icon(
                _filtersExpanded ? Icons.filter_list_off : Icons.filter_list,
                color: theme.primaryColor,
                size: 24,
              ),
            ),
          ),
        ],
      ),

      // -------------------------------------------------------
      // COLLAPSIBLE FILTER PANEL — COMPACT + PREMIUM
      // -------------------------------------------------------
AnimatedCrossFade(
  duration: const Duration(milliseconds: 220),
  firstChild: const SizedBox.shrink(),
  secondChild: Column(
    children: [
      Wrap(
        spacing: 6,
        children: [
          _chip("All"),
          _chip("Today"),
          _chip("This Week"),
          _chip("This Month"),
        ],
      ),
      const SizedBox(height: 12),
      _inlineFilter(
        icon: Icons.date_range,
        label: "Date Range",
        value: _selectedRange == null
            ? "Any"
            : "${DateFormat('MMM d').format(_selectedRange!.start)} – ${DateFormat('MMM d').format(_selectedRange!.end)}",
        onTap: _pickRange,
      ),
    ],
  ),
  crossFadeState: _filtersExpanded
      ? CrossFadeState.showSecond
      : CrossFadeState.showFirst,
),

    ],
  ),
),


              const SizedBox(height: 12),

              // ⭐ TOTAL CARD
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(.06),
                          blurRadius: 6,
                          offset: const Offset(0, 3))
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Total Expenses",
                          style:
                              TextStyle(fontSize: 13, color: Colors.grey[700])),
                      const SizedBox(height: 6),
                      Text(
                        NumberFormat.currency(locale: "en_PH", symbol: "₱")
                            .format(totalAmount),
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.redAccent,
                        ),
                      )
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ⭐ EXPENSE LIST
              Expanded(
                child: provider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : filtered.isEmpty
                        ? const Center(
                            child: Text("No matching expenses",
                                style: TextStyle(
                                    fontSize: 15, color: Colors.grey)),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 8),
                            itemCount: filtered.length,
                            itemBuilder: (_, i) {
                              final e = filtered[i];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: [
                                    BoxShadow(
                                        color: Colors.black.withOpacity(.05),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3))
                                  ],
                                ),
                                child: ListTile(
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            AddExpenseScreen(expense: e)),
                                  ),
                                  leading: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      _getCategoryIcon(e.category),
                                      color: Colors.redAccent,
                                    ),
                                  ),
                                  title: Text(
                                    e.category,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16),
                                  ),
                                  subtitle: Text(
                                      DateFormat("MMM d, yyyy")
                                          .format(e.expenseDate),
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[600])),
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        NumberFormat.currency(
                                                locale: "en_PH",
                                                symbol: "₱")
                                            .format(e.amount),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.redAccent,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      GestureDetector(
                                        onTap: () =>
                                            _confirmDelete(context, provider, e),
                                        child: Icon(Icons.delete_outline,
                                            size: 20,
                                            color: Colors.grey[400]),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          );
        },
      ),

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.redAccent,
        icon: const Icon(Icons.add),
        label: const Text("Record Expense"),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
        ),
      ),
    );
  }
}
