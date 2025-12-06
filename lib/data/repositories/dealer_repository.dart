import '../../core/database/database_helper.dart';
import '../../domain/models/models.dart';
import 'package:uuid/uuid.dart';

class DealerRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final _uuid = const Uuid();

  Future<List<Dealer>> getAll() async {
    final database = await _db.database;
    final maps = await database.query('dealers', orderBy: 'name ASC');
    return maps.map((map) => Dealer.fromMap(map)).toList();
  }

  Future<Dealer?> getById(String id) async {
    final database = await _db.database;
    final maps =
        await database.query('dealers', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Dealer.fromMap(maps.first);
  }

  Future<String> create({
    required String name,
    required String phone,
    String? address,
    String? contactPerson,
    String? email,
  }) async {
    final database = await _db.database;
    final id = _uuid.v4();
    await database.insert('dealers', {
      'id': id,
      'name': name,
      'phone': phone,
      'address': address,
      'contact_person': contactPerson,
      'email': email,
      'created_at': DateTime.now().toIso8601String(),
    });
    return id;
  }

  Future<void> update(Dealer dealer) async {
    final database = await _db.database;
    await database.update('dealers', dealer.toMap(),
        where: 'id = ?', whereArgs: [dealer.id]);
  }

  Future<void> delete(String id) async {
    final database = await _db.database;
    await database.delete('dealers', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Dealer>> search(String query) async {
    final database = await _db.database;
    final maps = await database.query('dealers',
        where: 'name LIKE ? OR phone LIKE ?',
        whereArgs: ['%$query%', '%$query%']);
    return maps.map((map) => Dealer.fromMap(map)).toList();
  }
}
