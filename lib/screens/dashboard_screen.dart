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
        child: SingleChildScrollView( // Use SingleChildScrollView for more buttons
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
              // NEW Buttons for Trainer & Class Management
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