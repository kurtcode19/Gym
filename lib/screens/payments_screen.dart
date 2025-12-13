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
  bool _filtersExpanded = false;
  String _quickFilter = "All";

  DateTimeRange? _dateRange;
  String? _paymentMethod;
  String? _paymentStatus;

  // ---------------------------------------------------------------------------
  // QUICK FILTER LOGIC (unchanged)
  // ---------------------------------------------------------------------------
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
        start = DateTime(now.year, now.month, 1);
        end = DateTime(now.year, now.month + 1, 1)
            .subtract(const Duration(seconds: 1));
      }

      _dateRange = DateTimeRange(start: start, end: end);
    });
  }

  // ---------------------------------------------------------------------------
  // DATE, METHOD & STATUS PICKERS (unchanged logic)
  // ---------------------------------------------------------------------------
  Future<void> _pickDateRange() async {
    final now = DateTime.now();

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
      initialDateRange: _dateRange ??
          DateTimeRange(
              start: now.subtract(const Duration(days: 30)), end: now),
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
          SimpleDialogOption(onPressed: () => Navigator.pop(dialogContext, null), child: const Text("Any")),
          SimpleDialogOption(onPressed: () => Navigator.pop(dialogContext, "Cash"), child: const Text("Cash")),
          SimpleDialogOption(onPressed: () => Navigator.pop(dialogContext, "Credit Card"), child: const Text("Credit Card")),
          SimpleDialogOption(onPressed: () => Navigator.pop(dialogContext, "Debit Card"), child: const Text("Debit Card")),
          SimpleDialogOption(onPressed: () => Navigator.pop(dialogContext, "Bank Transfer"), child: const Text("Bank Transfer")),
          SimpleDialogOption(onPressed: () => Navigator.pop(dialogContext, "Check"), child: const Text("Check")),
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
          SimpleDialogOption(onPressed: () => Navigator.pop(dialogContext, null), child: const Text("Any")),
          SimpleDialogOption(onPressed: () => Navigator.pop(dialogContext, "Completed"), child: const Text("Completed")),
          SimpleDialogOption(onPressed: () => Navigator.pop(dialogContext, "Pending"), child: const Text("Pending")),
          SimpleDialogOption(onPressed: () => Navigator.pop(dialogContext, "Failed"), child: const Text("Failed")),
          SimpleDialogOption(onPressed: () => Navigator.pop(dialogContext, "Refunded"), child: const Text("Refunded")),
        ],
      ),
    );

    setState(() {
      _paymentStatus = status;
      _quickFilter = "Custom";
    });
  }

  // ---------------------------------------------------------------------------
  // APPLY FILTERS (unchanged)
  // ---------------------------------------------------------------------------
  bool _matchesFilters(DetailedPayment dp) {
    final p = dp.payment;

    if (_dateRange != null) {
      if (p.paymentDate.isBefore(_dateRange!.start) ||
          p.paymentDate.isAfter(_dateRange!.end)) return false;
    }

    if (_paymentMethod != null && p.method != _paymentMethod) return false;

    if (_paymentStatus != null &&
        p.status.toLowerCase() != _paymentStatus!.toLowerCase()) return false;

    return true;
  }

  // ---------------------------------------------------------------------------
  // UI ELEMENTS
  // ---------------------------------------------------------------------------

  Widget _chip(String label) {
    final active = _quickFilter == label;

    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
            color: active ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600),
      ),
      selected: active,
      selectedColor: Colors.blueAccent,
      backgroundColor: Colors.white,
      elevation: active ? 3 : 0,
      onSelected: (_) => _applyQuickFilter(label),
    );
  }

  Widget _filterButton({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.05),
              blurRadius: 4,
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.blueAccent),
            const SizedBox(width: 12),
            Text(label,
                style:
                    const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(value,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey.shade700)),
            ),
            const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  // STATUS COLOR & ICON
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'failed':
        return Colors.red;
      case 'refunded':
        return Colors.orange;
      case 'pending':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getMethodIcon(String? method) {
    switch (method?.toLowerCase()) {
      case 'cash':
        return Icons.payments_outlined;
      case 'credit card':
        return Icons.credit_card;
      case 'debit card':
        return Icons.credit_card_outlined;
      case 'bank transfer':
        return Icons.account_balance;
      case 'check':
        return Icons.fact_check_outlined;
      default:
        return Icons.attach_money;
    }
  }

  // ---------------------------------------------------------------------------
  // PREMIUM PAYMENT TILE
  // ---------------------------------------------------------------------------
  Widget _paymentTile(
      BuildContext context, PaymentProvider provider, DetailedPayment dp) {
    final p = dp.payment;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => AddPaymentScreen(payment: p))),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _getStatusColor(p.status).withOpacity(.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _getMethodIcon(p.method),
            color: _getStatusColor(p.status),
            size: 24,
          ),
        ),
        title: Text(
          "${dp.customerFirstName} ${dp.customerLastName}",
          style: const TextStyle(
              fontWeight: FontWeight.w800, fontSize: 15),
        ),
        subtitle: Text(
          DateFormat('MMM d, yyyy • h:mm a').format(p.paymentDate),
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
        trailing: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              "₱${p.amount.toStringAsFixed(2)}",
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.green),
            ),
            const SizedBox(height: 6),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _getStatusColor(p.status).withOpacity(.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                p.status,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    color: _getStatusColor(p.status)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // MAIN UI
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ---------------- PREMIUM WHITE APPBAR ----------------
      appBar: AppBar(
        title: const Text(
          "Payments History",
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Colors.black87,
            letterSpacing: 0.2,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 10,
        shadowColor: Colors.black.withOpacity(.15),
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),

      // ---------------- MAIN BODY ----------------
      body: Consumer<PaymentProvider>(
        builder: (_, provider, __) {
          final filtered = provider.payments.where(_matchesFilters).toList();

          return Column(
            children: [
              // ---------------- FILTER HEADER ----------------
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF3F7FF), Color(0xFFEFF6FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
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
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            onChanged: provider.searchPayments,
                          ),
                        ),
                        const SizedBox(width: 12),

                        // FILTER TOGGLE
                        InkWell(
                          onTap: () =>
                              setState(() => _filtersExpanded = !_filtersExpanded),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: _filtersExpanded
                                    ? Colors.blueAccent
                                    : Colors.grey.shade300,
                                width: 1.3,
                              ),
                            ),
                            child: Icon(
                              _filtersExpanded
                                  ? Icons.filter_list_off
                                  : Icons.filter_list,
                              color: _filtersExpanded
                                  ? Colors.blueAccent
                                  : Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // FILTER PANEL
                    if (_filtersExpanded) ...[
                      const SizedBox(height: 16),

                      Wrap(
                        spacing: 8,
                        children: [
                          _chip("All"),
                          _chip("Today"),
                          _chip("This Week"),
                          _chip("This Month"),
                        ],
                      ),

                      const SizedBox(height: 14),

                      _filterButton(
                        icon: Icons.date_range,
                        label: "Date Range",
                        value: _dateRange == null
                            ? "Any"
                            : "${DateFormat('MMM d').format(_dateRange!.start)} - "
                                "${DateFormat('MMM d').format(_dateRange!.end)}",
                        onTap: _pickDateRange,
                      ),

                      const SizedBox(height: 10),

                      _filterButton(
                        icon: Icons.payment,
                        label: "Method",
                        value: _paymentMethod ?? "Any",
                        onTap: _pickMethod,
                      ),

                      const SizedBox(height: 10),

                      _filterButton(
                        icon: Icons.check_circle,
                        label: "Status",
                        value: _paymentStatus ?? "Any",
                        onTap: _pickStatus,
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // ---------------- PAYMENT LIST ----------------
              Expanded(
                child: provider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : filtered.isEmpty
                        ? const Center(
                            child: Text(
                              "No matching payments",
                              style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.black54,
                                  fontWeight: FontWeight.w500),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 4),
                            itemCount: filtered.length,
                            itemBuilder: (context, i) =>
                                _paymentTile(context, provider, filtered[i]),
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
        backgroundColor: Colors.blueAccent,
      ),
    );
  }
}
