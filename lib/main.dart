// lib/main.dart - UPDATED CONTENT

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

// Database helper and providers
import 'package:gym/providers/database_helper.dart';
import 'package:gym/providers/customer_provider.dart';
import 'package:gym/providers/membership_plan_provider.dart'; // NEW
import 'package:gym/providers/membership_provider.dart'; // NEW
//import 'package:gym/providers/attendance_provider.dart'; // Placeholder

// Screens
import 'package:gym/screens/customers_screen.dart';
import 'package:gym/screens/add_customer_screen.dart'; // NEW
import 'package:gym/screens/membership_plans_screen.dart'; // NEW
import 'package:gym/screens/add_membership_plan_screen.dart'; // NEW
import 'package:gym/screens/memberships_screen.dart'; // NEW
import 'package:gym/screens/add_membership_screen.dart'; // NEW
import 'package:gym/screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Provide the CustomerProvider instance
        ChangeNotifierProvider(
          create: (_) => CustomerProvider(DatabaseHelper()),
        ),
        // NEW: MembershipPlanProvider
        ChangeNotifierProvider(
          create: (_) => MembershipPlanProvider(DatabaseHelper()),
        ),
        // NEW: MembershipProvider
        ChangeNotifierProvider(
          create: (_) => MembershipProvider(DatabaseHelper()),
        ),
        // Placeholder for AttendanceProvider
        ChangeNotifierProvider(
          create: (_) => AttendanceProvider(DatabaseHelper()),
        ),
        // Add other providers here as they are implemented
      ],
      child: MaterialApp(
        title: 'Jay\'s Fitness Gym',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blueGrey,
          textTheme: GoogleFonts.poppinsTextTheme(
            Theme.of(context).textTheme,
          ),
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.blueGrey[900],
            foregroundColor: Colors.white,
            titleTextStyle: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          floatingActionButtonTheme: FloatingActionButtonThemeData(
            backgroundColor: Colors.deepOrange,
            foregroundColor: Colors.white,
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide(color: Colors.blueGrey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: const BorderSide(color: Colors.deepOrange, width: 2.0),
            ),
            labelStyle: TextStyle(color: Colors.blueGrey[700]),
            hintStyle: TextStyle(color: Colors.blueGrey[400]),
            contentPadding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0), // Consistent padding
          ),
          cardTheme: CardThemeData(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepOrange, // Primary action button color
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              textStyle: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        // Define initial routes
        initialRoute: '/',
        routes: {
          '/': (context) => const DashboardScreen(),
          '/customers': (context) => const CustomersScreen(),
          '/add_customer': (context) => const AddCustomerScreen(), // NEW
          '/membership_plans': (context) => const MembershipPlansScreen(), // NEW
          '/add_membership_plan': (context) => const AddMembershipPlanScreen(), // NEW
          '/memberships': (context) => const MembershipsScreen(), // NEW
          '/add_membership': (context) => const AddMembershipScreen(), // NEW
          // Add other screen routes here
        },
      ),
    );
  }
}

// Placeholder for AttendanceProvider (as it was in the original prompt)
class AttendanceProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper;
  AttendanceProvider(this._dbHelper);
  // ... (implement fetch, add, update, delete for Attendance)
}