class RepairOrderRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final _uuid = const Uuid();

  Future<List<RepairOrder>> getAll() async {
    final database = await _db.database;
    final maps =
        await database.query('repair_orders', orderBy: 'created_at DESC');

    final orders = <RepairOrder>[];
    for (var map in maps) {
      final order = RepairOrder.fromMap(map);
      final accessories = await _getOrderAccessories(order.id);
      final payments = await _getOrderPayments(order.id);
      orders.add(order.copyWith(accessories: accessories, payments: payments));
    }
    return orders;
  }

  Future<RepairOrder?> getById(String id) async {
    final database = await _db.database;
    final maps =
        await database.query('repair_orders', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;

    final order = RepairOrder.fromMap(maps.first);
    final accessories = await _getOrderAccessories(order.id);
    final payments = await _getOrderPayments(order.id);
    return order.copyWith(accessories: accessories, payments: payments);
  }

  Future<List<RepairOrder>> getByStatus(OrderStatus status) async {
    final database = await _db.database;
    final maps = await database.query('repair_orders',
        where: 'status = ?', whereArgs: [status.name], orderBy: 'created_at DESC');

    final orders = <RepairOrder>[];
    for (var map in maps) {
      final order = RepairOrder.fromMap(map);
      final accessories = await _getOrderAccessories(order.id);
      final payments = await _getOrderPayments(order.id);
      orders.add(order.copyWith(accessories: accessories, payments: payments));
    }
    return orders;
  }

  Future<List<RepairOrder>> getByCustomer(String customerId) async {
    final database = await _db.database;
    final maps = await database.query('repair_orders',
        where: 'customer_id = ?',
        whereArgs: [customerId],
        orderBy: 'created_at DESC');

    final orders = <RepairOrder>[];
    for (var map in maps) {
      final order = RepairOrder.fromMap(map);
      final accessories = await _getOrderAccessories(order.id);
      final payments = await _getOrderPayments(order.id);
      orders.add(order.copyWith(accessories: accessories, payments: payments));
    }
    return orders;
  }

  Future<List<OrderAccessory>> _getOrderAccessories(String orderId) async {
    final database = await _db.database;
    final maps = await database.query('order_accessories',
        where: 'order_id = ?', whereArgs: [orderId]);
    return maps.map((map) => OrderAccessory.fromMap(map)).toList();
  }

  Future<List<Payment>> _getOrderPayments(String orderId) async {
    final database = await _db.database;
    final maps = await database.query('payments',
        where: 'order_id = ?', whereArgs: [orderId], orderBy: 'payment_date DESC');
    return maps.map((map) => Payment.fromMap(map)).toList();
  }

  Future<String> create({
    required String customerId,
    required String laptopType,
    required String problemDescription,
    required double totalCost,
    required double initialPayment,
    List<OrderAccessory>? accessories,
  }) async {
    final database = await _db.database;
    final orderId = _uuid.v4();

    // Insert order
    await database.insert('repair_orders', {
      'id': orderId,
      'customer_id': customerId,
      'laptop_type': laptopType,
      'problem_description': problemDescription,
      'total_cost': totalCost,
      'paid_amount': initialPayment,
      'status': OrderStatus.pending.name,
      'created_at': DateTime.now().toIso8601String(),
      'completed_at': null,
      'delivered_at': null,
    });

    // Insert initial payment if any
    if (initialPayment > 0) {
      await database.insert('payments', {
        'id': _uuid.v4(),
        'order_id': orderId,
        'amount': initialPayment,
        'payment_date': DateTime.now().toIso8601String(),
        'notes': 'Initial payment',
      });
    }

    // Insert accessories if any
    if (accessories != null && accessories.isNotEmpty) {
      for (var accessory in accessories) {
        await database.insert('order_accessories', accessory.toMap());
        // Update stock
        await database.rawUpdate(
          'UPDATE accessories SET stock_quantity = stock_quantity - ? WHERE id = ?',
          [accessory.quantity, accessory.accessoryId],
        );
      }
    }

    return orderId;
  }

  Future<void> updateStatus(String orderId, OrderStatus status) async {
    final database = await _db.database;
    final updates = <String, dynamic>{'status': status.name};

    if (status == OrderStatus.completed) {
      updates['completed_at'] = DateTime.now().toIso8601String();
    } else if (status == OrderStatus.delivered) {
      updates['delivered_at'] = DateTime.now().toIso8601String();
    }

    await database.update('repair_orders', updates,
        where: 'id = ?', whereArgs: [orderId]);
  }

  Future<void> addPayment({
    required String orderId,
    required double amount,
    String? notes,
  }) async {
    final database = await _db.database;

    // Insert payment
    await database.insert('payments', {
      'id': _uuid.v4(),
      'order_id': orderId,
      'amount': amount,
      'payment_date': DateTime.now().toIso8601String(),
      'notes': notes,
    });

    // Update order paid amount
    await database.rawUpdate(
      'UPDATE repair_orders SET paid_amount = paid_amount + ? WHERE id = ?',
      [amount, orderId],
    );
  }

  Future<void> delete(String id) async {
    final database = await _db.database;

    // Get accessories to restore stock
    final accessories = await _getOrderAccessories(id);
    for (var accessory in accessories) {
      await database.rawUpdate(
        'UPDATE accessories SET stock_quantity = stock_quantity + ? WHERE id = ?',
        [accessory.quantity, accessory.accessoryId],
      );
    }

    // Delete order (cascades to accessories and payments)
    await database.delete('repair_orders', where: 'id = ?', whereArgs: [id]);
  }

  // Reports
  Future<Map<String, dynamic>> getStatistics() async {
    final database = await _db.database;

    final totalOrders =
        (await database.query('repair_orders')).length;
    final pendingOrders = (await database.query('repair_orders',
            where: 'status = ?', whereArgs: [OrderStatus.pending.name]))
        .length;
    final completedOrders = (await database.query('repair_orders',
            where: 'status = ?', whereArgs: [OrderStatus.completed.name]))
        .length;

    final revenueResult = await database.rawQuery(
        'SELECT SUM(total_cost) as total, SUM(paid_amount) as paid FROM repair_orders');
    final totalRevenue =
        (revenueResult.first['total'] as num?)?.toDouble() ?? 0.0;
    final totalPaid =
        (revenueResult.first['paid'] as num?)?.toDouble() ?? 0.0;
    final outstanding = totalRevenue - totalPaid;

    return {
      'total_orders': totalOrders,
      'pending_orders': pendingOrders,
      'completed_orders': completedOrders,
      'total_revenue': totalRevenue,
      'outstanding_balance': outstanding,
    };
  }

  Future<List<RepairOrder>> getByDateRange(
      DateTime startDate, DateTime endDate) async {
    final database = await _db.database;
    final maps = await database.query('repair_orders',
        where: 'created_at BETWEEN ? AND ?',
        whereArgs: [
          startDate.toIso8601String(),
          endDate.toIso8601String()
        ],
        orderBy: 'created_at DESC');

    final orders = <RepairOrder>[];
    for (var map in maps) {
      final order = RepairOrder.fromMap(map);
      final accessories = await _getOrderAccessories(order.id);
      final payments = await _getOrderPayments(order.id);
      orders.add(order.copyWith(accessories: accessories, payments: payments));
    }
    return orders;
  }
}