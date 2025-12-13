import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

// Providers
import 'package:gym/providers/customer_provider.dart';
import 'package:gym/providers/membership_provider.dart';
import 'package:gym/providers/attendance_provider.dart';
import 'package:gym/providers/class_provider.dart';
import 'package:gym/providers/sale_provider.dart';
import 'package:gym/providers/payment_provider.dart';
import 'package:gym/providers/equipment_provider.dart';
import 'package:gym/auth/auth_provider.dart';

// Backup + Settings
import 'package:gym/services/backup_service.dart';
import 'package:gym/screens/settings_screen.dart';
import 'package:gym/screens/about_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Timer? _autoRefreshTimer;
  bool _isRefreshing = false;

  final Color _primaryColor = const Color(0xFF2563EB);
  final Color _bgColor = const Color(0xFFF6F7F9);

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkBackupReminder();
      _refreshData();
      _startAutoRefresh();
    });
  }

  void _startAutoRefresh() {
    _autoRefreshTimer =
        Timer.periodic(const Duration(seconds: 30), (_) => _refreshData());
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  // BACKUP REMINDER
  void _checkBackupReminder() async {
    final backupService = BackupService();
    if (await backupService.needsBackup()) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.white),
              SizedBox(width: 10),
              Expanded(child: Text("You haven't backed up in a while!")),
            ],
          ),
          backgroundColor: Colors.orange[800],
          duration: const Duration(seconds: 10),
          action: SnackBarAction(
            label: "Backup Now",
            textColor: Colors.white,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ),
      );
    }
  }

  // REFRESH ALL PROVIDERS
  Future<void> _refreshData() async {
    setState(() => _isRefreshing = true);

    await Future.wait([
      Provider.of<CustomerProvider>(context, listen: false).fetchCustomers(),
      Provider.of<MembershipProvider>(context, listen: false).fetchMemberships(),
      Provider.of<AttendanceProvider>(context, listen: false)
          .fetchAttendanceRecords(),
      Provider.of<SaleProvider>(context, listen: false).fetchSales(),
      Provider.of<PaymentProvider>(context, listen: false).fetchPayments(),
      Provider.of<ClassProvider>(context, listen: false).fetchGymClasses(),
      Provider.of<EquipmentProvider>(context, listen: false).fetchEquipment(),
    ]);

    await Future.delayed(const Duration(milliseconds: 300));
    setState(() => _isRefreshing = false);
  }

  @override
  Widget build(BuildContext context) {
    final membershipProvider = Provider.of<MembershipProvider>(context);
    final attendanceProvider = Provider.of<AttendanceProvider>(context);
    final classProvider = Provider.of<ClassProvider>(context);
    final saleProvider = Provider.of<SaleProvider>(context);
    final paymentProvider = Provider.of<PaymentProvider>(context);

    final today = DateTime.now();
    
    // LOGIC
    final activeMembers = membershipProvider.memberships
        .where((m) =>
            m.membership.status == "Active" &&
            m.membership.endDate.isAfter(DateTime.now()))
        .length;

    final todaySales = saleProvider.sales
        .where((s) =>
            s.sale.saleDate.day == today.day &&
            s.sale.saleDate.month == today.month &&
            s.sale.saleDate.year == today.year)
        .fold(0.0, (sum, s) => sum + s.sale.totalAmount);

    final todayPayments = paymentProvider.payments
        .where((p) =>
            p.payment.paymentDate.day == today.day &&
            p.payment.paymentDate.month == today.month &&
            p.payment.paymentDate.year == today.year)
        .fold(0.0, (sum, p) => sum + p.payment.amount);

    final todayAttendance = attendanceProvider.attendanceRecords
        .where((a) =>
            a.attendance.checkinTime.day == today.day &&
            a.attendance.checkinTime.month == today.month &&
            a.attendance.checkinTime.year == today.year)
        .length;

    final todayWalkInRevenue = attendanceProvider.attendanceRecords
        .where((a) =>
            a.attendance.amountPaid > 0 &&
            a.attendance.date.day == today.day)
        .fold(0.0, (sum, a) => sum + a.attendance.amountPaid);
        final todayClasses = classProvider.classes.where((c) {
  final dt = c.gymClass.scheduleTime;
  return dt.year == today.year &&
         dt.month == today.month &&
         dt.day == today.day;
}).length;


    final totalRevenue = todaySales + todayPayments + todayWalkInRevenue;

    return Scaffold(
      backgroundColor: _bgColor,

      // ------------------ APP BAR ------------------
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        toolbarHeight: 80,
        titleSpacing: 18,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Hello, Admin 👋",
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Dashboard",
              style: TextStyle(
                color: Colors.grey[900],
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            color: Colors.grey[700],
            tooltip: "Settings",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            color: Colors.red[400],
            tooltip: "Logout",
            onPressed: () {
              Provider.of<AuthProvider>(context, listen: false).logout();
            },
          ),
          const SizedBox(width: 12),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: Colors.grey.withOpacity(0.08),
          ),
        ),
      ),

      // ------------------ BODY ------------------
      body: RefreshIndicator(
        color: _primaryColor,
        onRefresh: _refreshData,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 250),
          opacity: _isRefreshing ? 0.6 : 1,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_isRefreshing)
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: _primaryColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 10),
                          Text(
                            "Updating data...",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 18),

                // ------------------ REVENUE CARD ------------------
                _revenueCard(totalRevenue, todaySales, todayPayments,
                    todayWalkInRevenue),

                const SizedBox(height: 26),

                // ------------------ TODAY OVERVIEW ------------------
                Text(
                  "Today’s Overview",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: _statCard(
                          "Active Members",
                          "$activeMembers",
                          Icons.people_alt_rounded,
                          _primaryColor,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _statCard(
                          "Check-ins Today",
                          "$todayAttendance",
                          Icons.event_available,
                          Colors.green,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _statCard(
  "Today’s Classes",
  todayClasses.toString(),
  Icons.fitness_center,
  Colors.purple,
),

                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // ------------------ QUICK ACTIONS ------------------
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Quick Actions",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.grey[800],
                      ),
                    ),
                    Text(
                      "Today • ${DateFormat('MMM d').format(today)}",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: _quickActionsRow(context),
                ),

                const SizedBox(height: 28),

                // ------------------ MANAGEMENT GRID (kept) ------------------
                Text(
                  "Management",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 12),
                _managementGrid(context),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),

      // ------------------ BOTTOM NAV (kept) ------------------
      bottomNavigationBar: _bottomNav(context),
    );
  }

  // ------------------ REVENUE CARD ------------------
  Widget _revenueCard(
      double total, double sales, double payments, double walkins) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF11998e), Color(0xFF38ef7d)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.22),
            blurRadius: 20,
            offset: const Offset(0, 14),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.attach_money,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Today’s revenue",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      DateFormat('EEEE, MMM d').format(DateTime.now()),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.12),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.autorenew_rounded,
                    color: Colors.white.withOpacity(0.9),
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "Live",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 18),
          Text(
            NumberFormat.currency(locale: 'en_PH', symbol: '₱').format(total),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Total revenue today",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _revenueChip("Sales", sales),
              const SizedBox(width: 8),
              _revenueChip("Payments", payments),
              const SizedBox(width: 8),
              _revenueChip("Walk-ins", walkins),
            ],
          ),
        ],
      ),
    );
  }

  Widget _revenueChip(String label, double value) {
    return Expanded(
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(50),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 10,
                letterSpacing: 0.7,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              "₱${value.toStringAsFixed(0)}",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------ STAT CARD ------------------
  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20)),
        const SizedBox(height: 10),
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.grey[900],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          title,
          style: TextStyle(
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  // ------------------ QUICK ACTIONS ------------------
  Widget _quickActionsRow(BuildContext ctx) {
    Widget action(String label, IconData icon, Color color, String route) {
      return GestureDetector(
        onTap: () => Navigator.pushNamed(ctx, route),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, size: 30, color: color),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: 70,
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        action("New Member", Icons.person_add, _primaryColor,
            "/add_membership"),
        action("Check In", Icons.qr_code_scanner, Colors.green,
            "/attendance"),
        action("Book Class", Icons.calendar_month, Colors.purple,
            "/add_class_booking"),
        action("New Sale", Icons.shopping_cart, Colors.orange,
            "/add_sale"),
      ],
    );
  }

  // ------------------ MANAGEMENT GRID (kept) ------------------
  Widget _managementGrid(BuildContext context) {
    final items = [
      {"title": "Customers", "icon": Icons.people, "route": "/customers", "color": Colors.blue},
      {"title": "Plans", "icon": Icons.assignment, "route": "/membership_plans", "color": Colors.blue},
      {"title": "Memberships", "icon": Icons.card_membership, "route": "/memberships", "color": Colors.blue},

      {"title": "Check-Ins", "icon": Icons.qr_code, "route": "/attendance", "color": Colors.orange},
      {"title": "Classes", "icon": Icons.fitness_center, "route": "/classes", "color": Colors.orange},
      {"title": "Bookings", "icon": Icons.event_available, "route": "/class_bookings", "color": Colors.orange},

      {"title": "Trainers", "icon": Icons.sports, "route": "/trainers", "color": Colors.teal},
      {"title": "Trainer Pay", "icon": Icons.monetization_on, "route": "/trainer_payout", "color": Colors.teal},
      {"title": "PT Packages", "icon": Icons.confirmation_number, "route": "/trainer_packages", "color": Colors.teal},
      {"title": "PT Sessions", "icon": Icons.fitness_center, "route": "/pt_sessions", "color": Colors.teal},

      {"title": "Products", "icon": Icons.inventory_2, "route": "/products", "color": Colors.green},
      {"title": "Sales", "icon": Icons.point_of_sale, "route": "/sales", "color": Colors.green},
      {"title": "Payments", "icon": Icons.attach_money, "route": "/payments", "color": Colors.green},

      {"title": "Expenses", "icon": Icons.money_off, "route": "/expenses", "color": Colors.red},
      {"title": "Equipment", "icon": Icons.settings, "route": "/equipment", "color": Colors.grey},
      {"title": "About", "icon": Icons.info_outline, "route": "/about", "color": Colors.indigo},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      itemBuilder: (_, i) {
        final item = items[i];
        return GestureDetector(
          onTap: () => Navigator.pushNamed(context, item['route'] as String),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.grey.withOpacity(0.06),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (item['color'] as Color).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    item['icon'] as IconData,
                    color: item['color'] as Color,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item['title'] as String,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[900],
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  // ------------------ BOTTOM NAV (kept) ------------------
  Widget _bottomNav(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                context,
                icon: Icons.dashboard_rounded,
                label: "Home",
                isActive: true,
                route: "/dashboard",
              ),
              _buildNavItem(
                context,
                icon: Icons.people_alt_rounded,
                label: "Members",
                isActive: false,
                route: "/memberships",
              ),
              _buildNavItem(
                context,
                icon: Icons.receipt_long_rounded,
                label: "Expenses",
                isActive: false,
                route: "/expenses",
              ),
              _buildNavItem(
                context,
                icon: Icons.pie_chart_rounded,
                label: "Reports",
                isActive: false,
                route: "/finance_report",
              ),
              _buildNavItem(
                context,
                icon: Icons.info_outline,
                label: "About",
                isActive: false,
                route: "/about",
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isActive,
    required String route,
  }) {
    final color = isActive ? _primaryColor : Colors.grey[500];

    return GestureDetector(
      onTap: () {
        if (!isActive) Navigator.pushNamed(context, route);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
