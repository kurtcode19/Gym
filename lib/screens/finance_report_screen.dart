// lib/screens/finance_report_screen.dart

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:gym/providers/sale_provider.dart';
import 'package:gym/providers/payment_provider.dart';
import 'package:gym/providers/expense_provider.dart';
import 'package:gym/providers/attendance_provider.dart';
import 'package:gym/providers/pt_provider.dart';
import 'package:gym/providers/trainer_package_provider.dart';

class FinanceReportScreen extends StatefulWidget {
  const FinanceReportScreen({super.key});

  @override
  State<FinanceReportScreen> createState() => _FinanceReportScreenState();
}

class _FinanceReportScreenState extends State<FinanceReportScreen> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  Future<void> _selectDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final saleProvider = Provider.of<SaleProvider>(context);
    final paymentProvider = Provider.of<PaymentProvider>(context);
    final expenseProvider = Provider.of<ExpenseProvider>(context);
    final attendanceProvider = Provider.of<AttendanceProvider>(context);
    final ptProvider = Provider.of<PTProvider>(context);
    final packageProvider = Provider.of<TrainerPackageProvider>(context);

    if (saleProvider.isLoading ||
        paymentProvider.isLoading ||
        expenseProvider.isLoading ||
        attendanceProvider.isLoading ||
        ptProvider.isLoading ||
        packageProvider.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text("Finance Report")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // ----------------------------------------------------------
    // FILTER DATA BY DATE RANGE
    // ----------------------------------------------------------

    bool inRange(DateTime date) =>
        date.isAfter(_startDate.subtract(const Duration(days: 1))) &&
        date.isBefore(_endDate.add(const Duration(days: 1)));

    final salesInPeriod = saleProvider.sales.where((s) => inRange(s.sale.saleDate));
    final paymentsInPeriod = paymentProvider.payments.where((p) => inRange(p.payment.paymentDate));
    final expensesInPeriod = expenseProvider.expenses.where((e) => inRange(e.expenseDate));
    final walkInsInPeriod = attendanceProvider.attendanceRecords.where(
      (a) => inRange(a.attendance.date) && a.attendance.amountPaid > 0,
    );

    // PT sessions (cash only)
    final ptCashSessions = ptProvider.sessions.where(
      (s) => inRange(s.session.startTime) && s.session.packageId == null && s.session.isPaid,
    );

    // PT package sales (full price at activation)
    final packageSales = packageProvider.packages.where(
      (p) => inRange(p.package.startDate),
    );

    // ----------------------------------------------------------
    // CALCULATE REVENUES
    // ----------------------------------------------------------

    double totalSales = salesInPeriod.fold(0.0, (sum, item) => sum + item.sale.totalAmount);

    double totalMembershipPayments = paymentsInPeriod.fold(
      0.0,
      (sum, item) => sum + item.payment.amount,
    );

    double totalWalkIns = walkInsInPeriod.fold(
      0.0,
      (sum, item) => sum + item.attendance.amountPaid,
    );

    // PT package income (FULL PRICE)
    double totalPackageIncome = packageSales.fold(
      0.0,
      (sum, item) => sum + item.package.price,
    );

    // Cash PT sessions only
    double totalPTCashIncome = ptCashSessions.fold(
      0.0,
      (sum, item) => sum + item.session.cost,
    );

    double totalPTIncome = totalPackageIncome + totalPTCashIncome;

    double totalExpenses = expensesInPeriod.fold(
      0.0,
      (sum, item) => sum + item.amount,
    );

    double totalIncome = totalSales +
        totalMembershipPayments +
        totalWalkIns +
        totalPTIncome;

    double netProfit = totalIncome - totalExpenses;

    // ----------------------------------------------------------
    // UI
    // ----------------------------------------------------------

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Financial Overview", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: GestureDetector(
                onTap: () => _selectDateRange(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.grey.shade300),
                    color: Colors.white,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.calendar_today, size: 16, color: Theme.of(context).primaryColor),
                      const SizedBox(width: 8),
                      Text(
                        "${DateFormat('MMM d, yyyy').format(_startDate)} — ${DateFormat('MMM d, yyyy').format(_endDate)}",
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // NET PROFIT CARD
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: netProfit >= 0
                      ? [const Color(0xFF11998e), const Color(0xFF38ef7d)]
                      : [const Color(0xFFcb2d3e), const Color(0xFFef473a)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Net Profit", style: TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 8),
                  Text(
                    NumberFormat.currency(locale: 'en_PH', symbol: '₱').format(netProfit),
                    style: const TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(child: _buildDetailCard("Total Income", totalIncome, Icons.arrow_downward, Colors.green)),
                const SizedBox(width: 16),
                Expanded(child: _buildDetailCard("Total Expenses", totalExpenses, Icons.arrow_upward, Colors.red)),
              ],
            ),

            const SizedBox(height: 32),
            const Text("Revenue Sources", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
              child: Column(
                children: [
                  SizedBox(
                    height: 200,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 4,
                        centerSpaceRadius: 40,
                        borderData: FlBorderData(show: false),
                        sections: _buildIncomeSections(
                          totalSales,
                          totalMembershipPayments,
                          totalWalkIns,
                          totalPTIncome,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildLegendItem("Product Sales", totalSales, Colors.blue.shade400),
                  const Divider(),
                  _buildLegendItem("Memberships", totalMembershipPayments, Colors.purple.shade400),
                  const Divider(),
                  _buildLegendItem("Walk-ins", totalWalkIns, Colors.orange.shade400),
                  const Divider(),
                  _buildLegendItem("Personal Training", totalPTIncome, Colors.teal.shade400),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard(String title, double value, IconData icon, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: iconColor.withOpacity(0.15), shape: BoxShape.circle),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            NumberFormat.compactCurrency(locale: 'en_PH', symbol: '₱').format(value),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildIncomeSections(
      double sales, double membership, double walkins, double pt) {
    double total = sales + membership + walkins + pt;

    if (total == 0) {
      return [
        PieChartSectionData(
          color: Colors.grey.shade300,
          value: 100,
          radius: 50,
        ),
      ];
    }

    List<PieChartSectionData> sections = [];

    if (sales > 0) {
      sections.add(PieChartSectionData(
        color: Colors.blue.shade400,
        value: (sales / total) * 100,
        radius: 50,
        title: "${((sales / total) * 100).round()}%",
        titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
      ));
    }

    if (membership > 0) {
      sections.add(PieChartSectionData(
        color: Colors.purple.shade400,
        value: (membership / total) * 100,
        radius: 50,
        title: "${((membership / total) * 100).round()}%",
        titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
      ));
    }

    if (walkins > 0) {
      sections.add(PieChartSectionData(
        color: Colors.orange.shade400,
        value: (walkins / total) * 100,
        radius: 50,
        title: "${((walkins / total) * 100).round()}%",
        titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
      ));
    }

    if (pt > 0) {
      sections.add(PieChartSectionData(
        color: Colors.teal.shade400,
        value: (pt / total) * 100,
        radius: 50,
        title: "${((pt / total) * 100).round()}%",
        titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
      ));
    }

    return sections;
  }

  Widget _buildLegendItem(String label, double value, Color color) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 12),
        Text(label, style: TextStyle(color: Colors.grey[800], fontWeight: FontWeight.w500)),
        const Spacer(),
        Text(
          NumberFormat.currency(locale: 'en_PH', symbol: '₱', decimalDigits: 0).format(value),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
