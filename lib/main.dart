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
import 'package:gym/providers/equipment_provider.dart';
import 'package:gym/providers/trainer_package_provider.dart'; // 1. NEW IMPORT

// Auth system
import 'package:gym/auth/auth_service.dart';
import 'package:gym/auth/auth_provider.dart';

// Screens
import 'package:gym/screens/customers_screen.dart';
import 'package:gym/screens/add_customer_screen.dart';
import 'package:gym/screens/membership_plans_screen.dart';
import 'package:gym/screens/add_membership_plan_screen.dart';
import 'package:gym/screens/memberships_screen.dart';
import 'package:gym/screens/add_membership_screen.dart';
import 'package:gym/screens/trainers_screen.dart';
import 'package:gym/screens/trainer_payout_screen.dart';
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
import 'package:gym/screens/equipment_screen.dart';
import 'package:gym/screens/add_equipment_screen.dart';
import 'package:gym/screens/dashboard_screen.dart';
import 'package:gym/screens/trainer_packages_screen.dart'; 

// Auth Screens
import 'package:gym/screens/auth/onboarding_screen.dart';
import 'package:gym/screens/auth/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final databaseHelper = DatabaseHelper(); 

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CustomerProvider(databaseHelper)),
        ChangeNotifierProvider(create: (_) => MembershipPlanProvider(databaseHelper)),
        ChangeNotifierProvider(create: (_) => MembershipProvider(databaseHelper)),
        ChangeNotifierProvider(create: (_) => AttendanceProvider(databaseHelper)),
        ChangeNotifierProvider(create: (_) => TrainerProvider(databaseHelper)),
        
        // 2. REGISTER NEW PROVIDER
        ChangeNotifierProvider(create: (_) => TrainerPackageProvider(databaseHelper)), 
        
        ChangeNotifierProvider(create: (_) => ClassProvider(databaseHelper)),
        ChangeNotifierProvider(create: (_) => ClassBookingProvider(databaseHelper)),
        ChangeNotifierProvider(create: (_) => ProductCategoryProvider(databaseHelper)),
        ChangeNotifierProvider(create: (_) => ProductProvider(databaseHelper)),
        ChangeNotifierProvider(create: (_) => SaleProvider(databaseHelper)),
        
        ChangeNotifierProxyProvider<MembershipProvider, PaymentProvider>(
          create: (context) => PaymentProvider(databaseHelper, Provider.of<MembershipProvider>(context, listen: false)),
          update: (context, membershipProvider, paymentProvider) {
            return paymentProvider ?? PaymentProvider(databaseHelper, membershipProvider);
          },
        ),
        ChangeNotifierProvider(create: (_) => ExpenseProvider(databaseHelper)),
        ChangeNotifierProvider(create: (_) => EquipmentProvider(databaseHelper)),
        ChangeNotifierProvider(create: (_) => AuthProvider(AuthService())),
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
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
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
            hintStyle: TextStyle(color: Colors.grey[400]),
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
        home: Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            if (authProvider.isLoading) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            } else if (!authProvider.isOnboarded) {
              return const OnboardingScreen();
            } else if (!authProvider.isAuthenticated) {
              return const LoginScreen();
            } else {
              return const DashboardScreen();
            }
          },
        ),
        routes: {
          '/onboarding': (context) => const OnboardingScreen(),
          '/login': (context) => const LoginScreen(),
          '/dashboard': (context) => const DashboardScreen(),

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
          '/product_categories': (context) => const ProductCategoriesScreen(), // Fixed type
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
          '/equipment': (context) => const EquipmentScreen(),
          '/add_equipment': (context) => const AddEquipmentScreen(),
          
          // 3. ENSURE ROUTES ARE REGISTERED
          '/trainer_payout': (context) => const TrainerPayoutScreen(),  
          '/trainer_packages': (context) => const TrainerPackagesScreen(),
        },
      ),
    );
  }
}