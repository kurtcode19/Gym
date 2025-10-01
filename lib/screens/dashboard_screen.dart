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

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final customerProvider = Provider.of<CustomerProvider>(context);
    final membershipProvider = Provider.of<MembershipProvider>(context);
    final attendanceProvider = Provider.of<AttendanceProvider>(context);
    final classProvider = Provider.of<ClassProvider>(context);
    final saleProvider = Provider.of<SaleProvider>(context);
    final paymentProvider = Provider.of<PaymentProvider>(context);
    final equipmentProvider = Provider.of<EquipmentProvider>(context);

    // Dynamic values
    final activeMembersCount = membershipProvider.memberships
        .where((m) => m.membership.status == 'Active' &&
            m.membership.endDate.isAfter(DateTime.now()))
        .length;

    final today = DateTime.now();
    final todaySales = saleProvider.sales.where((s) =>
        s.sale.saleDate.year == today.year &&
        s.sale.saleDate.month == today.month &&
        s.sale.saleDate.day == today.day);

    final todayPayments = paymentProvider.payments.where((p) =>
        p.payment.paymentDate.year == today.year &&
        p.payment.paymentDate.month == today.month &&
        p.payment.paymentDate.day == today.day);

    final todaysRevenue = todaySales.fold(
            0.0, (sum, sale) => sum + sale.sale.totalAmount) +
        todayPayments.fold(0.0, (sum, payment) => sum + payment.payment.amount);

    final todayCheckins = attendanceProvider.attendanceRecords
        .where((a) =>
            a.attendance.checkinTime.year == today.year &&
            a.attendance.checkinTime.month == today.month &&
            a.attendance.checkinTime.day == today.day)
        .length;

    final todayClasses = classProvider.classes
        .where((c) =>
            c.gymClass.scheduleTime.year == today.year &&
            c.gymClass.scheduleTime.month == today.month &&
            c.gymClass.scheduleTime.day == today.day)
        .length;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Hi, Welcome Back 👋",
              style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w400),
            ),
            Text(
              "Jay's Fitness",
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800]),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            color: Colors.grey[700],
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Notifications (TODO)")));
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            color: Colors.grey[700],
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Settings (TODO)")));
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            color: Colors.redAccent,
            tooltip: "Logout",
            onPressed: () {
              Provider.of<AuthProvider>(context, listen: false).logout();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text("Logged out successfully.")));
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
// ---- STATS CARDS ----
Column(
  children: [
    // Highlighted Profit Card
    Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color.fromARGB(255, 65, 182, 71), const Color.fromARGB(255, 40, 122, 106)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),

              ),

            ],
          ),
          const SizedBox(height: 18),
          Text(
            NumberFormat.currency(symbol: "₱").format(todaysRevenue),
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Today's Revenue",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "${todaySales.length} sales, ${todayPayments.length} payments",
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    ),
    const SizedBox(height: 16),

    // Row with 3 cards below
    Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: "Active Members",
            value: activeMembersCount.toString(),
            icon: Icons.people,
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            title: "Check-ins Today",
            value: todayCheckins.toString(),
            icon: Icons.check_circle,
            color: Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            title: "Classes Today",
            value: todayClasses.toString(),
            icon: Icons.event_note,
            color: Colors.purple,
          ),
        ),
      ],
    ),
  ],
),

            // ---- QUICK ACTIONS ----
            Text("Quick Actions",
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 4,
              crossAxisSpacing: 10,
              mainAxisSpacing: 12,
              children: [
                _buildQuickAction(context,
                    "Add Member", Icons.person_add, Colors.blue, "/add_membership"),
                _buildQuickAction(context,
                    "Check In", Icons.login, Colors.green, "/add_attendance"),
                _buildQuickAction(context,
                    "Book Class", Icons.event, Colors.purple, "/add_class_booking"),
                _buildQuickAction(context,
                    "Record Sale", Icons.shopping_cart, Colors.orange, "/add_sale"),
              ],
            ),

            const SizedBox(height: 28),



            // ---- MANAGEMENT ----
            Text("Management",
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            _buildManagementGrid(context),
          ],
        ),
      ),

      // ---- BOTTOM NAV ----
