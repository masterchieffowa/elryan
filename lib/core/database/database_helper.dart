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
        version: 2, // UPDATED VERSION
        onCreate: _createDB,
        onUpgrade: _onUpgrade,
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

    // Dealers table (NEW)
    await db.execute('''
      CREATE TABLE dealers (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        phone TEXT NOT NULL,
        address TEXT,
        contact_person TEXT,
        email TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // Accessories table
    await db.execute('''
      CREATE TABLE accessories (
        id TEXT PRIMARY KEY,
        name_ar TEXT NOT NULL,
        name_en TEXT NOT NULL,
        category_ar TEXT,
        category_en TEXT,
        price REAL NOT NULL,
        stock_quantity INTEGER NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // Repair orders table with serial code
    await db.execute('''
      CREATE TABLE repair_orders (
        id TEXT PRIMARY KEY,
        serial_code TEXT UNIQUE NOT NULL,
        customer_id TEXT,
        dealer_id TEXT,
        device_owner_name TEXT,
        laptop_type TEXT NOT NULL,
        problem_description TEXT NOT NULL,
        total_cost REAL NOT NULL,
        paid_amount REAL NOT NULL,
        status TEXT NOT NULL,
        created_at TEXT NOT NULL,
        completed_at TEXT,
        delivered_at TEXT,
        notes TEXT,
        FOREIGN KEY (customer_id) REFERENCES customers (id) ON DELETE SET NULL,
        FOREIGN KEY (dealer_id) REFERENCES dealers (id) ON DELETE SET NULL
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

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add serial_code column if upgrading from version 1
      await db.execute('ALTER TABLE repair_orders ADD COLUMN serial_code TEXT');

      // Add dealers table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS dealers (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          phone TEXT NOT NULL,
          address TEXT,
          contact_person TEXT,
          email TEXT,
          created_at TEXT NOT NULL
        )
      ''');

      // Add dealer_id and device_owner_name columns
      await db.execute('ALTER TABLE repair_orders ADD COLUMN dealer_id TEXT');
      await db.execute(
          'ALTER TABLE repair_orders ADD COLUMN device_owner_name TEXT');

      // Update existing orders with unique serial codes
      final orders = await db.query('repair_orders');
      for (var order in orders) {
        final serialCode =
            'RPR${DateTime.now().millisecondsSinceEpoch}${order['id'].toString().substring(0, 4).toUpperCase()}';
        await db.update(
          'repair_orders',
          {'serial_code': serialCode},
          where: 'id = ?',
          whereArgs: [order['id']],
        );
      }
    }
  }

  Future<void> _insertDefaultData(Database db) async {
    // Sample accessories with categories
    final accessories = [
      {
        'id': '1',
        'name_ar': 'شاحن لابتوب',
        'name_en': 'Laptop Charger',
        'category_ar': 'شواحن',
        'category_en': 'Chargers',
        'price': 150.0,
        'stock_quantity': 10,
      },
      {
        'id': '2',
        'name_ar': 'ماوس',
        'name_en': 'Mouse',
        'category_ar': 'ملحقات',
        'category_en': 'Accessories',
        'price': 50.0,
        'stock_quantity': 15,
      },
      {
        'id': '3',
        'name_ar': 'كيبورد',
        'name_en': 'Keyboard',
        'category_ar': 'ملحقات',
        'category_en': 'Accessories',
        'price': 200.0,
        'stock_quantity': 8,
      },
      {
        'id': '4',
        'name_ar': 'رام 8 جيجا',
        'name_en': 'RAM 8GB',
        'category_ar': 'قطع غيار',
        'category_en': 'Spare Parts',
        'price': 300.0,
        'stock_quantity': 5,
      },
      {
        'id': '5',
        'name_ar': 'هارد SSD 256',
        'name_en': 'SSD 256GB',
        'category_ar': 'قطع غيار',
        'category_en': 'Spare Parts',
        'price': 500.0,
        'stock_quantity': 6,
      },
    ];

    for (var accessory in accessories) {
      await db.insert('accessories', {
        ...accessory,
        'created_at': DateTime.now().toIso8601String(),
      });
    }
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
