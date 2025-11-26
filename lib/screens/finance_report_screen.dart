// lib/screens/finance_report_screen.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:gym/providers/sale_provider.dart';
import 'package:gym/providers/payment_provider.dart';
import 'package:gym/providers/expense_provider.dart';
import 'package:gym/providers/attendance_provider.dart';

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
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && (picked.start != _startDate || picked.end != _endDate)) {
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

    if (saleProvider.isLoading || 
        paymentProvider.isLoading || 
        expenseProvider.isLoading || 
        attendanceProvider.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Finance Report')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // --- FILTER DATA ---
    final salesInPeriod = saleProvider.sales.where((s) =>
        s.sale.saleDate.isAfter(_startDate.subtract(const Duration(days: 1))) &&
        s.sale.saleDate.isBefore(_endDate.add(const Duration(days: 1)))
    ).toList();

    final paymentsInPeriod = paymentProvider.payments.where((p) =>
        p.payment.paymentDate.isAfter(_startDate.subtract(const Duration(days: 1))) &&
        p.payment.paymentDate.isBefore(_endDate.add(const Duration(days: 1)))
    ).toList();

    final expensesInPeriod = expenseProvider.expenses.where((e) =>
        e.expenseDate.isAfter(_startDate.subtract(const Duration(days: 1))) &&
        e.expenseDate.isBefore(_endDate.add(const Duration(days: 1)))
    ).toList();

    final walkInsInPeriod = attendanceProvider.attendanceRecords.where((a) =>
        a.attendance.date.isAfter(_startDate.subtract(const Duration(days: 1))) &&
        a.attendance.date.isBefore(_endDate.add(const Duration(days: 1))) &&
        a.attendance.amountPaid > 0 
    ).toList();

    // --- CALCULATE TOTALS ---
    double totalSales = salesInPeriod.fold(0.0, (sum, item) => sum + item.sale.totalAmount);
    double totalPayments = paymentsInPeriod.fold(0.0, (sum, item) => sum + item.payment.amount);
    double totalWalkIns = walkInsInPeriod.fold(0.0, (sum, item) => sum + item.attendance.amountPaid);
    double totalExpenses = expensesInPeriod.fold(0.0, (sum, item) => sum + item.amount);

    double totalIncome = totalSales + totalPayments + totalWalkIns;
    double netProfit = totalIncome - totalExpenses;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Financial Overview', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Picker Pill
            Center(
              child: GestureDetector(
                onTap: () => _selectDateRange(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.grey.shade300),
                    boxShadow: [
                      BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5, offset: const Offset(0, 2))
                    ]
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.calendar_today, size: 16, color: Theme.of(context).primaryColor),
                      const SizedBox(width: 8),
                      Text(
                        '${DateFormat('MMM d, yyyy').format(_startDate)}  —  ${DateFormat('MMM d, yyyy').format(_endDate)}',
                        style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_drop_down, color: Colors.grey),
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 24),

            // Net Profit Hero Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: netProfit >= 0 
                      ? [const Color(0xFF11998e), const Color(0xFF38ef7d)] 
                      : [const Color(0xFFcb2d3e), const Color(0xFFef473a)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: (netProfit >= 0 ? Colors.green : Colors.red).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Net Profit", style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  Text(
                    NumberFormat.currency(locale: 'en_PH', symbol: '₱').format(netProfit),
                    style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Income vs Expenses Cards
            Row(
              children: [
                Expanded(
                  child: _buildDetailCard(
                    title: 'Total Income',
                    value: totalIncome,
                    icon: Icons.arrow_downward, // Money coming in
                    iconColor: Colors.green,
                    bgColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDetailCard(
                    title: 'Total Expenses',
                    value: totalExpenses,
                    icon: Icons.arrow_upward, // Money going out
                    iconColor: Colors.red,
                    bgColor: Colors.white,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Bar Chart Section
            const Text('Cash Flow', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 12),
            Container(
              height: 300,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: ([totalIncome, totalExpenses].reduce((a, b) => a > b ? a : b)) == 0 
                      ? 100 
                      : ([totalIncome, totalExpenses].reduce((a, b) => a > b ? a : b)) * 1.2,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor:  (BarChartGroupData group) => Colors.blueGrey,
                      tooltipPadding: const EdgeInsets.all(8),
                      
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final style = TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold, fontSize: 12);
                          switch (value.toInt()) {
                            case 0: return Padding(padding: const EdgeInsets.only(top: 8), child: Text('Income', style: style));
                            case 1: return Padding(padding: const EdgeInsets.only(top: 8), child: Text('Expenses', style: style));
                            default: return const Text('');
                          }
                        },
                        reservedSize: 30,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 45,
                        getTitlesWidget: (value, meta) {
                          if (value == 0) return const SizedBox.shrink();
                          return Text(
                            NumberFormat.compactCurrency(locale: 'en_PH', symbol: '₱').format(value),
                            style: TextStyle(color: Colors.grey.shade400, fontSize: 10),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: ([totalIncome, totalExpenses].reduce((a, b) => a > b ? a : b)) / 5,
                    getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade100, strokeWidth: 1),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: [
                    BarChartGroupData(
                      x: 0,
                      barRods: [
                        BarChartRodData(
                          toY: totalIncome,
                          color: const Color(0xFF38ef7d),
                          width: 40,
                          borderRadius: BorderRadius.circular(6),
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: ([totalIncome, totalExpenses].reduce((a, b) => a > b ? a : b)) * 1.2,
                            color: Colors.grey.shade50,
                          )
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 1,
                      barRods: [
                        BarChartRodData(
                          toY: totalExpenses,
                          color: const Color(0xFFef473a),
                          width: 40,
                          borderRadius: BorderRadius.circular(6),
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: ([totalIncome, totalExpenses].reduce((a, b) => a > b ? a : b)) * 1.2,
                            color: Colors.grey.shade50,
                          )
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Income Sources Pie Chart
            const Text('Revenue Sources', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                children: [
                  SizedBox(
                    height: 200,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 4,
                        centerSpaceRadius: 40,
                        sections: _buildIncomeSections(totalSales, totalPayments, totalWalkIns),
                        borderData: FlBorderData(show: false),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildLegendItem('Product Sales', totalSales, Colors.blue.shade400),
                  const Divider(height: 20),
                  _buildLegendItem('Memberships', totalPayments, Colors.purple.shade400),
                  const Divider(height: 20),
                  _buildLegendItem('Walk-ins / Passes', totalWalkIns, Colors.orange.shade400),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard({
    required String title,
    required double value,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            NumberFormat.compactCurrency(locale: 'en_PH', symbol: '₱').format(value),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildIncomeSections(double sales, double payments, double walkIns) {
    List<PieChartSectionData> sections = [];
    double total = sales + payments + walkIns;

    if (total == 0) {
      return [
        PieChartSectionData(
          color: Colors.grey.shade200,
          value: 100,
          title: '',
          radius: 25,
        ),
      ];
    }

    if (sales > 0) {
      sections.add(
        PieChartSectionData(
          color: Colors.blue.shade400,
          value: (sales / total) * 100,
          title: '${((sales / total) * 100).round()}%',
          radius: 50,
          titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      );
    }
    if (payments > 0) {
      sections.add(
        PieChartSectionData(
          color: Colors.purple.shade400,
          value: (payments / total) * 100,
          title: '${((payments / total) * 100).round()}%',
          radius: 50,
          titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      );
    }
    if (walkIns > 0) {
      sections.add(
        PieChartSectionData(
          color: Colors.orange.shade400,
          value: (walkIns / total) * 100,
          title: '${((walkIns / total) * 100).round()}%',
          radius: 50,
          titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      );
    }
    return sections;
  }

  Widget _buildLegendItem(String label, double value, Color color) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 12),
        Text(label, style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w500)),
        const Spacer(),
        Text(
          NumberFormat.currency(locale: 'en_PH', symbol: '₱', decimalDigits: 0).format(value),
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
      ],
    );
  }
}