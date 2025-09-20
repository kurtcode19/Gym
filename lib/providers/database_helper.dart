// lib/providers/database_helper.dart - FURTHER UPDATED CONTENT

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
    String path = join(await getDatabasesPath(), 'gym.db');
    return await openDatabase(
      path,
      version: 1,
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

    // EQUIPMENT Table
    await db.execute('''
      CREATE TABLE EQUIPMENT (
        equipment_id TEXT PRIMARY KEY,
        equipment_name TEXT NOT NULL,
        purchase_date INTEGER NOT NULL,
        condition TEXT
      )
    ''');

    // EXPENSE Table
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
    // Example: If you add a new column in a future version:
    // if (oldVersion < 2) {
    //   await db.execute("ALTER TABLE CUSTOMER ADD COLUMN new_column TEXT;");
    // }
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

  // --- CRUD Methods for ATTENDANCE Table ---
  Future<int> insertAttendance(Map<String, dynamic> attendance) async {
    final db = await database;
    return await db.insert('ATTENDANCE', attendance, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getAttendanceRecords() async {
    final db = await database;
    // Join with CUSTOMER to get member names
    return await db.rawQuery('''
      SELECT
        A.*,
        C.first_name AS customer_first_name,
        C.last_name AS customer_last_name
      FROM ATTENDANCE A
      INNER JOIN CUSTOMER C ON A.member_id = C.customer_id
      ORDER BY A.checkin_time DESC
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
  Future<int> insertGymClass(Map<String, dynamic> gymClass) async {
    final db = await database;
    return await db.insert('CLASS', gymClass, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getGymClasses() async {
    final db = await database;
    // Join with TRAINER to get trainer name
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

  Future<int> updateGymClass(Map<String, dynamic> gymClass) async {
    final db = await database;
    return await db.update(
      'CLASS',
      gymClass,
      where: 'class_id = ?',
      whereArgs: [gymClass['class_id']],
    );
  }

  Future<int> deleteGymClass(String classId) async {
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
    // Join with CUSTOMER and CLASS to get detailed booking info
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
      ORDER BY CL.schedule_time DESC, C.last_name, C.first_name
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
}