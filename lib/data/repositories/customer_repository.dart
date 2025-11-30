import '../../core/database/database_helper.dart';
import '../../domain/models/models.dart';
import 'package:uuid/uuid.dart';

class CustomerRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final _uuid = const Uuid();

  Future<List<Customer>> getAll() async {
    final database = await _db.database;
    final maps = await database.query('customers', orderBy: 'name ASC');
    return maps.map((map) => Customer.fromMap(map)).toList();
  }

  Future<Customer?> getById(String id) async {
    final database = await _db.database;
    final maps =
        await database.query('customers', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Customer.fromMap(maps.first);
  }

  Future<String> create(String name, String phone, String? address) async {
    final database = await _db.database;
    final id = _uuid.v4();
    await database.insert('customers', {
      'id': id,
      'name': name,
      'phone': phone,
      'address': address,
      'created_at': DateTime.now().toIso8601String(),
    });
    return id;
  }

  Future<void> update(Customer customer) async {
    final database = await _db.database;
    await database.update('customers', customer.toMap(),
        where: 'id = ?', whereArgs: [customer.id]);
  }

  Future<void> delete(String id) async {
    final database = await _db.database;
    await database.delete('customers', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Customer>> search(String query) async {
    final database = await _db.database;
    final maps = await database.query('customers',
        where: 'name LIKE ? OR phone LIKE ?',
        whereArgs: ['%$query%', '%$query%']);
    return maps.map((map) => Customer.fromMap(map)).toList();
  }
}