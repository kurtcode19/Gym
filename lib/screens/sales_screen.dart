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
  // FILTER STATE
  bool _filtersExpanded = false;
  String _quickFilter = "All";
  DateTimeRange? _selectedDateRange;
  String? _selectedPaymentMethod;

  // QUICK FILTER PRESETS -------------------------------------------------------
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
        // This Month
        start = DateTime(now.year, now.month, 1);
        end = DateTime(now.year, now.month + 1, 1)
            .subtract(const Duration(seconds: 1));
      }

      _selectedDateRange = DateTimeRange(start: start, end: end);
    });
  }

  // PICK DATE RANGE ------------------------------------------------------------
  Future<void> _pickDateRange() async {
    final now = DateTime.now();

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 3),
      lastDate: DateTime(now.year + 3),
      initialDateRange: _selectedDateRange ??
          DateTimeRange(
              start: DateTime(now.year, now.month, 1), end: now),
    );

    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
        _quickFilter = "Custom";
      });
    }
  }

  // PICK PAYMENT METHOD --------------------------------------------------------
  Future<void> _pickPaymentMethod() async {
    final method = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text("Select Payment Method"),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text("Any"),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, "Cash"),
            child: const Text("Cash"),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, "Credit Card"),
            child: const Text("Credit Card"),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, "Debit Card"),
            child: const Text("Debit Card"),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, "Bank Transfer"),
            child: const Text("Bank Transfer"),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, "Other"),
            child: const Text("Other"),
          ),
        ],
      ),
    );

    setState(() {
      _selectedPaymentMethod = method;
      _quickFilter = "Custom";
    });
  }

  // FILTER VALIDATION ----------------------------------------------------------
  bool _saleMatchesFilters(DetailedSale ds) {
    final sale = ds.sale;

    // DATE RANGE
    if (_selectedDateRange != null) {
      if (sale.saleDate.isBefore(_selectedDateRange!.start) ||
          sale.saleDate.isAfter(_selectedDateRange!.end)) {
        return false;
      }
    }

    // PAYMENT METHOD
    if (_selectedPaymentMethod != null &&
        sale.paymentMethod != _selectedPaymentMethod) return false;

    return true;
  }

  // TOP PRODUCTS REPORT --------------------------------------------------------
  Widget _buildTopProductsReport(List<DetailedSale> sales) {
    final Map<String, Map<String, dynamic>> stats = {};

    for (var s in sales) {
      for (var item in s.items) {
        String name = item.productName;
        int qty = item.saleItem.quantity;
        double value = qty * item.saleItem.unitPrice;

        stats.putIfAbsent(name, () => {"name": name, "qty": 0, "value": 0.0});
        stats[name]!["qty"] += qty;
        stats[name]!["value"] += value;
      }
    }

    final top = stats.values.toList()
      ..sort((a, b) => b["qty"].compareTo(a["qty"]));
    final top3 = top.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Top Products",
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.grey[700])),
        const SizedBox(height: 10),

        if (top3.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300)),
            child: const Text(
              "No product data for selected filters.",
              style: TextStyle(color: Colors.grey),
            ),
          )
        else
          Column(
            children: top3.map((p) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child:
                          const Icon(Icons.inventory_2, color: Colors.blue),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p["name"],
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            Text("Qty Sold: ${p["qty"]}",
                                style: const TextStyle(
                                    color: Colors.grey, fontSize: 12)),
                          ]),
                    ),
                    Text(
                      "₱${p["value"].toStringAsFixed(2)}",
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green),
                    )
                  ],
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  // FILTER LABEL ---------------------------------------------------------------
  String getFilterLabel() {
    if (_quickFilter != "Custom") return _quickFilter;
    return "Custom";
  }

  // INLINE FILTER BUTTON --------------------------------------------------------
  Widget _inlineFilterButton({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade300)),
        child: Row(
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 8),
            Text("$label: ",
                style: const TextStyle(fontWeight: FontWeight.bold)),
            Expanded(child: Text(value)),
            const Icon(Icons.chevron_right, size: 16),
          ],
        ),
      ),
    );
  }

  // QUICK FILTER CHIP ----------------------------------------------------------
  Widget _quickFilterChip(String label) {
    final active = _quickFilter == label;

    return ChoiceChip(
      selected: active,
      label: Text(label,
          style: TextStyle(
              color: active ? Colors.white : Colors.black)),
      selectedColor: Colors.blue,
      onSelected: (_) => _applyQuickFilter(label),
    );
  }

  // STAT CARD ------------------------------------------------------------------
  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(.08),
                  blurRadius: 4,
                  offset: const Offset(0, 2))
            ]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, size: 18, color: color),
              const Spacer(),
              Text(value,
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: color))
            ]),
            const SizedBox(height: 4),
            Text(title, style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  // SALE CARD ------------------------------------------------------------------
  Widget _saleCard(
      BuildContext context, DetailedSale ds, SaleProvider sp) {
    final sale = ds.sale;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => AddSaleScreen(detailedSale: ds))),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor:
              Theme.of(context).colorScheme.primary.withOpacity(.15),
          child: Text(
            DateFormat('dd').format(sale.saleDate),
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary),
          ),
        ),
        title: Text(
          "${ds.customerFirstName} ${ds.customerLastName}",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          ds.items.map((i) => i.productName).join(", "),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              NumberFormat.currency(locale: "en_PH", symbol: "₱")
                  .format(sale.totalAmount),
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red, size: 20),
              onPressed: () => _confirmDelete(context, sp, sale.saleId),
            )
          ],
        ),
      ),
    );
  }

  // DELETE CONFIRM -------------------------------------------------------------
  void _confirmDelete(
      BuildContext context, SaleProvider sp, String saleId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
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
          ),
        ],
      ),
    );
  }

  // MAIN UI --------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sales History"),
        backgroundColor:
            Theme.of(context).colorScheme.primaryContainer,
        elevation: 0,
      ),

      body: Consumer<SaleProvider>(
        builder: (context, saleProvider, child) {
          final filtered =
              saleProvider.sales.where(_saleMatchesFilters).toList();

          final totalSales = filtered.length;
          final totalRevenue =
              filtered.fold(0.0, (sum, s) => sum + s.sale.totalAmount);

          return Column(
            children: [
              // SEARCH + FILTER BAR --------------------------------------------
              // SEARCH + FILTER BAR --------------------------------------------
Container(
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: Theme.of(context).colorScheme.primaryContainer.withOpacity(.1),
    borderRadius: const BorderRadius.only(
      bottomLeft: Radius.circular(16),
      bottomRight: Radius.circular(16),
    ),
  ),
  child: Column(
    children: [
      Row(
        children: [
          // SEARCH FIELD ---------------------------------------------------
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search sales...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (query) => saleProvider.searchSales(query),
            ),
          ),

          const SizedBox(width: 10),

          // FILTER BUTTON --------------------------------------------------
          InkWell(
            onTap: () => setState(() => _filtersExpanded = !_filtersExpanded),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(
                  color: _filtersExpanded ? Colors.blue : Colors.grey.shade300,
                  width: 1.3,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _filtersExpanded ? Icons.filter_list_off : Icons.filter_list,
                color: _filtersExpanded ? Colors.blue : Colors.black87,
                size: 22,
              ),
            ),
          ),
        ],
      ),

      // COLLAPSIBLE FILTER CONTENT ----------------------------------------
      if (_filtersExpanded) ...[
        const SizedBox(height: 16),

        // QUICK FILTERS ----------------------------------------------------
        Wrap(
          spacing: 6,
          children: [
            _quickFilterChip("All"),
            _quickFilterChip("Today"),
            _quickFilterChip("This Week"),
            _quickFilterChip("This Month"),
          ],
        ),

        const SizedBox(height: 14),

        // ADVANCED FILTERS -------------------------------------------------
        _inlineFilterButton(
          icon: Icons.date_range,
          label: "Date Range",
          value: _selectedDateRange == null
              ? "Any"
              : "${DateFormat('MMM d').format(_selectedDateRange!.start)} - ${DateFormat('MMM d').format(_selectedDateRange!.end)}",
          onTap: _pickDateRange,
        ),

        const SizedBox(height: 8),

        _inlineFilterButton(
          icon: Icons.payment,
          label: "Payment",
          value: _selectedPaymentMethod ?? "Any",
          onTap: _pickPaymentMethod,
        ),

        const SizedBox(height: 10),

        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            "Active filter: ${getFilterLabel()}",
            style: TextStyle(
              color: Theme.of(context).colorScheme.outline,
              fontSize: 12,
            ),
          ),
        ),
      ]
    ],
  ),
),


              const SizedBox(height: 12),

              // STATS ----------------------------------------------------------
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _statCard("Total Sales", totalSales.toString(),
                        Icons.receipt_long, Colors.blue),
                    const SizedBox(width: 10),
                    _statCard(
                      "Revenue",
                      NumberFormat.currency(
                              locale: "en_PH", symbol: "₱")
                          .format(totalRevenue),
                      Icons.monetization_on,
                      Colors.green,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // TOP PRODUCTS ---------------------------------------------------
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildTopProductsReport(filtered),
              ),

              const SizedBox(height: 12),

              // SALES LIST -----------------------------------------------------
              Expanded(
                child: saleProvider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : filtered.isEmpty
                        ? const Center(child: Text("No matching sales"))
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filtered.length,
                            itemBuilder: (context, i) =>
                                _saleCard(context, filtered[i],
                                    saleProvider),
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
