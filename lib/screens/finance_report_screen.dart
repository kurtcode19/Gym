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

  bool _showTrendChart = false;

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

    bool inRange(DateTime date) =>
        date.isAfter(_startDate.subtract(const Duration(days: 1))) &&
        date.isBefore(_endDate.add(const Duration(days: 1)));

    final salesInPeriod =
        saleProvider.sales.where((s) => inRange(s.sale.saleDate));
    final paymentsInPeriod =
        paymentProvider.payments.where((p) => inRange(p.payment.paymentDate));
    final expensesInPeriod =
        expenseProvider.expenses.where((e) => inRange(e.expenseDate));
    final walkInsInPeriod = attendanceProvider.attendanceRecords.where(
      (a) => inRange(a.attendance.date) && a.attendance.amountPaid > 0,
    );

    final ptCashSessions = ptProvider.sessions.where(
      (s) =>
          inRange(s.session.startTime) &&
          s.session.packageId == null &&
          s.session.isPaid,
    );

    final packageSales = packageProvider.packages.where(
      (p) => inRange(p.package.startDate),
    );

    double totalSales =
        salesInPeriod.fold(0.0, (sum, item) => sum + item.sale.totalAmount);

    double totalMembershipPayments = paymentsInPeriod.fold(
      0.0,
      (sum, item) => sum + item.payment.amount,
    );

    double totalWalkIns = walkInsInPeriod.fold(
      0.0,
      (sum, item) => sum + item.attendance.amountPaid,
    );

    double totalPackageIncome =
        packageSales.fold(0.0, (sum, item) => sum + item.package.price);

    double totalPTCashIncome =
        ptCashSessions.fold(0.0, (sum, item) => sum + item.session.cost);

    double totalPTIncome = totalPackageIncome + totalPTCashIncome;

    double totalExpenses =
        expensesInPeriod.fold(0.0, (sum, item) => sum + item.amount);

    double totalIncome = totalSales +
        totalMembershipPayments +
        totalWalkIns +
        totalPTIncome;

    double netProfit = totalIncome - totalExpenses;

    List<DateTime> rangeDays = List.generate(
      _endDate.difference(_startDate).inDays + 1,
      (i) => _startDate.add(Duration(days: i)),
    );

    List<double> dailyRevenue = rangeDays.map((day) {
      double total = 0;

      total += salesInPeriod
          .where((s) => isSameDay(s.sale.saleDate, day))
          .fold(0, (sum, s) => sum + s.sale.totalAmount);

      total += paymentsInPeriod
          .where((p) => isSameDay(p.payment.paymentDate, day))
          .fold(0, (sum, p) => sum + p.payment.amount);

      total += walkInsInPeriod
          .where((a) => isSameDay(a.attendance.date, day))
          .fold(0, (sum, a) => sum + a.attendance.amountPaid);

      return total;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Financial Overview",
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0.5,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),

      //----------------------------------------------------------------------
      // BODY
      //----------------------------------------------------------------------
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                //----------------------------------------------------------------------
                // DATE PICKER
                //----------------------------------------------------------------------
                Center(
                  child: GestureDetector(
                    onTap: () => _selectDateRange(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.grey.shade300),
                        color: Colors.white,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.calendar_today,
                              size: 16, color: Colors.blue.shade600),
                          const SizedBox(width: 8),
                          Text(
                            "${DateFormat('MMM d, yyyy').format(_startDate)} — ${DateFormat('MMM d, yyyy').format(_endDate)}",
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          const Icon(Icons.arrow_drop_down),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                //----------------------------------------------------------------------
                // NET PROFIT CARD
                //----------------------------------------------------------------------
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(26),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: netProfit >= 0
                          ? [const Color(0xFF11998e), const Color(0xFF38ef7d)]
                          : [const Color(0xFFcb2d3e), const Color(0xFFef473a)],
                    ),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(.08),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Net Profit",
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14)),
                      const SizedBox(height: 6),
                      Text(
                        NumberFormat.currency(
                                locale: 'en_PH', symbol: '₱')
                            .format(netProfit),
                        style: const TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            color: Colors.white),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                //----------------------------------------------------------------------
                // INCOME & EXPENSES CARDS
                //----------------------------------------------------------------------
                Row(
                  children: [
                    Expanded(
                      child: _buildDetailCard(
                        "Total Income",
                        totalIncome,
                        Icons.trending_up,
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildDetailCard(
                        "Total Expenses",
                        totalExpenses,
                        Icons.trending_down,
                        Colors.red,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 35),

                //----------------------------------------------------------------------
                // COLLAPSIBLE REVENUE TREND CHART
                //----------------------------------------------------------------------
                GestureDetector(
                  onTap: () =>
                      setState(() => _showTrendChart = !_showTrendChart),
                  child: Row(
                    children: [
                      Text("Revenue Trend",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.grey[800])),
                      const Spacer(),
                      AnimatedRotation(
                        turns: _showTrendChart ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: const Icon(Icons.keyboard_arrow_down_rounded,
                            size: 28),
                      ),
                    ],
                  ),
                ),

                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  height: _showTrendChart ? 260 : 0,
                  child: _showTrendChart
                      ? Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: FittedBox(
                            fit: BoxFit.contain,
                            alignment: Alignment.center,
                            child: SizedBox(
                              width: 600,
                              height: 250,
                              child: LineChart(
                                LineChartData(
                                  minY: 0,
                                  titlesData: FlTitlesData(show: false),
                                  gridData: FlGridData(show: false),
                                  borderData: FlBorderData(show: false),
                                  lineBarsData: [
                                    LineChartBarData(
                                      spots: [
                                        for (int i = 0;
                                            i < dailyRevenue.length;
                                            i++)
                                          FlSpot(i.toDouble(),
                                              dailyRevenue[i].toDouble())
                                      ],
                                      isCurved: true,
                                      color: Colors.blue.shade600,
                                      barWidth: 3,
                                      belowBarData: BarAreaData(
                                        show: true,
                                        color: Colors.blue.shade200
                                            .withOpacity(0.35),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        )
                      : null,
                ),

                const SizedBox(height: 35),

                //----------------------------------------------------------------------
                // PIE CHART - Revenue Sources
                //----------------------------------------------------------------------
                Text("Revenue Sources",
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800])),
                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Column(
                    children: [
                      FittedBox(
                        fit: BoxFit.contain,
                        child: SizedBox(
                          width: 500,
                          height: 210,
                          child: PieChart(
                            PieChartData(
                              sectionsSpace: 6,
                              centerSpaceRadius: 45,
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
                      ),
                      const SizedBox(height: 16),

                      _buildLegendItem("Product Sales", totalSales,
                          Colors.blue.shade400),
                      const Divider(),
                      _buildLegendItem("Memberships", totalMembershipPayments,
                          Colors.purple.shade400),
                      const Divider(),
                      _buildLegendItem("Walk-ins", totalWalkIns,
                          Colors.orange.shade400),
                      const Divider(),
                      _buildLegendItem("Personal Training", totalPTIncome,
                          Colors.teal.shade400),
                    ],
                  ),
                ),

                const SizedBox(height: 40)
              ],
            ),
          );
        },
      ),
    );
  }

  //----------------------------------------------------------------------
  // HELPERS
  //----------------------------------------------------------------------
  bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Widget _buildDetailCard(
      String title, double value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            NumberFormat.compactCurrency(
              locale: 'en_PH',
              symbol: '₱',
            ).format(value),
            style: const TextStyle(
                fontSize: 22, fontWeight: FontWeight.bold),
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

    return [
      if (sales > 0)
        PieChartSectionData(
          color: Colors.blue.shade400,
          value: sales,
          title: "${((sales / total) * 100).round()}%",
          radius: 50,
          titleStyle: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
        ),
      if (membership > 0)
        PieChartSectionData(
          color: Colors.purple.shade400,
          value: membership,
          title: "${((membership / total) * 100).round()}%",
          radius: 50,
          titleStyle: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
        ),
      if (walkins > 0)
        PieChartSectionData(
          color: Colors.orange.shade400,
          value: walkins,
          title: "${((walkins / total) * 100).round()}%",
          radius: 50,
          titleStyle: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
        ),
      if (pt > 0)
        PieChartSectionData(
          color: Colors.teal.shade400,
          value: pt,
          title: "${((pt / total) * 100).round()}%",
          radius: 50,
          titleStyle: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
        ),
    ];
  }

  Widget _buildLegendItem(String label, double value, Color color) {
    return Row(
      children: [
        Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(label,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w500)),
        ),
        Text(
          NumberFormat.currency(locale: 'en_PH', symbol: '₱', decimalDigits: 0)
              .format(value),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
