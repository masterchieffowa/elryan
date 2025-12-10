import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/utils/serial_generator.dart';
import '../../../domain/models/models.dart';
import '../../providers/providers.dart';
import 'order_form_screen.dart';
import 'order_details_screen.dart';
import '../dealers/dealers_screen.dart';

// Helper function to get owner name
Future<String> _getOrderOwnerName(WidgetRef ref, RepairOrder order) async {
  if (order.customerId != null) {
    final customersAsync = ref.read(customersProvider);
    if (customersAsync.hasValue) {
      try {
        final customer =
            customersAsync.value!.firstWhere((c) => c.id == order.customerId);
        return customer.name;
      } catch (e) {
        return '';
      }
    }
  } else if (order.dealerId != null) {
    final dealersAsync = ref.read(dealersProvider);
    if (dealersAsync.hasValue) {
      try {
        final dealer =
            dealersAsync.value!.firstWhere((d) => d.id == order.dealerId);
        return '${dealer.name}${order.deviceOwnerName != null ? " (${order.deviceOwnerName})" : ""}';
      } catch (e) {
        return order.deviceOwnerName ?? '';
      }
    }
  }
  return '';
}

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  OrderStatus? _filterStatus;
  String _searchQuery = '';
  String _serialSearchQuery = '';

  void _refreshAll() {
    ref.invalidate(ordersProvider);
    ref.invalidate(customersProvider);
    ref.invalidate(dealersProvider);
    ref.invalidate(accessoriesProvider);
    ref.invalidate(statisticsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ordersAsync = ref.watch(ordersProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.orders),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshAll,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).cardColor,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText:
                              '${l10n.search} (${l10n.isArabic ? "الاسم أو الجهاز" : "Name or Device"})',
                          prefixIcon: const Icon(Icons.search),
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          setState(() => _searchQuery = value.toLowerCase());
                        },
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Search by serial code
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: l10n.searchBySerial,
                          prefixIcon: const Icon(Icons.qr_code),
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          setState(() => _serialSearchQuery = value.trim());
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: Text(l10n.newOrder),
                      onPressed: () => _showNewOrderOptionsDialog(context),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 20),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Status Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: Text(l10n.isArabic ? 'الكل' : 'All'),
                        selected: _filterStatus == null,
                        onSelected: (selected) {
                          setState(() => _filterStatus = null);
                        },
                      ),
                      const SizedBox(width: 8),
                      ...OrderStatus.values.map((status) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(
                                l10n.isArabic ? status.nameAr : status.nameEn),
                            selected: _filterStatus == status,
                            onSelected: (selected) {
                              setState(() =>
                                  _filterStatus = selected ? status : null);
                            },
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Orders List
          Expanded(
            child: ordersAsync.when(
              data: (orders) {
                // Apply filters
                var filteredOrders = orders;

                if (_filterStatus != null) {
                  filteredOrders = filteredOrders
                      .where((order) => order.status == _filterStatus)
                      .toList();
                }

                // Serial search - exact and partial matching
                if (_serialSearchQuery.isNotEmpty) {
                  filteredOrders = filteredOrders.where((order) {
                    final cleanSerial =
                        order.serialCode.replaceAll('-', '').toLowerCase();
                    final cleanSearch =
                        _serialSearchQuery.replaceAll('-', '').toLowerCase();
                    return cleanSerial.contains(cleanSearch);
                  }).toList();
                }

                if (filteredOrders.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox_outlined,
                            size: 80, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(l10n.noData,
                            style: TextStyle(color: Colors.grey[600])),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredOrders.length,
                  itemBuilder: (context, index) {
                    final order = filteredOrders[index];

                    // Filter by search query (name or laptop)
                    if (_searchQuery.isNotEmpty) {
                      return FutureBuilder<String>(
                        future: _getOrderOwnerName(ref, order),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const SizedBox.shrink();
                          }
                          final ownerName = snapshot.data!.toLowerCase();
                          final laptopType = order.laptopType.toLowerCase();
                          final problem =
                              order.problemDescription.toLowerCase();

                          if (!ownerName.contains(_searchQuery) &&
                              !laptopType.contains(_searchQuery) &&
                              !problem.contains(_searchQuery)) {
                            return const SizedBox.shrink();
                          }

                          return OrderCard(order: order, onUpdate: _refreshAll);
                        },
                      );
                    }

                    return OrderCard(order: order, onUpdate: _refreshAll);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error: $error')),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showNewOrderOptionsDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context);

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.isArabic ? 'نوع الطلب' : 'Order Type'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.build, color: Colors.blue, size: 40),
              title: Text(l10n.isArabic ? 'إصلاح لابتوب' : 'Laptop Repair'),
              subtitle: Text(l10n.isArabic
                  ? 'إنشاء طلب إصلاح (يمكن إضافة إكسسوارات)'
                  : 'Create repair order (can add accessories)'),
              onTap: () => Navigator.pop(context, 'repair'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.shopping_cart,
                  color: Colors.green, size: 40),
              title: Text(l10n.isArabic
                  ? 'بيع إكسسوارات فقط'
                  : 'Sell Accessories Only'),
              subtitle: Text(l10n.isArabic
                  ? 'بيع بدون إصلاح (عميل معروف أو غير معروف)'
                  : 'Sell without repair (known or unknown customer)'),
              onTap: () => Navigator.pop(context, 'accessories'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );

    if (result != null && mounted) {
      if (result == 'repair') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const OrderFormScreen(includeAccessories: true),
          ),
        ).then((_) => _refreshAll());
      } else if (result == 'accessories') {
        // Show accessories-only dialog
        _showAccessoriesOnlyDialog(context);
      }
    }
  }

  Future<void> _showAccessoriesOnlyDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final accessoriesAsync = ref.read(accessoriesProvider);
    final customersAsync = ref.read(customersProvider);

    if (!accessoriesAsync.hasValue || !customersAsync.hasValue) return;

    final accessories = accessoriesAsync.value!;
    final customers = customersAsync.value!;
    final selectedItems = <Accessory, int>{};
    Customer? selectedCustomer;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final total = selectedItems.entries.fold<double>(
            0,
            (sum, entry) => sum + (entry.key.price * entry.value),
          );

          return AlertDialog(
            title: Text(l10n.isArabic ? 'بيع إكسسوارات' : 'Sell Accessories'),
            content: SizedBox(
              width: 600,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Customer selection
                  DropdownButtonFormField<Customer>(
                    value: selectedCustomer,
                    decoration: InputDecoration(
                      labelText: l10n.customerName,
                      border: const OutlineInputBorder(),
                    ),
                    items: customers.map((customer) {
                      return DropdownMenuItem(
                        value: customer,
                        child: Text('${customer.name} - ${customer.phone}'),
                      );
                    }).toList(),
                    onChanged: (customer) {
                      setState(() => selectedCustomer = customer);
                    },
                  ),
                  const SizedBox(height: 16),
                  // Accessories list
                  Text(l10n.accessories,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 300,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: accessories.length,
                      itemBuilder: (context, index) {
                        final accessory = accessories[index];
                        final isSelected = selectedItems.containsKey(accessory);

                        return ListTile(
                          title: Text(l10n.isArabic
                              ? accessory.nameAr
                              : accessory.nameEn),
                          subtitle: Text(
                              '${l10n.price}: ${l10n.currency(accessory.price)} | ${l10n.stockQuantity}: ${accessory.stockQuantity}'),
                          trailing: isSelected
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove),
                                      onPressed: () {
                                        setState(() {
                                          if (selectedItems[accessory]! > 1) {
                                            selectedItems[accessory] =
                                                selectedItems[accessory]! - 1;
                                          } else {
                                            selectedItems.remove(accessory);
                                          }
                                        });
                                      },
                                    ),
                                    Text('${selectedItems[accessory]}'),
                                    IconButton(
                                      icon: const Icon(Icons.add),
                                      onPressed: () {
                                        if (selectedItems[accessory]! <
                                            accessory.stockQuantity) {
                                          setState(() {
                                            selectedItems[accessory] =
                                                selectedItems[accessory]! + 1;
                                          });
                                        }
                                      },
                                    ),
                                  ],
                                )
                              : ElevatedButton(
                                  onPressed: accessory.stockQuantity > 0
                                      ? () {
                                          setState(() {
                                            selectedItems[accessory] = 1;
                                          });
                                        }
                                      : null,
                                  child: const Icon(Icons.add),
                                ),
                        );
                      },
                    ),
                  ),
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(l10n.isArabic ? 'الإجمالي:' : 'Total:',
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        Text(l10n.currency(total),
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.green)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.cancel),
              ),
              ElevatedButton(
                onPressed: (selectedCustomer == null || selectedItems.isEmpty)
                    ? null
                    : () async {
                        // Create accessories-only order
                        await _createAccessoriesOrder(
                            selectedCustomer!, selectedItems, total);
                        Navigator.pop(context);
                      },
                child: Text(l10n.isArabic ? 'إتمام البيع' : 'Complete Sale'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _createAccessoriesOrder(
    Customer customer,
    Map<Accessory, int> selectedItems,
    double total,
  ) async {
    try {
      final l10n = AppLocalizations.of(context);
      final serialCode = SerialCodeGenerator.generate();

      // Create order accessories list
      final orderAccessories = selectedItems.entries.map((entry) {
        return OrderAccessory(
          id: const Uuid().v4(),
          orderId: '', // Will be set after order creation
          accessoryId: entry.key.id,
          accessoryNameAr: entry.key.nameAr,
          accessoryNameEn: entry.key.nameEn,
          quantity: entry.value,
          unitPrice: entry.key.price,
          totalPrice: entry.key.price * entry.value,
        );
      }).toList();

      await ref.read(repairOrderRepositoryProvider).createWithSerial(
            serialCode: serialCode,
            customerId: customer.id,
            laptopType:
                l10n.isArabic ? 'بيع إكسسوارات فقط' : 'Accessories Only',
            problemDescription: l10n.isArabic
                ? 'لا يوجد إصلاح - بيع إكسسوارات'
                : 'No repair - Accessories sale',
            totalCost: total,
            initialPayment: total, // Assume full payment
            accessories: orderAccessories,
          );

      _refreshAll();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.saveSuccess),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}

class OrderCard extends ConsumerWidget {
  final RepairOrder order;
  final VoidCallback onUpdate;

  const OrderCard({super.key, required this.order, required this.onUpdate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OrderDetailsScreen(orderId: order.id),
            ),
          ).then((_) => onUpdate());
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Serial Code with copy button
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.qr_code, size: 16, color: Colors.blue),
                        const SizedBox(width: 4),
                        Text(
                          SerialCodeGenerator.formatSerialCode(
                              order.serialCode),
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 4),
                        InkWell(
                          onTap: () {
                            Clipboard.setData(
                                ClipboardData(text: order.serialCode));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(l10n.isArabic
                                    ? 'تم نسخ الكود'
                                    : 'Serial code copied'),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                          child: const Icon(Icons.copy,
                              size: 14, color: Colors.blue),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(order.status).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      l10n.isArabic ? order.status.nameAr : order.status.nameEn,
                      style: TextStyle(
                        color: _getStatusColor(order.status),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    DateFormat('yyyy-MM-dd').format(order.createdAt),
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Show customer/dealer name with laptop type
              FutureBuilder<String>(
                future: _getOrderOwnerName(ref, order),
                builder: (context, snapshot) {
                  final ownerName = snapshot.data ?? '';
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (ownerName.isNotEmpty)
                        Text(
                          ownerName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue,
                          ),
                        ),
                      Text(
                        order.laptopType,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 4),
              Text(
                order.problemDescription,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${l10n.repairCost}: ${l10n.currency(order.totalCost)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${l10n.paidAmount}: ${l10n.currency(order.paidAmount)}',
                        style: TextStyle(color: Colors.green[700]),
                      ),
                    ],
                  ),
                  if (order.remainingAmount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${l10n.remainingAmount}: ${l10n.currency(order.remainingAmount)}',
                        style: TextStyle(
                          color: Colors.red[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.inProgress:
        return Colors.blue;
      case OrderStatus.completed:
        return Colors.green;
      case OrderStatus.delivered:
        return Colors.teal;
    }
  }
}
