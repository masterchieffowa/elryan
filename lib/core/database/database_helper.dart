import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('laptop_repair.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final appDir = await getApplicationDocumentsDirectory();
    final dbPath = join(appDir.path, 'laptop_repair_shop', filePath);

    await Directory(dirname(dbPath)).create(recursive: true);

    return await databaseFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: _createDB,
      ),
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Customers table
    await db.execute('''
      CREATE TABLE customers (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        phone TEXT NOT NULL,
        address TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // Accessories table
    await db.execute('''
      CREATE TABLE accessories (
        id TEXT PRIMARY KEY,
        name_ar TEXT NOT NULL,
        name_en TEXT NOT NULL,
        price REAL NOT NULL,
        stock_quantity INTEGER NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // Repair orders table
    await db.execute('''
      CREATE TABLE repair_orders (
        id TEXT PRIMARY KEY,
        customer_id TEXT NOT NULL,
        laptop_type TEXT NOT NULL,
        problem_description TEXT NOT NULL,
        total_cost REAL NOT NULL,
        paid_amount REAL NOT NULL,
        status TEXT NOT NULL,
        created_at TEXT NOT NULL,
        completed_at TEXT,
        delivered_at TEXT,
        FOREIGN KEY (customer_id) REFERENCES customers (id) ON DELETE CASCADE
      )
    ''');

    // Order accessories junction table
    await db.execute('''
      CREATE TABLE order_accessories (
        id TEXT PRIMARY KEY,
        order_id TEXT NOT NULL,
        accessory_id TEXT NOT NULL,
        accessory_name_ar TEXT NOT NULL,
        accessory_name_en TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        unit_price REAL NOT NULL,
        total_price REAL NOT NULL,
        FOREIGN KEY (order_id) REFERENCES repair_orders (id) ON DELETE CASCADE
      )
    ''');

    // Payments table
    await db.execute('''
      CREATE TABLE payments (
        id TEXT PRIMARY KEY,
        order_id TEXT NOT NULL,
        amount REAL NOT NULL,
        payment_date TEXT NOT NULL,
        notes TEXT,
        FOREIGN KEY (order_id) REFERENCES repair_orders (id) ON DELETE CASCADE
      )
    ''');

    // Insert sample data
    await _insertDefaultData(db);
  }

  Future<void> _insertDefaultData(Database db) async {
    // Sample accessories
    await db.insert('accessories', {
      'id': '1',
      'name_ar': 'شاحن لابتوب',
      'name_en': 'Laptop Charger',
      'price': 150.0,
      'stock_quantity': 10,
      'created_at': DateTime.now().toIso8601String(),
    });

    await db.insert('accessories', {
      'id': '2',
      'name_ar': 'ماوس',
      'name_en': 'Mouse',
      'price': 50.0,
      'stock_quantity': 15,
      'created_at': DateTime.now().toIso8601String(),
    });

    await db.insert('accessories', {
      'id': '3',
      'name_ar': 'كيبورد',
      'name_en': 'Keyboard',
      'price': 200.0,
      'stock_quantity': 8,
      'created_at': DateTime.now().toIso8601String(),
    });

    await db.insert('accessories', {
      'id': '4',
      'name_ar': 'رام 8 جيجا',
      'name_en': 'RAM 8GB',
      'price': 300.0,
      'stock_quantity': 5,
      'created_at': DateTime.now().toIso8601String(),
    });

    await db.insert('accessories', {
      'id': '5',
      'name_ar': 'هارد SSD 256',
      'name_en': 'SSD 256GB',
      'price': 500.0,
      'stock_quantity': 6,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<String> getDatabasePath() async {
    final appDir = await getApplicationDocumentsDirectory();
    return join(appDir.path, 'laptop_repair_shop', 'laptop_repair.db');
  }

  Future<void> close() async {
    final db = await instance.database;
    await db.close();
  }
}