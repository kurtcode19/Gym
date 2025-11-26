import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gym/providers/customer_provider.dart';
import 'package:gym/providers/membership_provider.dart';
import 'package:gym/providers/membership_plan_provider.dart';
import 'package:gym/providers/payment_provider.dart';
import 'package:gym/providers/attendance_provider.dart';
import 'package:gym/providers/class_provider.dart';
import 'package:gym/providers/class_booking_provider.dart';
import 'package:gym/providers/trainer_provider.dart';
import 'package:gym/providers/product_provider.dart';
import 'package:gym/providers/product_category_provider.dart';
import 'package:gym/providers/sale_provider.dart';
import 'package:gym/providers/expense_provider.dart';
import 'package:gym/providers/equipment_provider.dart';

class AppRefresher {
  /// Refreshes all providers in the app to ensure data consistency
  static Future<void> refreshAll(BuildContext context) async {
    // Use Future.wait to fetch them all in parallel for speed
    await Future.wait([
      Provider.of<CustomerProvider>(context, listen: false).fetchCustomers(),
      Provider.of<MembershipPlanProvider>(context, listen: false).fetchMembershipPlans(),
      Provider.of<MembershipProvider>(context, listen: false).fetchMemberships(),
      Provider.of<PaymentProvider>(context, listen: false).fetchPayments(),
      Provider.of<AttendanceProvider>(context, listen: false).fetchAttendanceRecords(),
      Provider.of<TrainerProvider>(context, listen: false).fetchTrainers(),
      Provider.of<ClassProvider>(context, listen: false).fetchGymClasses(),
      Provider.of<ClassBookingProvider>(context, listen: false).fetchClassBookings(),
      Provider.of<ProductCategoryProvider>(context, listen: false).fetchProductCategories(),
      Provider.of<ProductProvider>(context, listen: false).fetchProducts(),
      Provider.of<SaleProvider>(context, listen: false).fetchSales(),
      Provider.of<ExpenseProvider>(context, listen: false).fetchExpenses(),
      Provider.of<EquipmentProvider>(context, listen: false).fetchEquipment(),
    ]);
  }
}