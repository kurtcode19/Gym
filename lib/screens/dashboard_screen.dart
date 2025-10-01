// lib/screens/dashboard_screen.dart - Modern UI Design - UPDATED CONTENT

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

// Import providers to fetch dynamic data
import 'package:gym/providers/customer_provider.dart';
import 'package:gym/providers/membership_provider.dart';
import 'package:gym/providers/attendance_provider.dart';
import 'package:gym/providers/class_provider.dart';
import 'package:gym/providers/sale_provider.dart';
import 'package:gym/providers/payment_provider.dart';
import 'package:gym/providers/equipment_provider.dart'; // NEW


class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Watch providers to get current state for dynamic stats
    final customerProvider = Provider.of<CustomerProvider>(context);
    final membershipProvider = Provider.of<MembershipProvider>(context);
    final attendanceProvider = Provider.of<AttendanceProvider>(context);
    final classProvider = Provider.of<ClassProvider>(context);
    final saleProvider = Provider.of<SaleProvider>(context);
    final paymentProvider = Provider.of<PaymentProvider>(context);
    final equipmentProvider = Provider.of<EquipmentProvider>(context); // NEW

    // Dynamic Stats Calculation
    final activeMembersCount = membershipProvider.memberships
        .where((m) => m.membership.status == 'Active' && m.membership.endDate.isAfter(DateTime.now()))
        .length;

    final today = DateTime.now();
    final todaySales = saleProvider.sales.where(
      (s) => s.sale.saleDate.year == today.year &&
             s.sale.saleDate.month == today.month &&
             s.sale.saleDate.day == today.day,
    );
    final todayPayments = paymentProvider.payments.where(
      (p) => p.payment.paymentDate.year == today.year &&
             p.payment.paymentDate.month == today.month &&
             p.payment.paymentDate.day == today.day,
    );
    final todaysRevenue = todaySales.fold(0.0, (sum, sale) => sum + sale.sale.totalAmount) +
                         todayPayments.fold(0.0, (sum, payment) => sum + payment.payment.amount);


    final todayCheckins = attendanceProvider.attendanceRecords.where(
      (a) => a.attendance.checkinTime.year == today.year &&
             a.attendance.checkinTime.month == today.month &&
             a.attendance.checkinTime.day == today.day,
    ).length;

    final todayClasses = classProvider.classes.where(
      (c) => c.gymClass.scheduleTime.year == today.year &&
             c.gymClass.scheduleTime.month == today.month &&
             c.gymClass.scheduleTime.day == today.day,
    ).length;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Jay\'s Fitness',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            Text(
              'Gym Management',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: Icon(Icons.notifications_outlined, color: Colors.grey[700]),
                onPressed: () {
                  // TODO: Implement notifications logic
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Notifications (TODO)')),
                  );
                },
              ),
              Positioned(
                right: 11,
                top: 11,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 14,
                    minHeight: 14,
                  ),
                ),
              ),
            ],
          ),
          IconButton(
            icon: Icon(Icons.settings_outlined, color: Colors.grey[700]),
            onPressed: () {
              // TODO: Implement settings logic
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings (TODO)')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Statistics Cards
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: 'Active Members',
                    value: activeMembersCount.toString(), // Dynamic
                    icon: Icons.people_outline,
                    color: Colors.blue[100]!,
                    iconColor: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    title: 'Today\'s Revenue',
                    value: NumberFormat.currency(symbol: '₱').format(todaysRevenue), // Dynamic
                    icon: Icons.attach_money,
                    color: Colors.green[100]!,
                    iconColor: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: 'Check-ins Today',
                    value: todayCheckins.toString(), // Dynamic
                    icon: Icons.check_circle_outline,
                    color: Colors.orange[100]!,
                    iconColor: Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    title: 'Classes Today',
                    value: todayClasses.toString(), // Dynamic
                    icon: Icons.event_note,
                    color: Colors.purple[100]!,
                    iconColor: Colors.purple,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Quick Actions Section
            Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildQuickActionButton(
                    context,
                    title: 'Add Member',
                    icon: Icons.person_add,
                    color: Colors.blue,
                    route: '/add_customer',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionButton(
                    context,
                    title: 'Check In',
                    icon: Icons.check_circle,
                    color: Colors.green,
                    route: '/add_attendance',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionButton(
                    context,
                    title: 'Book Class',
                    icon: Icons.event,
                    color: Colors.purple,
                    route: '/add_class_booking',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionButton(
                    context,
                    title: 'Record Sale',
                    icon: Icons.shopping_cart,
                    color: Colors.orange,
                    route: '/add_sale',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Recent Activity Section
            Text(
              'Recent Activity',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 16),
            // TODO: Replace with dynamic fetching of recent activities (e.g., last 3 customers, attendance, bookings)
            _buildActivityItem(
              name: 'New customer signed up',
              time: '2 minutes ago',
              icon: Icons.person_add,
              color: Colors.blue,
            ),
            _buildActivityItem(
              name: 'Member checked in',
              time: '5 minutes ago',
              icon: Icons.check_circle,
              color: Colors.green,
            ),
            _buildActivityItem(
              name: 'Class booking received',
              time: '10 minutes ago',
              icon: Icons.event,
              color: Colors.purple,
            ),
            _buildActivityItem(
              name: 'Product sale recorded',
              time: '15 minutes ago',
              icon: Icons.shopping_cart,
              color: Colors.orange,
            ),


            const SizedBox(height: 32),

            // All Management Options
            Text(
              'Management',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 16),

            _buildManagementGrid(context),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        currentIndex: 0, // Always start at dashboard
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Members',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle),
            label: 'Attendance',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment), // Changed to classes
            label: 'Classes',
          ),
        ],
        onTap: (index) {
          switch (index) {
            case 0: // Dashboard - already here
              break;
            case 1:
              Navigator.pushNamed(context, '/customers');
              break;
            case 2:
              Navigator.pushNamed(context, '/attendance');
              break;
            case 3:
              Navigator.pushNamed(context, '/classes'); // Changed to classes
              break;
          }
        },
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: iconColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: iconColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required String route,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () {
          Navigator.pushNamed(context, route);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 20),
          elevation: 0,
        ),
        child: Column(
          children: [
            Icon(icon, size: 24),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem({
    required String name,
    required String time,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 20,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManagementGrid(BuildContext context) {
    final managementItems = [
      {'title': 'Customers', 'icon': Icons.people, 'route': '/customers'},
      {'title': 'Plans', 'icon': Icons.fitness_center, 'route': '/membership_plans'},
      {'title': 'Memberships', 'icon': Icons.card_membership, 'route': '/memberships'},
      {'title': 'Trainers', 'icon': Icons.person_add_alt_1, 'route': '/trainers'},
      {'title': 'Classes', 'icon': Icons.assignment, 'route': '/classes'},
      {'title': 'Bookings', 'icon': Icons.event_available, 'route': '/class_bookings'},
      {'title': 'Categories', 'icon': Icons.category, 'route': '/product_categories'},
      {'title': 'Products', 'icon': Icons.shopping_bag, 'route': '/products'},
      {'title': 'Sales', 'icon': Icons.receipt_long, 'route': '/sales'},
      {'title': 'Payments', 'icon': Icons.payment, 'route': '/payments'},
      {'title': 'Attendance', 'icon': Icons.check_circle_outline, 'route': '/attendance'},
      {'title': 'Expenses', 'icon': Icons.money_off, 'route': '/expenses'},
      {'title': 'Finance Report', 'icon': Icons.pie_chart, 'route': '/finance_report'},
      {'title': 'Equipment', 'icon': Icons.fitness_center_outlined, 'route': '/equipment'}, // NEW
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.5,
      ),
      itemCount: managementItems.length,
      itemBuilder: (context, index) {
        final item = managementItems[index];
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.pushNamed(context, item['route'] as String);
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      item['icon'] as IconData,
                      size: 24,
                      color: Colors.grey[700],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item['title'] as String,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.grey[400],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}