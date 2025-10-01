// lib/main.dart - UPDATED CONTENT

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

// Database helper and providers
import 'package:gym/providers/database_helper.dart';
import 'package:gym/providers/customer_provider.dart';
import 'package:gym/providers/membership_plan_provider.dart';
import 'package:gym/providers/membership_provider.dart';
import 'package:gym/providers/attendance_provider.dart';
import 'package:gym/providers/trainer_provider.dart';
import 'package:gym/providers/class_provider.dart';
import 'package:gym/providers/class_booking_provider.dart';
import 'package:gym/providers/product_category_provider.dart';
import 'package:gym/providers/product_provider.dart';
import 'package:gym/providers/sale_provider.dart';
import 'package:gym/providers/payment_provider.dart';
import 'package:gym/providers/expense_provider.dart';
import 'package:gym/providers/equipment_provider.dart'; // NEW

// Screens
import 'package:gym/screens/customers_screen.dart';
import 'package:gym/screens/add_customer_screen.dart';
import 'package:gym/screens/membership_plans_screen.dart';
import 'package:gym/screens/add_membership_plan_screen.dart';
import 'package:gym/screens/memberships_screen.dart';
import 'package:gym/screens/add_membership_screen.dart';
import 'package:gym/screens/trainers_screen.dart';
import 'package:gym/screens/add_trainer_screen.dart';
import 'package:gym/screens/classes_screen.dart';
import 'package:gym/screens/add_class_screen.dart';
import 'package:gym/screens/class_bookings_screen.dart';
import 'package:gym/screens/add_class_booking_screen.dart';
import 'package:gym/screens/product_categories_screen.dart';
import 'package:gym/screens/add_product_category_screen.dart';
import 'package:gym/screens/products_screen.dart';
import 'package:gym/screens/add_product_screen.dart';
import 'package:gym/screens/sales_screen.dart';
import 'package:gym/screens/add_sale_screen.dart';
import 'package:gym/screens/payments_screen.dart';
import 'package:gym/screens/add_payment_screen.dart';
import 'package:gym/screens/attendance_screen.dart';
import 'package:gym/screens/add_attendance_screen.dart';
import 'package:gym/screens/expenses_screen.dart';
import 'package:gym/screens/add_expense_screen.dart';
import 'package:gym/screens/finance_report_screen.dart';
import 'package:gym/screens/equipment_screen.dart'; // NEW
import 'package:gym/screens/add_equipment_screen.dart'; // NEW
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
        ChangeNotifierProvider(create: (_) => CustomerProvider(DatabaseHelper())),
        ChangeNotifierProvider(create: (_) => MembershipPlanProvider(DatabaseHelper())),
        ChangeNotifierProvider(create: (_) => MembershipProvider(DatabaseHelper())),
        ChangeNotifierProvider(create: (_) => AttendanceProvider(DatabaseHelper())),
        ChangeNotifierProvider(create: (_) => TrainerProvider(DatabaseHelper())),
        ChangeNotifierProvider(create: (_) => ClassProvider(DatabaseHelper())),
        ChangeNotifierProvider(create: (_) => ClassBookingProvider(DatabaseHelper())),
        ChangeNotifierProvider(create: (_) => ProductCategoryProvider(DatabaseHelper())),
        ChangeNotifierProvider(create: (_) => ProductProvider(DatabaseHelper())),
        ChangeNotifierProvider(create: (_) => SaleProvider(DatabaseHelper())),
        ChangeNotifierProvider(create: (_) => PaymentProvider(DatabaseHelper())),
        ChangeNotifierProvider(create: (_) => ExpenseProvider(DatabaseHelper())),
        // NEW Provider for Equipment Management
        ChangeNotifierProvider(create: (_) => EquipmentProvider(DatabaseHelper())),
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
            contentPadding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
          ),
          cardTheme: CardThemeData(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepOrange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              textStyle: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.blueGrey).copyWith(secondary: Colors.amber),
        ),
        // Define initial routes
        initialRoute: '/',
        routes: {
          '/': (context) => const DashboardScreen(),
          '/customers': (context) => const CustomersScreen(),
          '/add_customer': (context) => const AddCustomerScreen(),
          '/membership_plans': (context) => const MembershipPlansScreen(),
          '/add_membership_plan': (context) => const AddMembershipPlanScreen(),
          '/memberships': (context) => const MembershipsScreen(),
          '/add_membership': (context) => const AddMembershipScreen(),
          '/trainers': (context) => const TrainersScreen(),
          '/add_trainer': (context) => const AddTrainerScreen(),
          '/classes': (context) => const ClassesScreen(),
          '/add_class': (context) => const AddClassScreen(),
          '/class_bookings': (context) => const ClassBookingsScreen(),
          '/add_class_booking': (context) => const AddClassBookingScreen(),
          '/product_categories': (context) => const ProductCategoriesScreen(),
          '/add_product_category': (context) => const AddProductCategoryScreen(),
          '/products': (context) => const ProductsScreen(),
          '/add_product': (context) => const AddProductScreen(),
          '/sales': (context) => const SalesScreen(),
          '/add_sale': (context) => const AddSaleScreen(),
          '/payments': (context) => const PaymentsScreen(),
          '/add_payment': (context) => const AddPaymentScreen(),
          '/attendance': (context) => const AttendanceScreen(),
          '/add_attendance': (context) => const AddAttendanceScreen(),
          '/expenses': (context) => const ExpensesScreen(),
          '/add_expense': (context) => const AddExpenseScreen(),
          '/finance_report': (context) => const FinanceReportScreen(),
          // NEW Routes for Equipment Management
          '/equipment': (context) => const EquipmentScreen(),
          '/add_equipment': (context) => const AddEquipmentScreen(),
        },
      ),
    );
  }
}