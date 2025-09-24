// lib/screens/finance_report_screen.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:gym/providers/sale_provider.dart'; // Corrected import
import 'package:gym/providers/payment_provider.dart'; // Corrected import
import 'package:gym/providers/expense_provider.dart'; // Corrected import

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
    if (picked != null && (picked.start != _startDate || picked.end != _endDate)) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      // Optionally trigger a refresh of providers if needed
      // Provider.of<SaleProvider>(context, listen: false).fetchSales(); etc.
    }
  }

  @override
  Widget build(BuildContext context) {
    final saleProvider = Provider.of<SaleProvider>(context);
    final paymentProvider = Provider.of<PaymentProvider>(context);
    final expenseProvider = Provider.of<ExpenseProvider>(context);

    if (saleProvider.isLoading || paymentProvider.isLoading || expenseProvider.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Finance Report')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Filter data for the selected date range
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


    double totalSales = salesInPeriod.fold(0.0, (sum, item) => sum + item.sale.totalAmount);
    double totalPayments = paymentsInPeriod.fold(0.0, (sum, item) => sum + item.payment.amount);
    double totalExpenses = expensesInPeriod.fold(0.0, (sum, item) => sum + item.amount);

    double totalIncome = totalSales + totalPayments;
    double netProfit = totalIncome - totalExpenses;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Finance Report'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Range Selection
            GestureDetector(
              onTap: () => _selectDateRange(context),
              child: Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 16.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Report Period:',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          Text(
                            '${DateFormat('MMM d, yyyy').format(_startDate)} - ${DateFormat('MMM d, yyyy').format(_endDate)}',
                            style: Theme.of(context).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const Icon(Icons.calendar_today, color: Colors.deepOrange),
                    ],
                  ),
                ),
              ),
            ),

            // Summary Cards
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    context,
                    title: 'Total Income',
                    value: totalIncome,
                    color: Colors.green,
                    icon: Icons.arrow_upward,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    context,
                    title: 'Total Expenses',
                    value: totalExpenses,
                    color: Colors.red,
                    icon: Icons.arrow_downward,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildSummaryCard(
              context,
              title: 'Net Profit',
              value: netProfit,
              color: netProfit >= 0 ? Colors.blue : Colors.orange,
              icon: netProfit >= 0 ? Icons.trending_up : Icons.trending_down,
            ),
            const SizedBox(height: 32),

            Text(
              'Income vs. Expenses',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  height: 250,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: [totalIncome, totalExpenses].reduce(
                          (a, b) => a > b ? a : b) *
                          1.2, // 20% extra space at top
                      barTouchData: BarTouchData(enabled: false),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              switch (value.toInt()) {
                                case 0: return const Text('Income', style: TextStyle(fontSize: 10));
                                case 1: return const Text('Expenses', style: TextStyle(fontSize: 10));
                                default: return const Text('');
                              }
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              return Text(NumberFormat.compactSimpleCurrency(locale: 'en_US').format(value), style: const TextStyle(fontSize: 10));
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: Colors.grey[200]!,
                          strokeWidth: 0.5,
                        ),
                      ),
                      borderData: FlBorderData(
                        show: false,
                      ),
                      barGroups: [
                        BarChartGroupData(
                          x: 0,
                          barRods: [
                            BarChartRodData(
                              toY: totalIncome,
                              color: Colors.green,
                              width: 30,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ],
                          showingTooltipIndicators: [0],
                        ),
                        BarChartGroupData(
                          x: 1,
                          barRods: [
                            BarChartRodData(
                              toY: totalExpenses,
                              color: Colors.red,
                              width: 30,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ],
                          showingTooltipIndicators: [0],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            Text(
              'Income Sources',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  height: 250,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      sections: _buildIncomeSections(totalSales, totalPayments),
                      borderData: FlBorderData(show: false),
                      // Add touch data for interactivity if needed
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildLegend(
              label: 'Sales Income',
              color: Colors.blue.shade300,
              value: totalSales,
            ),
            _buildLegend(
              label: 'Membership Payments',
              color: Colors.purple.shade300,
              value: totalPayments,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, {
    required String title,
    required double value,
    required Color color,
    required IconData icon,
  }) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero, // Control margin via parent Row/Column
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: Theme.of(context).textTheme.bodySmall),
                Icon(icon, color: color, size: 20),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              NumberFormat.currency(symbol: '\$').format(value),
              style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildIncomeSections(double sales, double payments) {
    List<PieChartSectionData> sections = [];
    double total = sales + payments;

    if (total == 0) {
      return [
        PieChartSectionData(
          color: Colors.grey,
          value: 100,
          title: '0%',
          radius: 60,
          titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ];
    }

    if (sales > 0) {
      sections.add(
        PieChartSectionData(
          color: Colors.blue.shade300,
          value: (sales / total) * 100,
          title: '${((sales / total) * 100).toStringAsFixed(1)}%',
          radius: 60,
          titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      );
    }
    if (payments > 0) {
      sections.add(
        PieChartSectionData(
          color: Colors.purple.shade300,
          value: (payments / total) * 100,
          title: '${((payments / total) * 100).toStringAsFixed(1)}%',
          radius: 60,
          titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      );
    }
    return sections;
  }

  Widget _buildLegend({required String label, required Color color, required double value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            color: color,
          ),
          const SizedBox(width: 8),
          Text('$label: ${NumberFormat.currency(symbol: '\$').format(value)}', style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}