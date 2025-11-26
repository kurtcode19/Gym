// lib/screens/dashboard_screen.dart - Modern UI/UX Enhanced
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

// Import providers
import 'package:gym/providers/customer_provider.dart';
import 'package:gym/providers/membership_provider.dart';
import 'package:gym/providers/attendance_provider.dart';
import 'package:gym/providers/class_provider.dart';
import 'package:gym/providers/sale_provider.dart';
import 'package:gym/providers/payment_provider.dart';
import 'package:gym/providers/equipment_provider.dart';
import 'package:gym/auth/auth_provider.dart';

// Import Service and Settings for Backup
import 'package:gym/services/backup_service.dart';
import 'package:gym/screens/settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  
  @override
  void initState() {
    super.initState();
    // Check for backup reminder after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkBackupReminder();
      _refreshData(); // Auto-refresh data on load as well
    });
  }

  // --- BACKUP REMINDER LOGIC ---
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
          duration: const Duration(seconds: 10), // Stay visible longer
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: "Backup Now",
            textColor: Colors.white,
            onPressed: () {
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (context) => const SettingsScreen())
              );
            },
          ),
        ),
      );
    }
  }

  // --- DATA REFRESH LOGIC ---
  Future<void> _refreshData() async {
    // Trigger fetches for all providers to ensure data is up to date
    final context = this.context; // Capture context
    Provider.of<MembershipProvider>(context, listen: false).fetchMemberships();
    Provider.of<AttendanceProvider>(context, listen: false).fetchAttendanceRecords();
    Provider.of<SaleProvider>(context, listen: false).fetchSales();
    Provider.of<PaymentProvider>(context, listen: false).fetchPayments();
    Provider.of<ClassProvider>(context, listen: false).fetchGymClasses();
    // Ensure these are loaded
    Provider.of<CustomerProvider>(context, listen: false).fetchCustomers();
    Provider.of<EquipmentProvider>(context, listen: false).fetchEquipment();
  }

  @override
  Widget build(BuildContext context) {
    // Access Providers
    final membershipProvider = Provider.of<MembershipProvider>(context);
    final attendanceProvider = Provider.of<AttendanceProvider>(context);
    final classProvider = Provider.of<ClassProvider>(context);
    final saleProvider = Provider.of<SaleProvider>(context);
    final paymentProvider = Provider.of<PaymentProvider>(context);
    
    // --- LOGIC SECTION ---
    final today = DateTime.now();

    // 1. Active Members
    final activeMembersCount = membershipProvider.memberships
        .where((m) => m.membership.status == 'Active' &&
            m.membership.endDate.isAfter(DateTime.now()))
        .length;

    // 2. Today's Sales
    final todaySales = saleProvider.sales.where((s) =>
        s.sale.saleDate.year == today.year &&
        s.sale.saleDate.month == today.month &&
        s.sale.saleDate.day == today.day);
    final todaySalesTotal = todaySales.fold(0.0, (sum, sale) => sum + sale.sale.totalAmount);

    // 3. Today's Membership Payments
    final todayPayments = paymentProvider.payments.where((p) =>
        p.payment.paymentDate.year == today.year &&
        p.payment.paymentDate.month == today.month &&
        p.payment.paymentDate.day == today.day);
    final todayPaymentsTotal = todayPayments.fold(0.0, (sum, p) => sum + p.payment.amount);

    // 4. Today's Walk-Ins & Revenue
    final todayAttendance = attendanceProvider.attendanceRecords.where((a) =>
        a.attendance.checkinTime.year == today.year &&
        a.attendance.checkinTime.month == today.month &&
        a.attendance.checkinTime.day == today.day
    ).toList();
    
    final todayWalkInRevenue = todayAttendance.fold(0.0, (sum, item) => sum + item.attendance.amountPaid);

    // 5. Total Revenue
    final todaysRevenue = todaySalesTotal + todayPaymentsTotal + todayWalkInRevenue;

    // 6. Today's Classes
    final todayClasses = classProvider.classes
        .where((c) =>
            c.gymClass.scheduleTime.year == today.year &&
            c.gymClass.scheduleTime.month == today.month &&
            c.gymClass.scheduleTime.day == today.day)
        .length;
    
    // NEW: PopScope prevents going back to Login screen when swiping back on Dashboard
    return PopScope(
      canPop: false, 
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          toolbarHeight: 70,
          // This ensures no back button is shown on the Dashboard itself
          automaticallyImplyLeading: false, 
          
          // Home/Refresh Button
          leading: Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.refresh_rounded, color: Colors.blue),
                tooltip: "Refresh Data",
                onPressed: _refreshData,
              ),
            ),
          ),
          
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Welcome Back, Admin 👋",
                style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              Text(
                "Jay's Fitness",
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[900]),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              color: Colors.grey[800],
              iconSize: 24,
              tooltip: "Settings",
              onPressed: () {
                Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (context) => const SettingsScreen())
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.logout_rounded),
              color: Colors.red[400],
              iconSize: 24,
              tooltip: "Logout",
              onPressed: () {
                // Handle logout
                Provider.of<AuthProvider>(context, listen: false).logout();
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _refreshData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ---- REVENUE CARD ----
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF11998e), Color(0xFF38ef7d)], 
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF38ef7d).withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.attach_money, color: Colors.white, size: 24),
                          ),
                          Text(
                            DateFormat('MMM d, yyyy').format(today),
                            style: TextStyle(color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.w500),
                          )
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        NumberFormat.currency(locale: 'en_PH', symbol: '₱').format(todaysRevenue),
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Total Revenue Today",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Divider(color: Colors.white.withOpacity(0.3)),
                      const SizedBox(height: 4),
                      // Breakdown Text
                      Text(
                        "Sales: ${NumberFormat.compact().format(todaySalesTotal)} • Payments: ${NumberFormat.compact().format(todayPaymentsTotal)} • Walk-ins: ${NumberFormat.compact().format(todayWalkInRevenue)}",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),

                // ---- KEY STATS ROW ----
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        title: "Active\nMembers",
                        value: activeMembersCount.toString(),
                        icon: Icons.groups_rounded,
                        color: Colors.blueAccent,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        title: "Check-ins\nToday",
                        value: todayAttendance.length.toString(),
                        icon: Icons.fact_check_rounded,
                        color: Colors.orangeAccent,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        title: "Classes\nToday",
                        value: todayClasses.toString(),
                        icon: Icons.fitness_center_rounded,
                        color: Colors.purpleAccent,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // ---- QUICK ACTIONS ----
                Text("Quick Actions",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800])),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildQuickAction(context, "New Member", Icons.person_add_rounded, Colors.blue, "/add_membership"),
                    _buildQuickAction(context, "Check In", Icons.qr_code_scanner_rounded, Colors.green, "/attendance"),
                    _buildQuickAction(context, "Book Class", Icons.calendar_month_rounded, Colors.purple, "/add_class_booking"),
                    _buildQuickAction(context, "New Sale", Icons.shopping_cart_rounded, Colors.orange, "/add_sale"),
                  ],
                ),

                const SizedBox(height: 28),

                // ---- MANAGEMENT GRID ----
                Text("Management",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800])),
                const SizedBox(height: 16),
                _buildManagementGrid(context),
                
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
        
        // ---- BOTTOM NAVIGATION ----
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(context, icon: Icons.dashboard_rounded, label: "Home", isActive: true, route: "/dashboard"),
                  _buildNavItem(context, icon: Icons.people_alt_rounded, label: "Members", isActive: false, route: "/memberships"),
                  _buildNavItem(context, icon: Icons.receipt_long_rounded, label: "Expenses", isActive: false, route: "/expenses"),
                  _buildNavItem(context, icon: Icons.pie_chart_rounded, label: "Reports", isActive: false, route: "/finance_report"),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---- WIDGET BUILDERS ----

  Widget _buildStatCard({required String title, required String value, required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 12),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.grey[800])),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey[500], height: 1.2)),
        ],
      ),
    );
  }

  Widget _buildQuickAction(BuildContext context, String title, IconData icon, Color color, String route) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, route),
      child: Column(
        children: [
          Container(
            width: 65,
            height: 65,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey[700]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildManagementGrid(BuildContext context) {
    final items = [
      {"title": "Members", "icon": Icons.people, "route": "/customers", "color": Colors.blue},
      {"title": "Plans", "icon": Icons.assignment, "route": "/membership_plans", "color": Colors.blue},
      {"title": "Memberships", "icon": Icons.card_membership, "route": "/memberships", "color": Colors.blue},
      
      {"title": "Check-Ins", "icon": Icons.qr_code, "route": "/attendance", "color": Colors.orange},
      {"title": "Classes", "icon": Icons.fitness_center, "route": "/classes", "color": Colors.orange},
      {"title": "Bookings", "icon": Icons.event_available, "route": "/class_bookings", "color": Colors.orange},
      {"title": "Trainers", "icon": Icons.sports, "route": "/trainers", "color": Colors.orange},

      {"title": "Products", "icon": Icons.inventory_2, "route": "/products", "color": Colors.green},
      {"title": "Sales", "icon": Icons.point_of_sale, "route": "/sales", "color": Colors.green},
      {"title": "Payments", "icon": Icons.attach_money, "route": "/payments", "color": Colors.green},
      
      {"title": "Expenses", "icon": Icons.money_off, "route": "/expenses", "color": Colors.red},
      {"title": "Equipment", "icon": Icons.fitness_center, "route": "/equipment", "color": Colors.grey},
      // In _buildManagementGrid items list:
{
  "title": "Trainer Pay", 
  "icon": Icons.payments_rounded, 
  "route": "/trainer_payout", // Register this route in main.dart
  "color": Colors.teal
},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.1,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final item = items[i];
        final color = item["color"] as Color;
        return GestureDetector(
          onTap: () => Navigator.pushNamed(context, item["route"] as String),
          child: Container(
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 3))
                ]),
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      shape: BoxShape.circle
                    ),
                    child: Icon(item["icon"] as IconData, size: 24, color: color),
                  ),
                  const SizedBox(height: 10),
                  Text(item['title']! as String, textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[800])),
                ]),
          ),
        );
      },
    );
  }

  Widget _buildNavItem(BuildContext context, {required IconData icon, required String label, required bool isActive, required String route}) {
    final color = isActive ? Colors.black87 : Colors.grey[400];
    return GestureDetector(
      onTap: () {
        if (!isActive) {
          // Uses pushNamed to allow back button navigation on destination screens
          Navigator.pushNamed(context, route); 
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: isActive ? FontWeight.w700 : FontWeight.w500)),
        ],
      ),
    );
  }
}