// lib/providers/database_helper.dart - UPDATED CONTENT

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:async';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._privateConstructor();
  static Database? _database;

  DatabaseHelper._privateConstructor();

  factory DatabaseHelper() {
    return _instance;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // Database name corrected to 'gym.db' as per your provided content
    String path = join(await getDatabasesPath(), 'gym.db');
    return await openDatabase(
      path,
      version: 1, // Keep version 1 for now unless schema changes.
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onCreate(Database db, int version) async {
    // CUSTOMER Table
    await db.execute('''
      CREATE TABLE CUSTOMER (
        customer_id TEXT PRIMARY KEY,
        first_name TEXT NOT NULL,
        last_name TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        phone_number TEXT,
        date_joined INTEGER NOT NULL,
        address TEXT,
        emergency_contact_phone TEXT
      )
    ''');

    // MEMBERSHIP_PLAN Table
    await db.execute('''
      CREATE TABLE MEMBERSHIP_PLAN (
        plan_id TEXT PRIMARY KEY,
        plan_name TEXT NOT NULL,
        monthly_fee REAL NOT NULL,
        duration INTEGER NOT NULL
      )
    ''');

    // MEMBERSHIP Table
    await db.execute('''
      CREATE TABLE MEMBERSHIP (
        membership_id TEXT PRIMARY KEY,
        customer_id TEXT NOT NULL,
        plan_id TEXT NOT NULL,
        start_date INTEGER NOT NULL,
        end_date INTEGER NOT NULL,
        status TEXT NOT NULL,
        FOREIGN KEY (customer_id) REFERENCES CUSTOMER(customer_id) ON DELETE CASCADE,
        FOREIGN KEY (plan_id) REFERENCES MEMBERSHIP_PLAN(plan_id) ON DELETE CASCADE
      )
    ''');

    // ATTENDANCE Table
    await db.execute('''
      CREATE TABLE ATTENDANCE (
        attendance_id TEXT PRIMARY KEY,
        member_id TEXT NOT NULL, -- FK to CUSTOMER
        checkin_time INTEGER NOT NULL,
        checkout_time INTEGER,
        date INTEGER NOT NULL,
        facility_used TEXT,
        FOREIGN KEY (member_id) REFERENCES CUSTOMER(customer_id) ON DELETE CASCADE
      )
    ''');

    // TRAINER Table
    await db.execute('''
      CREATE TABLE TRAINER (
        trainer_id TEXT PRIMARY KEY,
        first_name TEXT NOT NULL,
        last_name TEXT NOT NULL,
        email TEXT,
        phone_number TEXT,
        hire_date INTEGER NOT NULL
      )
    ''');

    // CLASS Table
    await db.execute('''
      CREATE TABLE CLASS (
        class_id TEXT PRIMARY KEY,
        trainer_id TEXT,
        class_name TEXT NOT NULL,
        schedule_time INTEGER NOT NULL,
        duration_minutes INTEGER NOT NULL,
        FOREIGN KEY (trainer_id) REFERENCES TRAINER(trainer_id) ON DELETE SET NULL
      )
    ''');

    // CLASS_BOOKING Table
    await db.execute('''
      CREATE TABLE CLASS_BOOKING (
        booking_id TEXT PRIMARY KEY,
        customer_id TEXT NOT NULL,
        class_id TEXT NOT NULL,
        booking_date INTEGER NOT NULL,
        status TEXT NOT NULL,
        FOREIGN KEY (customer_id) REFERENCES CUSTOMER(customer_id) ON DELETE CASCADE,
        FOREIGN KEY (class_id) REFERENCES CLASS(class_id) ON DELETE CASCADE
      )
    ''');

    // PRODUCT_CATEGORY Table
    await db.execute('''
      CREATE TABLE PRODUCT_CATEGORY (
        category_id TEXT PRIMARY KEY,
        category_name TEXT NOT NULL,
        description TEXT,
        status TEXT
      )
    ''');

    // PRODUCT Table
    await db.execute('''
      CREATE TABLE PRODUCT (
        product_id TEXT PRIMARY KEY,
        category_id TEXT,
        product_name TEXT NOT NULL,
        description TEXT,
        unit_price REAL NOT NULL,
        stock_quantity INTEGER NOT NULL,
        status TEXT,
        FOREIGN KEY (category_id) REFERENCES PRODUCT_CATEGORY(category_id) ON DELETE SET NULL
      )
    ''');

    // SALE Table
    await db.execute('''
      CREATE TABLE SALE (
        sale_id TEXT PRIMARY KEY,
        customer_id TEXT NOT NULL,
        sale_date INTEGER NOT NULL,
        total_amount REAL NOT NULL,
        payment_method TEXT,
        FOREIGN KEY (customer_id) REFERENCES CUSTOMER(customer_id) ON DELETE CASCADE
      )
    ''');

    // SALE_ITEM Table
    await db.execute('''
      CREATE TABLE SALE_ITEM (
        sale_item_id TEXT PRIMARY KEY,
        sale_id TEXT NOT NULL,
        product_id TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        unit_price REAL NOT NULL,
        FOREIGN KEY (sale_id) REFERENCES SALE(sale_id) ON DELETE CASCADE,
        FOREIGN KEY (product_id) REFERENCES PRODUCT(product_id) ON DELETE CASCADE
      )
    ''');

    // PAYMENT Table
    await db.execute('''
      CREATE TABLE PAYMENT (
        payment_id TEXT PRIMARY KEY,
        membership_id TEXT NOT NULL,
        amount REAL NOT NULL,
        method TEXT,
        payment_date INTEGER NOT NULL,
        status TEXT NOT NULL,
        FOREIGN KEY (membership_id) REFERENCES MEMBERSHIP(membership_id) ON DELETE CASCADE
      )
    ''');

    // EQUIPMENT Table (This table was already present in your provided schema)
    await db.execute('''
      CREATE TABLE EQUIPMENT (
        equipment_id TEXT PRIMARY KEY,
        equipment_name TEXT NOT NULL,
        purchase_date INTEGER NOT NULL,
        condition TEXT
      )
    ''');

    // EXPENSE Table (This table was already present in your provided schema)
    await db.execute('''
      CREATE TABLE EXPENSE (
        expense_id TEXT PRIMARY KEY,
        category TEXT NOT NULL,
        description TEXT,
        amount REAL NOT NULL,
        expense_date INTEGER NOT NULL
      )
    ''');

    print('Database created with all tables.');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print('Database upgraded from version $oldVersion to $newVersion');
    // Implement migration logic if future schema changes are introduced
  }

  // --- CRUD Methods for CUSTOMER Table ---
  Future<int> insertCustomer(Map<String, dynamic> customer) async {
    final db = await database;
    return await db.insert('CUSTOMER', customer, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getCustomers() async {
    final db = await database;
    return await db.query('CUSTOMER', orderBy: 'last_name, first_name');
  }

  Future<int> updateCustomer(Map<String, dynamic> customer) async {
    final db = await database;
    return await db.update(
      'CUSTOMER',
      customer,
      where: 'customer_id = ?',
      whereArgs: [customer['customer_id']],
    );
  }

  Future<int> deleteCustomer(String customerId) async {
    final db = await database;
    return await db.delete(
      'CUSTOMER',
      where: 'customer_id = ?',
      whereArgs: [customerId],
    );
  }

  // --- CRUD Methods for MEMBERSHIP_PLAN Table ---
  Future<int> insertMembershipPlan(Map<String, dynamic> plan) async {
    final db = await database;
    return await db.insert('MEMBERSHIP_PLAN', plan, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getMembershipPlans() async {
    final db = await database;
    return await db.query('MEMBERSHIP_PLAN', orderBy: 'plan_name');
  }

  Future<int> updateMembershipPlan(Map<String, dynamic> plan) async {
    final db = await database;
    return await db.update(
      'MEMBERSHIP_PLAN',
      plan,
      where: 'plan_id = ?',
      whereArgs: [plan['plan_id']],
    );
  }

  Future<int> deleteMembershipPlan(String planId) async {
    final db = await database;
    return await db.delete(
      'MEMBERSHIP_PLAN',
      where: 'plan_id = ?',
      whereArgs: [planId],
    );
  }

  // --- CRUD Methods for MEMBERSHIP Table ---
  Future<int> insertMembership(Map<String, dynamic> membership) async {
    final db = await database;
    return await db.insert('MEMBERSHIP', membership, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getMemberships() async {
    final db = await database;
    return await db.query('MEMBERSHIP');
  }

  Future<List<Map<String, dynamic>>> getDetailedMemberships() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT
        M.*,
        C.first_name AS customer_first_name,
        C.last_name AS customer_last_name,
        MP.plan_name AS plan_name,
        MP.monthly_fee AS plan_monthly_fee
      FROM MEMBERSHIP M
      INNER JOIN CUSTOMER C ON M.customer_id = C.customer_id
      INNER JOIN MEMBERSHIP_PLAN MP ON M.plan_id = MP.plan_id
      ORDER BY M.end_date DESC
    ''');
  }

  Future<int> updateMembership(Map<String, dynamic> membership) async {
    final db = await database;
    return await db.update(
      'MEMBERSHIP',
      membership,
      where: 'membership_id = ?',
      whereArgs: [membership['membership_id']],
    );
  }

  Future<int> deleteMembership(String membershipId) async {
    final db = await database;
    return await db.delete(
      'MEMBERSHIP',
      where: 'membership_id = ?',
      whereArgs: [membershipId],
    );
  }

  // --- CRUD Methods for TRAINER Table ---
  Future<int> insertTrainer(Map<String, dynamic> trainer) async {
    final db = await database;
    return await db.insert('TRAINER', trainer, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getTrainers() async {
    final db = await database;
    return await db.query('TRAINER', orderBy: 'last_name, first_name');
  }

  Future<int> updateTrainer(Map<String, dynamic> trainer) async {
    final db = await database;
    return await db.update(
      'TRAINER',
      trainer,
      where: 'trainer_id = ?',
      whereArgs: [trainer['trainer_id']],
    );
  }

  Future<int> deleteTrainer(String trainerId) async {
    final db = await database;
    return await db.delete(
      'TRAINER',
      where: 'trainer_id = ?',
      whereArgs: [trainerId],
    );
  }

  // --- CRUD Methods for CLASS Table ---
  Future<int> insertClass(Map<String, dynamic> classData) async {
    final db = await database;
    return await db.insert('CLASS', classData, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getClasses() async {
    final db = await database;
    return await db.query('CLASS', orderBy: 'schedule_time DESC');
  }

  Future<List<Map<String, dynamic>>> getDetailedClasses() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT
        CL.*,
        T.first_name AS trainer_first_name,
        T.last_name AS trainer_last_name
      FROM CLASS CL
      LEFT JOIN TRAINER T ON CL.trainer_id = T.trainer_id
      ORDER BY CL.schedule_time DESC
    ''');
  }

  Future<int> updateClass(Map<String, dynamic> classData) async {
    final db = await database;
    return await db.update(
      'CLASS',
      classData,
      where: 'class_id = ?',
      whereArgs: [classData['class_id']],
    );
  }

  Future<int> deleteClass(String classId) async {
    final db = await database;
    return await db.delete(
      'CLASS',
      where: 'class_id = ?',
      whereArgs: [classId],
    );
  }

  // --- CRUD Methods for CLASS_BOOKING Table ---
  Future<int> insertClassBooking(Map<String, dynamic> booking) async {
    final db = await database;
    return await db.insert('CLASS_BOOKING', booking, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getClassBookings() async {
    final db = await database;
    return await db.query('CLASS_BOOKING', orderBy: 'booking_date DESC');
  }

  Future<List<Map<String, dynamic>>> getDetailedClassBookings() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT
        CB.*,
        C.first_name AS customer_first_name,
        C.last_name AS customer_last_name,
        CL.class_name AS class_name,
        CL.schedule_time AS class_schedule_time,
        CL.duration_minutes AS class_duration_minutes,
        T.first_name AS trainer_first_name,
        T.last_name AS trainer_last_name
      FROM CLASS_BOOKING CB
      INNER JOIN CUSTOMER C ON CB.customer_id = C.customer_id
      INNER JOIN CLASS CL ON CB.class_id = CL.class_id
      LEFT JOIN TRAINER T ON CL.trainer_id = T.trainer_id
      ORDER BY CL.schedule_time DESC, C.last_name
    ''');
  }

  Future<int> updateClassBooking(Map<String, dynamic> booking) async {
    final db = await database;
    return await db.update(
      'CLASS_BOOKING',
      booking,
      where: 'booking_id = ?',
      whereArgs: [booking['booking_id']],
    );
  }

  Future<int> deleteClassBooking(String bookingId) async {
    final db = await database;
    return await db.delete(
      'CLASS_BOOKING',
      where: 'booking_id = ?',
      whereArgs: [bookingId],
    );
  }

  // --- CRUD Methods for PRODUCT_CATEGORY Table ---
  Future<int> insertProductCategory(Map<String, dynamic> category) async {
    final db = await database;
    return await db.insert('PRODUCT_CATEGORY', category, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getProductCategories() async {
    final db = await database;
    return await db.query('PRODUCT_CATEGORY', orderBy: 'category_name');
  }

  Future<int> updateProductCategory(Map<String, dynamic> category) async {
    final db = await database;
    return await db.update(
      'PRODUCT_CATEGORY',
      category,
      where: 'category_id = ?',
      whereArgs: [category['category_id']],
    );
  }

  Future<int> deleteProductCategory(String categoryId) async {
    final db = await database;
    return await db.delete(
      'PRODUCT_CATEGORY',
      where: 'category_id = ?',
      whereArgs: [categoryId],
    );
  }

  // --- CRUD Methods for PRODUCT Table ---
  Future<int> insertProduct(Map<String, dynamic> product) async {
    final db = await database;
    return await db.insert('PRODUCT', product, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getProducts() async {
    final db = await database;
    return await db.query('PRODUCT', orderBy: 'product_name');
  }

  Future<List<Map<String, dynamic>>> getDetailedProducts() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT
        P.*,
        PC.category_name AS category_name
      FROM PRODUCT P
      LEFT JOIN PRODUCT_CATEGORY PC ON P.category_id = PC.category_id
      ORDER BY P.product_name
    ''');
  }

  Future<int> updateProduct(Map<String, dynamic> product) async {
    final db = await database;
    return await db.update(
      'PRODUCT',
      product,
      where: 'product_id = ?',
      whereArgs: [product['product_id']],
    );
  }

  Future<int> deleteProduct(String productId) async {
    final db = await database;
    return await db.delete(
      'PRODUCT',
      where: 'product_id = ?',
      whereArgs: [productId],
    );
  }

  // --- CRUD Methods for SALE Table ---
  Future<String> insertSale(Map<String, dynamic> sale) async {
    final db = await database;
    await db.insert('SALE', sale, conflictAlgorithm: ConflictAlgorithm.replace);
    return sale['sale_id']; // Return the ID of the inserted sale
  }

  Future<List<Map<String, dynamic>>> getSales() async {
    final db = await database;
    return await db.query('SALE', orderBy: 'sale_date DESC');
  }

  // Get sales with joined customer details
  Future<List<Map<String, dynamic>>> getDetailedSales() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT
        S.*,
        C.first_name AS customer_first_name,
        C.last_name AS customer_last_name
      FROM SALE S
      INNER JOIN CUSTOMER C ON S.customer_id = C.customer_id
      ORDER BY S.sale_date DESC
    ''');
  }

  Future<int> updateSale(Map<String, dynamic> sale) async {
    final db = await database;
    return await db.update(
      'SALE',
      sale,
      where: 'sale_id = ?',
      whereArgs: [sale['sale_id']],
    );
  }

  Future<int> deleteSale(String saleId) async {
    final db = await database;
    return await db.delete(
      'SALE',
      where: 'sale_id = ?',
      whereArgs: [saleId],
    );
  }

  // --- CRUD Methods for SALE_ITEM Table ---
  Future<int> insertSaleItem(Map<String, dynamic> saleItem) async {
    final db = await database;
    return await db.insert('SALE_ITEM', saleItem, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getSaleItemsForSale(String saleId) async {
    final db = await database;
    return await db.query('SALE_ITEM', where: 'sale_id = ?', whereArgs: [saleId]);
  }

  // Get sale items for a specific sale, with joined product details
  Future<List<Map<String, dynamic>>> getDetailedSaleItemsForSale(String saleId) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT
        SI.*,
        P.product_name AS product_name,
        P.description AS product_description
      FROM SALE_ITEM SI
      INNER JOIN PRODUCT P ON SI.product_id = P.product_id
      WHERE SI.sale_id = ?
      ORDER BY P.product_name
    ''', [saleId]);
  }

  Future<int> updateSaleItem(Map<String, dynamic> saleItem) async {
    final db = await database;
    return await db.update(
      'SALE_ITEM',
      saleItem,
      where: 'sale_item_id = ?',
      whereArgs: [saleItem['sale_item_id']],
    );
  }

  Future<int> deleteSaleItem(String saleItemId) async {
    final db = await database;
    return await db.delete(
      'SALE_ITEM',
      where: 'sale_item_id = ?',
      whereArgs: [saleItemId],
    );
  }

  Future<int> deleteSaleItemsForSale(String saleId) async {
    final db = await database;
    return await db.delete(
      'SALE_ITEM',
      where: 'sale_id = ?',
      whereArgs: [saleId],
    );
  }

  // --- CRUD Methods for PAYMENT Table ---
  Future<int> insertPayment(Map<String, dynamic> payment) async {
    final db = await database;
    return await db.insert('PAYMENT', payment, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getPayments() async {
    final db = await database;
    return await db.query('PAYMENT', orderBy: 'payment_date DESC');
  }

  // Get payments with joined membership and customer details
  Future<List<Map<String, dynamic>>> getDetailedPayments() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT
        PY.*,
        M.start_date AS membership_start_date,
        M.end_date AS membership_end_date,
        M.status AS membership_status,
        C.first_name AS customer_first_name,
        C.last_name AS customer_last_name
      FROM PAYMENT PY
      INNER JOIN MEMBERSHIP M ON PY.membership_id = M.membership_id
      INNER JOIN CUSTOMER C ON M.customer_id = C.customer_id
      ORDER BY PY.payment_date DESC
    ''');
  }

  Future<int> updatePayment(Map<String, dynamic> payment) async {
    final db = await database;
    return await db.update(
      'PAYMENT',
      payment,
      where: 'payment_id = ?',
      whereArgs: [payment['payment_id']],
    );
  }

  Future<int> deletePayment(String paymentId) async {
    final db = await database;
    return await db.delete(
      'PAYMENT',
      where: 'payment_id = ?',
      whereArgs: [paymentId],
    );
  }

  // --- CRUD Methods for ATTENDANCE Table ---
  Future<int> insertAttendance(Map<String, dynamic> attendance) async {
    final db = await database;
    return await db.insert('ATTENDANCE', attendance, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getAttendanceRecords() async {
    final db = await database;
    return await db.query('ATTENDANCE', orderBy: 'date DESC, checkin_time DESC');
  }

  // Get attendance records with joined customer details
  Future<List<Map<String, dynamic>>> getDetailedAttendanceRecords() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT
        A.*,
        C.first_name AS customer_first_name,
        C.last_name AS customer_last_name
      FROM ATTENDANCE A
      INNER JOIN CUSTOMER C ON A.member_id = C.customer_id
      ORDER BY A.date DESC, A.checkin_time DESC
    ''');
  }

  Future<int> updateAttendance(Map<String, dynamic> attendance) async {
    final db = await database;
    return await db.update(
      'ATTENDANCE',
      attendance,
      where: 'attendance_id = ?',
      whereArgs: [attendance['attendance_id']],
    );
  }

  Future<int> deleteAttendance(String attendanceId) async {
    final db = await database;
    return await db.delete(
      'ATTENDANCE',
      where: 'attendance_id = ?',
      whereArgs: [attendanceId],
    );
  }

  // --- CRUD Methods for EXPENSE Table ---
  Future<int> insertExpense(Map<String, dynamic> expense) async {
    final db = await database;
    return await db.insert('EXPENSE', expense, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getExpenses() async {
    final db = await database;
    return await db.query('EXPENSE', orderBy: 'expense_date DESC, category');
  }

  Future<int> updateExpense(Map<String, dynamic> expense) async {
    final db = await database;
    return await db.update(
      'EXPENSE',
      expense,
      where: 'expense_id = ?',
      whereArgs: [expense['expense_id']],
    );
  }

  Future<int> deleteExpense(String expenseId) async {
    final db = await database;
    return await db.delete(
      'EXPENSE',
      where: 'expense_id = ?',
      whereArgs: [expenseId],
    );
  }

  // --- CRUD Methods for EQUIPMENT Table --- // NEW
  Future<int> insertEquipment(Map<String, dynamic> equipment) async {
    final db = await database;
    return await db.insert('EQUIPMENT', equipment, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getEquipment() async {
    final db = await database;
    return await db.query('EQUIPMENT', orderBy: 'equipment_name');
  }

  Future<int> updateEquipment(Map<String, dynamic> equipment) async {
    final db = await database;
    return await db.update(
      'EQUIPMENT',
      equipment,
      where: 'equipment_id = ?',
      whereArgs: [equipment['equipment_id']],
    );
  }

  Future<int> deleteEquipment(String equipmentId) async {
    final db = await database;
    return await db.delete(
      'EQUIPMENT',
      where: 'equipment_id = ?',
      whereArgs: [equipmentId],
    );
  }
}