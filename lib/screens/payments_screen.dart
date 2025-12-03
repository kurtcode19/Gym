// lib/screens/payments_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gym/providers/payment_provider.dart';
import 'package:gym/models/payment.dart';
import 'package:gym/screens/add_payment_screen.dart';
import 'package:intl/intl.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  // FILTER PANEL STATE ---------------------------------------------------------
  bool _filtersExpanded = false;
  String _quickFilter = "All";

  DateTimeRange? _dateRange;
  String? _paymentMethod;
  String? _paymentStatus;

  // QUICK FILTER LOGIC ---------------------------------------------------------
  void _applyQuickFilter(String filter) {
    final now = DateTime.now();
    DateTime start;
    DateTime end;

    setState(() {
      _quickFilter = filter;

      if (filter == "All") {
        _dateRange = null;
        return;
      }

      if (filter == "Today") {
        start = DateTime(now.year, now.month, now.day);
        end = start.add(const Duration(hours: 23, minutes: 59));
      } else if (filter == "This Week") {
        start = DateTime(now.year, now.month, now.day)
            .subtract(Duration(days: now.weekday - 1));
        end = start.add(const Duration(days: 6, hours: 23, minutes: 59));
      } else {
        // This Month
        start = DateTime(now.year, now.month, 1);
        end = DateTime(now.year, now.month + 1, 1)
            .subtract(const Duration(seconds: 1));
      }

      _dateRange = DateTimeRange(start: start, end: end);
    });
  }

  // PICK DATE RANGE ------------------------------------------------------------
  Future<void> _pickDateRange() async {
    final now = DateTime.now();

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
      initialDateRange: _dateRange ??
          DateTimeRange(start: now.subtract(const Duration(days: 30)), end: now),
    );

    if (picked != null) {
      setState(() {
        _dateRange = picked;
        _quickFilter = "Custom";
      });
    }
  }

Future<void> _pickMethod() async {
  final method = await showDialog<String>(
    context: context,
    builder: (dialogContext) => SimpleDialog(
      title: const Text("Payment Method"),
      children: [
        SimpleDialogOption(
          onPressed: () => Navigator.pop(dialogContext, null),
          child: const Text("Any"),
        ),
        SimpleDialogOption(
          onPressed: () => Navigator.pop(dialogContext, "Cash"),
          child: const Text("Cash"),
        ),
        SimpleDialogOption(
          onPressed: () => Navigator.pop(dialogContext, "Credit Card"),
          child: const Text("Credit Card"),
        ),
        SimpleDialogOption(
          onPressed: () => Navigator.pop(dialogContext, "Debit Card"),
          child: const Text("Debit Card"),
        ),
        SimpleDialogOption(
          onPressed: () => Navigator.pop(dialogContext, "Bank Transfer"),
          child: const Text("Bank Transfer"),
        ),
        SimpleDialogOption(
          onPressed: () => Navigator.pop(dialogContext, "Check"),
          child: const Text("Check"),
        ),
      ],
    ),
  );

  setState(() {
    _paymentMethod = method;
    _quickFilter = "Custom";
  });
}

