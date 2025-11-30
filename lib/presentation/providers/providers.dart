import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/customer_repository.dart';
import '../../data/repositories/accessory_repository.dart';
import '../../data/repositories/repair_order_repository.dart';
import '../../domain/models/models.dart';

// Repository Providers
final customerRepositoryProvider = Provider((ref) => CustomerRepository());
final accessoryRepositoryProvider = Provider((ref) => AccessoryRepository());
final repairOrderRepositoryProvider = Provider((ref) => RepairOrderRepository());

// Customers Provider
final customersProvider = FutureProvider<List<Customer>>((ref) async {
  final repo = ref.watch(customerRepositoryProvider);
  return await repo.getAll();
});

// Accessories Provider
final accessoriesProvider = FutureProvider<List<Accessory>>((ref) async {
  final repo = ref.watch(accessoryRepositoryProvider);
  return await repo.getAll();
});

// Orders Provider
final ordersProvider = FutureProvider<List<RepairOrder>>((ref) async {
  final repo = ref.watch(repairOrderRepositoryProvider);
  return await repo.getAll();
});

// Orders by Status Provider
final ordersByStatusProvider = FutureProvider.family<List<RepairOrder>, OrderStatus>(
  (ref, status) async {
    final repo = ref.watch(repairOrderRepositoryProvider);
    return await repo.getByStatus(status);
  },
);

// Customer Orders Provider
final customerOrdersProvider = FutureProvider.family<List<RepairOrder>, String>(
  (ref, customerId) async {
    final repo = ref.watch(repairOrderRepositoryProvider);
    return await repo.getByCustomer(customerId);
  },
);

// Order Details Provider
final orderDetailsProvider = FutureProvider.family<RepairOrder?, String>(
  (ref, orderId) async {
    final repo = ref.watch(repairOrderRepositoryProvider);
    return await repo.getById(orderId);
  },
);

// Statistics Provider
final statisticsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repo = ref.watch(repairOrderRepositoryProvider);
  return await repo.getStatistics();
});

// Low Stock Accessories Provider
final lowStockAccessoriesProvider = FutureProvider<List<Accessory>>((ref) async {
  final repo = ref.watch(accessoryRepositoryProvider);
  return await repo.getLowStock();
});

// Selected Order Provider (for editing)
final selectedOrderProvider = StateProvider<RepairOrder?>((ref) => null);

// Selected Customer Provider (for new order)
final selectedCustomerProvider = StateProvider<Customer?>((ref) => null);