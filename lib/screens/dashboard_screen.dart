// lib/screens/dashboard_screen.dart - UPDATED CONTENT

import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Welcome to Jay\'s Fitness Gym!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              _buildDashboardButton(
                context,
                title: 'Manage Customers',
                icon: Icons.people,
                route: '/customers',
              ),
              _buildDashboardButton(
                context,
                title: 'Manage Plans',
                icon: Icons.fitness_center,
                route: '/membership_plans',
              ),
              _buildDashboardButton(
                context,
                title: 'Manage Memberships',
                icon: Icons.card_membership,
                route: '/memberships',
              ),
              _buildDashboardButton(
                context,
                title: 'Manage Trainers',
                icon: Icons.person_add_alt_1,
                route: '/trainers',
              ),
              _buildDashboardButton(
                context,
                title: 'Manage Classes',
                icon: Icons.assignment,
                route: '/classes',
              ),
              _buildDashboardButton(
                context,
                title: 'Manage Class Bookings',
                icon: Icons.event_available,
                route: '/class_bookings',
              ),
              _buildDashboardButton(
                context,
                title: 'Manage Product Categories',
                icon: Icons.category,
                route: '/product_categories',
              ),
              _buildDashboardButton(
                context,
                title: 'Manage Products',
                icon: Icons.shopping_bag,
                route: '/products',
              ),
              _buildDashboardButton(
                context,
                title: 'Manage Sales',
                icon: Icons.receipt_long,
                route: '/sales',
              ),
              _buildDashboardButton(
                context,
                title: 'Manage Payments',
                icon: Icons.payment,
                route: '/payments',
              ),
              // NEW Button for Attendance Management
              _buildDashboardButton(
                context,
                title: 'Manage Attendance',
                icon: Icons.check_circle_outline,
                route: '/attendance',
              ),
              const SizedBox(height: 20),
              Text('More modules coming soon...', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardButton(BuildContext context, {required String title, required IconData icon, required String route}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () {
            Navigator.pushNamed(context, route);
          },
          icon: Icon(icon, size: 28),
          label: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(title, style: const TextStyle(fontSize: 18)),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 15),
            elevation: 5,
          ),
        ),
      ),
    );
  }
}