Future<void> _pickStatus() async {
  final status = await showDialog<String>(
    context: context,
    builder: (dialogContext) => SimpleDialog(
      title: const Text("Payment Status"),
      children: [
        SimpleDialogOption(
          onPressed: () => Navigator.pop(dialogContext, null),
          child: const Text("Any"),
        ),
        SimpleDialogOption(
          onPressed: () => Navigator.pop(dialogContext, "Completed"),
          child: const Text("Completed"),
        ),
        SimpleDialogOption(
          onPressed: () => Navigator.pop(dialogContext, "Pending"),
          child: const Text("Pending"),
        ),
        SimpleDialogOption(
          onPressed: () => Navigator.pop(dialogContext, "Failed"),
          child: const Text("Failed"),
        ),
        SimpleDialogOption(
          onPressed: () => Navigator.pop(dialogContext, "Refunded"),
          child: const Text("Refunded"),
        ),
      ],
    ),
  );

  setState(() {
    _paymentStatus = status;
    _quickFilter = "Custom";
  });
}


  // MATCH FILTERS --------------------------------------------------------------
  bool _matchesFilters(DetailedPayment dp) {
    final p = dp.payment;

    // DATE RANGE
    if (_dateRange != null) {
      if (p.paymentDate.isBefore(_dateRange!.start) ||
          p.paymentDate.isAfter(_dateRange!.end)) return false;
    }

    // METHOD
    if (_paymentMethod != null && p.method != _paymentMethod) return false;

    // STATUS
    if (_paymentStatus != null &&
        p.status.toLowerCase() != _paymentStatus!.toLowerCase()) return false;

    return true;
  }

  // QUICK CHIP -----------------------------------------------------------------
  Widget _chip(String label) {
    final active = _quickFilter == label;
    return ChoiceChip(
      label: Text(label, style: TextStyle(color: active ? Colors.white : Colors.black)),
      selected: active,
      selectedColor: Colors.blue,
      onSelected: (_) => _applyQuickFilter(label),
    );
  }

  // INLINE FILTER BUTTON --------------------------------------------------------
  Widget _filterButton({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 8),
            Text("$label: ", style: const TextStyle(fontWeight: FontWeight.bold)),
            Expanded(child: Text(value)),
            const Icon(Icons.chevron_right, size: 16),
          ],
        ),
      ),
    );
  }

  // COLOR AND ICON HELPERS -----------------------------------------------------
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed': return Colors.green;
      case 'failed': return Colors.red;
      case 'refunded': return Colors.orange;
      case 'pending': return Colors.blue;
      default: return Colors.grey;
    }
  }

  IconData _getMethodIcon(String? method) {
    switch (method?.toLowerCase()) {
      case 'cash': return Icons.payments_outlined;
      case 'credit card': return Icons.credit_card;
      case 'debit card': return Icons.credit_card_outlined;
      case 'bank transfer': return Icons.account_balance;
      case 'check': return Icons.fact_check_outlined;
      default: return Icons.attach_money;
    }
  }

  // MAIN BUILD -----------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
   appBar: AppBar(
  title: const Text(
    "Payments History",
    style: TextStyle(
      fontWeight: FontWeight.bold,
      color: Colors.black87,
    ),
  ),
  centerTitle: true,
  backgroundColor: Colors.white,
  elevation: 4,
  shadowColor: Colors.black26,
  surfaceTintColor: Colors.transparent,
  iconTheme: const IconThemeData(color: Colors.black87),
),


      body: Consumer<PaymentProvider>(
        builder: (_, provider, __) {
          final filtered = provider.payments.where(_matchesFilters).toList();

          return Column(
            children: [
              // SEARCH + FILTER HEADER ----------------------------------------
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(.08),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(18),
                    bottomRight: Radius.circular(18),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // SEARCH FIELD
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: "Search payments...",
                              prefixIcon: const Icon(Icons.search),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            onChanged: provider.searchPayments,
                          ),
                        ),
                        const SizedBox(width: 10),

                        // FILTER BUTTON
                        InkWell(
                          onTap: () =>
                              setState(() => _filtersExpanded = !_filtersExpanded),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(
                                color: _filtersExpanded
                                    ? Colors.blue
                                    : Colors.grey.shade300,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _filtersExpanded
                                  ? Icons.filter_list_off
                                  : Icons.filter_list,
                              color: _filtersExpanded ? Colors.blue : Colors.black87,
                              size: 22,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // COLLAPSIBLE FILTER AREA --------------------------------
                    if (_filtersExpanded) ...[
                      const SizedBox(height: 16),

                      Wrap(
                        spacing: 6,
                        children: [
                          _chip("All"),
                          _chip("Today"),
                          _chip("This Week"),
                          _chip("This Month"),
                        ],
                      ),

                      const SizedBox(height: 16),

                      _filterButton(
                        icon: Icons.date_range,
                        label: "Date",
                        value: _dateRange == null
                            ? "Any"
                            : "${DateFormat('MMM d').format(_dateRange!.start)} - ${DateFormat('MMM d').format(_dateRange!.end)}",
                        onTap: _pickDateRange,
                      ),

                      const SizedBox(height: 8),

                      _filterButton(
                        icon: Icons.payment,
                        label: "Method",
                        value: _paymentMethod ?? "Any",
                        onTap: _pickMethod,
                      ),

                      const SizedBox(height: 8),

                      _filterButton(
                        icon: Icons.flag,
                        label: "Status",
                        value: _paymentStatus ?? "Any",
                        onTap: _pickStatus,
                      ),
                    ]
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // LIST ---------------------------------------------------------
              Expanded(
                child: provider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : filtered.isEmpty
                        ? const Center(child: Text("No matching payments"))
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filtered.length,
                            itemBuilder: (context, i) {
                              final dp = filtered[i];
                              final p = dp.payment;

                              return _paymentTile(context, provider, dp);
                            },
                          ),
              ),
            ],
          );
        },
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddPaymentScreen()),
        ),
        label: const Text("Receive Payment"),
        icon: const Icon(Icons.add),
      ),
    );
  }

  // PAYMENT TILE ---------------------------------------------------------------
  Widget _paymentTile(
      BuildContext context, PaymentProvider provider, DetailedPayment dp) {
    final p = dp.payment;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(.08),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: ListTile(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AddPaymentScreen(payment: p)),
        ),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _getStatusColor(p.status).withOpacity(.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            _getMethodIcon(p.method),
            color: _getStatusColor(p.status),
            size: 24,
          ),
        ),
        title: Text(
          "${dp.customerFirstName} ${dp.customerLastName}",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          DateFormat('MMM d, yyyy • h:mm a').format(p.paymentDate),
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
        trailing: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              "₱${p.amount.toStringAsFixed(2)}",
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.green),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: _getStatusColor(p.status).withOpacity(.12),
              ),
              child: Text(
                p.status,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                  color: _getStatusColor(p.status),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