bottomNavigationBar: Container(
  decoration: BoxDecoration(
    color: Colors.white,
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: 20,
        offset: const Offset(0, -5),
      ),
    ],
  ),
  child: SafeArea(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            context,
            icon: Icons.dashboard_rounded,
            label: "Dashboard",
            isActive: true,
            route: "/dashboard",
          ),
          _buildNavItem(
            context,
            icon: Icons.people_rounded,
            label: "Members",
            isActive: false,
            route: "/memberships",
          ),
          _buildNavItem(
            context,
            icon: Icons.money_off,
            label: "Expenses",
            isActive: false,
            route: "/expenses",
          ),
          _buildNavItem(
            context,
            icon: Icons.pie_chart,
            label: "Report",
            isActive: false,
            route: "/finance_report",
          ),
        ],
      ),
    ),
  ),
)
    );
  }
  Widget _buildNavItem(BuildContext context,
      {required IconData icon,
      required String label,
      required bool isActive,
      required String route}) {
    final color = isActive ? Colors.blue : Colors.grey[600];
    return GestureDetector(
      onTap: () {
        if (!isActive) {
          Navigator.pushNamed(context, route);
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  color: color,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400)),
        ],
      ),
    );
  }
  // ---- CUSTOM WIDGETS ----
  Widget _buildStatCard(
      {required String title,
      required String value,
      required IconData icon,
      required Color color}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.15), color.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 20),
            ),
            const Spacer(),
            Icon(Icons.more_vert, color: Colors.grey[400]),
          ],
        ),
        const SizedBox(height: 16),
        Text(value,
            style: TextStyle(
                fontSize: 26, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 6),
        Text(title,
            style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ]),
    );
  }

  Widget _buildQuickAction(BuildContext context, String title, IconData icon,
      Color color, String route) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, route),
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 28, color: color),
              const SizedBox(height: 6),
              Text(title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: color)),
            ]),
      ),
    );
  }

 
  Widget _buildManagementGrid(BuildContext context) {
    final items = [
      {"title": "Customers", "icon": Icons.people, "route": "/customers"},
      {"title": "Plans", "icon": Icons.fitness_center, "route": "/membership_plans"},
      {"title": "Memberships", "icon": Icons.card_membership, "route": "/memberships"},
      {"title": "Attendance", "icon": Icons.shopping_bag, "route": "/attendance"},
      {"title": "Trainers", "icon": Icons.person, "route": "/trainers"},
      {"title": "Classes", "icon": Icons.assignment, "route": "/classes"},
      {"title": "Bookings", "icon": Icons.event, "route": "/class_bookings"},
      {"title": "Category", "icon": Icons.category, "route": "/product_categories"},
      {"title": "Sales", "icon": Icons.receipt, "route": "/sales"},
      {"title": "Payments", "icon": Icons.payment, "route": "/payments"},
      {"title": "Expenses", "icon": Icons.money_off, "route": "/expenses"},
      {"title": "Reports", "icon": Icons.pie_chart, "route": "/finance_report"},
      {"title": "Equipment", "icon": Icons.fitness_center_outlined, "route": "/equipment"},
      {"title": "Products", "icon": Icons.shopping_bag, "route": "/products"},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.3,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final item = items[i];
        return GestureDetector(
          onTap: () => Navigator.pushNamed(context, item["route"] as String),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 2))
                ]),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(item["icon"] as IconData,
                      size: 28, color: Colors.blueGrey),
                  const SizedBox(height: 10),
                  Text(item['title']! as String, textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 10, fontWeight: FontWeight.w600)),
                ]),
          ),
        );
      },
    );
  }
}
