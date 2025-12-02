import '../../core/database/database_helper.dart';
import '../../domain/models/models.dart';
import 'package:uuid/uuid.dart';

class AccessoryRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final _uuid = const Uuid();
  
  Future<List<Accessory>> getAll() async {
    final database = await _db.database;
    final maps = await database.query('accessories', orderBy: 'name_ar ASC');
    return maps.map((map) => Accessory.fromMap(map)).toList();
  }

  Future<Accessory?> getById(String id) async {
    final database = await _db.database;
    final maps =
        await database.query('accessories', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Accessory.fromMap(maps.first);
  }

  Future<String> create({
    required String nameAr,
    required String nameEn,
    required double price,
    required int stockQuantity,
  }) async {
    final database = await _db.database;
    final id = _uuid.v4();
    await database.insert('accessories', {
      'id': id,
      'name_ar': nameAr,
      'name_en': nameEn,
      'price': price,
      'stock_quantity': stockQuantity,
      'created_at': DateTime.now().toIso8601String(),
    });
    return id;
  }

  Future<void> update(Accessory accessory) async {
    final database = await _db.database;
    await database.update('accessories', accessory.toMap(),
        where: 'id = ?', whereArgs: [accessory.id]);
  }

  Future<void> delete(String id) async {
    final database = await _db.database;
    await database.delete('accessories', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateStock(String id, int quantity) async {
    final database = await _db.database;
    await database.rawUpdate(
      'UPDATE accessories SET stock_quantity = stock_quantity + ? WHERE id = ?',
      [quantity, id],
    );
  }

  Future<List<Accessory>> getLowStock({int threshold = 5}) async {
    final database = await _db.database;
    final maps = await database.query('accessories',
        where: 'stock_quantity <= ?', whereArgs: [threshold]);
    return maps.map((map) => Accessory.fromMap(map)).toList();
  }
}