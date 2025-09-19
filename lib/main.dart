import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: GymDashboard(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class GymDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Jay\'s Fitness'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(icon: Icon(Icons.notifications), onPressed: () {}),
          IconButton(icon: Icon(Icons.settings), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          // Stats Section
     Padding(
  padding: const EdgeInsets.all(5.0),
  child: ClipRRect(
    borderRadius: BorderRadius.circular(4.0), // Optional: Add rounded corners if desired
    child: Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            children: [
              _buildStatCard('Active Members', '142', Colors.green[100]!),
              _buildStatCard('Today\'s Revenue', '\$3,450', Colors.green[50]!),
            ],
          ),
          Row(
            children: [
              _buildStatCard('Check-ins Today', '67', Colors.orange[50]!),
              _buildStatCard('Classes Today', '8', Colors.purple[50]!),
            ],
          ),
        ],
      ),
    ),
  ),
),
          // Quick Actions Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildActionButton('Add Member', Icons.person_add, Colors.blue),
              _buildActionButton('Check In', Icons.check_circle, Colors.green),
              _buildActionButton('Book Class', Icons.calendar_today, Colors.purple),
              _buildActionButton('Record Sale', Icons.shopping_cart, Colors.orange),
            ],
          ),
          // Recent Activity Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Recent Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ListTile(
                  leading: CircleAvatar(child: Icon(Icons.person)),
                  title: Text('Maria Santos joined'),
                  subtitle: Text('2 minutes ago'),
                ),
              ],
            ),
          ),
          // Navigation
          BottomNavigationBar(
            items: [
              BottomNavigationBarItem(icon: Icon(Icons.home, color: Colors.blue ,), label: 'Dashboard'),
              BottomNavigationBarItem(icon: Icon(Icons.people, color: Colors.blue), label: 'Members'),
              BottomNavigationBarItem(icon: Icon(Icons.check_circle, color: Colors.blue), label: 'Attendance'),
              BottomNavigationBarItem(icon: Icon(Icons.calendar_today, color: Colors.blue), label: 'Classes'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Card(
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(title, style: TextStyle(fontSize: 16)),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(backgroundColor: color),
      onPressed: () {},
      child: Column(
        children: [
          Icon(icon),
          Text(label),
        ],
      ),
    );
  }
}