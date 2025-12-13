import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gym/providers/sale_provider.dart';
import 'package:gym/screens/add_sale_screen.dart';
import 'package:gym/models/sale.dart';
import 'package:intl/intl.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  bool _filtersExpanded = false;
  String _quickFilter = "All";
  DateTimeRange? _selectedDateRange;
  String? _selectedPaymentMethod;

  // ------------------------------------------------------------
  // QUICK FILTER LOGIC
  // ------------------------------------------------------------
  void _applyQuickFilter(String filter) {
    final now = DateTime.now();
    DateTime start;
    DateTime end;

    setState(() {
      _quickFilter = filter;

      if (filter == "All") {
        _selectedDateRange = null;
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

      _selectedDateRange = DateTimeRange(start: start, end: end);
    });
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 3),
      lastDate: DateTime(now.year + 3),
      initialDateRange: _selectedDateRange ??
          DateTimeRange(start: DateTime(now.year, now.month, 1), end: now),
    );

    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
        _quickFilter = "Custom";
      });
    }
  }

  Future<void> _pickPaymentMethod() async {
    final method = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text("Select Payment Method"),
        children: [
          SimpleDialogOption(onPressed: () => Navigator.pop(ctx, null), child: const Text("Any")),
          SimpleDialogOption(onPressed: () => Navigator.pop(ctx, "Cash"), child: const Text("Cash")),
          SimpleDialogOption(onPressed: () => Navigator.pop(ctx, "Credit Card"), child: const Text("Credit Card")),
          SimpleDialogOption(onPressed: () => Navigator.pop(ctx, "Debit Card"), child: const Text("Debit Card")),
          SimpleDialogOption(onPressed: () => Navigator.pop(ctx, "Bank Transfer"), child: const Text("Bank Transfer")),
          SimpleDialogOption(onPressed: () => Navigator.pop(ctx, "Other"), child: const Text("Other")),
        ],
      ),
    );

    setState(() {
      _selectedPaymentMethod = method;
      _quickFilter = "Custom";
    });
  }

  // ------------------------------------------------------------
  // FILTER CHECK LOGIC
  // ------------------------------------------------------------
  bool _saleMatchesFilters(DetailedSale ds) {
    final sale = ds.sale;

    if (_selectedDateRange != null) {
      if (sale.saleDate.isBefore(_selectedDateRange!.start) ||
          sale.saleDate.isAfter(_selectedDateRange!.end)) {
        return false;
      }
    }

    if (_selectedPaymentMethod != null &&
        sale.paymentMethod != _selectedPaymentMethod) {
      return false;
    }

    return true;
  }

  // ------------------------------------------------------------
  // PREMIUM UI HELPERS
  // ------------------------------------------------------------
  Widget _quickFilterChip(String label) {
    final selected = _quickFilter == label;

    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: selected ? Colors.white : Colors.black87,
        ),
      ),
      selected: selected,
      selectedColor: Colors.blueAccent,
      backgroundColor: Colors.white,
      elevation: selected ? 4 : 0,
      pressElevation: 2,
      onSelected: (_) => _applyQuickFilter(label),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    );
  }

  Widget _inlineFilterButton({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Colors.blueAccent),
            const SizedBox(width: 10),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                value,
                style: TextStyle(color: Colors.grey.shade700),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // TOP PRODUCTS REPORT
  // ------------------------------------------------------------
  Widget _buildTopProductsReport(List<DetailedSale> sales) {
    final Map<String, Map<String, dynamic>> stats = {};

    for (var s in sales) {
      for (var item in s.items) {
        final name = item.productName;
        final qty = item.saleItem.quantity;
        final value = qty * item.saleItem.unitPrice;

        stats.putIfAbsent(name, () => {"qty": 0, "value": 0, "name": name});
        stats[name]!["qty"] += qty;
        stats[name]!["value"] += value;
      }
    }

    final top3 = stats.values.toList()
      ..sort((a, b) => b["qty"].compareTo(a["qty"]))
      ..take(3);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Top Products",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),

        if (stats.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: const Text("No product data available",
                style: TextStyle(color: Colors.grey)),
          )
        else
          Column(
            children: top3.map((p) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(.05),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    )
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.withOpacity(.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.inventory_2_rounded,
                          size: 22, color: Colors.blueAccent),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p["name"],
                                style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700)),
                            Text("Qty Sold: ${p["qty"]}",
                                style: TextStyle(color: Colors.grey.shade700)),
                          ]),
                    ),
                    Text(
                      "₱${p["value"].toStringAsFixed(2)}",
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.green),
                    )
                  ],
                ),
              );
            }).toList(),
          )
      ],
    );
  }

  // ------------------------------------------------------------
  // SALE CARD
  // ------------------------------------------------------------
  Widget _saleCard(BuildContext context, DetailedSale ds, SaleProvider sp) {
    final sale = ds.sale;

    return Card(
      elevation: 3,
      shadowColor: Colors.black.withOpacity(.06),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ListTile(
        onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => AddSaleScreen(detailedSale: ds))),
        leading: CircleAvatar(
          radius: 26,
          backgroundColor: Colors.blueAccent.withOpacity(.15),
          child: Text(
            DateFormat('dd').format(sale.saleDate),
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Colors.blueAccent),
          ),
        ),
        title: Text(
          "${ds.customerFirstName} ${ds.customerLastName}",
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          ds.items.map((i) => i.productName).join(", "),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              NumberFormat.currency(locale: "en_PH", symbol: "₱")
                  .format(sale.totalAmount),
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.blueAccent),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  color: Colors.red, size: 22),
              onPressed: () => _confirmDelete(context, sp, sale.saleId),
            )
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // CONFIRM DELETE
  // ------------------------------------------------------------
  void _confirmDelete(BuildContext context, SaleProvider sp, String saleId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Delete Sale"),
        content: const Text("Are you sure you want to delete this sale?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              sp.deleteSale(saleId);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Delete"),
          )
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // MISSING METHOD — FIXED HERE 🎉
  // ------------------------------------------------------------
  Widget statCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.06),
              blurRadius: 6,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: color),
                const Spacer(),
                Text(
                  value,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color,
                      fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey[700],
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // MAIN UI
  // ------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 8,
        centerTitle: true,
        backgroundColor: Colors.white,
        shadowColor: Colors.black.withOpacity(.15),
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          "Sales History",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
      ),

      body: Consumer<SaleProvider>(
        builder: (context, saleProvider, _) {
          final filtered =
              saleProvider.sales.where(_saleMatchesFilters).toList();

          final totalSales = filtered.length;
          final totalRevenue =
              filtered.fold(0.0, (sum, s) => sum + s.sale.totalAmount);

          return Column(
            children: [
              // ------------------------------------------------------------
              // SEARCH + FILTER UI
              // ------------------------------------------------------------
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFEEF4FF), Color(0xFFE9F5FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(22),
                    bottomRight: Radius.circular(22),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: "Search sales...",
                              prefixIcon: const Icon(Icons.search),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            onChanged: saleProvider.searchSales,
                          ),
                        ),
                        const SizedBox(width: 10),
                        InkWell(
                          onTap: () => setState(
                              () => _filtersExpanded = !_filtersExpanded),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: _filtersExpanded
                                    ? Colors.blue
                                    : Colors.grey.shade300,
                                width: 1.3,
                              ),
                            ),
                            child: Icon(
                              _filtersExpanded
                                  ? Icons.filter_list_off
                                  : Icons.filter_list,
                              color: _filtersExpanded
                                  ? Colors.blue
                                  : Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (_filtersExpanded) ...[
                      const SizedBox(height: 16),

                      Wrap(
                        spacing: 8,
                        children: [
                          _quickFilterChip("All"),
                          _quickFilterChip("Today"),
                          _quickFilterChip("This Week"),
                          _quickFilterChip("This Month"),
                        ],
                      ),

                      const SizedBox(height: 14),

                      _inlineFilterButton(
                        icon: Icons.date_range,
                        label: "Date Range",
                        value: _selectedDateRange == null
                            ? "Any"
                            : "${DateFormat('MMM d').format(_selectedDateRange!.start)} - "
                                "${DateFormat('MMM d').format(_selectedDateRange!.end)}",
                        onTap: _pickDateRange,
                      ),

                      const SizedBox(height: 10),

                      _inlineFilterButton(
                        icon: Icons.payment,
                        label: "Payment",
                        value: _selectedPaymentMethod ?? "Any",
                        onTap: _pickPaymentMethod,
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ------------------------------------------------------------
              // STATS ROW
              // ------------------------------------------------------------
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    statCard("Total Sales", "$totalSales",
                        Icons.receipt_long, Colors.blue),
                    const SizedBox(width: 12),
                    statCard(
                      "Revenue",
                      NumberFormat.currency(
                              locale: "en_PH", symbol: "₱")
                          .format(totalRevenue),
                      Icons.payments_rounded,
                      Colors.green,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ------------------------------------------------------------
              // TOP PRODUCTS
              // ------------------------------------------------------------
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildTopProductsReport(filtered),
              ),

              const SizedBox(height: 12),

              // ------------------------------------------------------------
              // SALES LIST
              // ------------------------------------------------------------
              Expanded(
                child: saleProvider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : filtered.isEmpty
                        ? const Center(child: Text("No sales found."))
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filtered.length,
                            itemBuilder: (_, i) =>
                                _saleCard(context, filtered[i], saleProvider),
                          ),
              ),
            ],
          );
        },
      ),

      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text("New Sale"),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddSaleScreen()),
        ),
      ),
    );
  }
}
