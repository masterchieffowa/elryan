import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/database/database_helper.dart';
import '../../../domain/models/models.dart';
import '../../../core/services/receipt_printer.dart';
import '../../providers/providers.dart';
import '../dealers/dealers_screen.dart';

class OrderDetailsScreen extends ConsumerWidget {
  final String orderId;

  const OrderDetailsScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final orderAsync = ref.watch(orderDetailsProvider(orderId));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.orderDetails),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () =>
                _showEditOrderDialog(context, ref, orderAsync.value),
            tooltip: l10n.edit,
          ),
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () => _printReceipt(context, ref, orderAsync.value),
            tooltip: l10n.isArabic ? 'طباعة' : 'Print',
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
      body: orderAsync.when(
        data: (order) {
          if (order == null) {
            return Center(child: Text(l10n.noData));
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                // Order Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  color: _getStatusColor(order.status).withOpacity(0.1),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  order.laptopType,
                                  style:
                                      Theme.of(context).textTheme.headlineSmall,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${l10n.createdDate}: ${DateFormat('yyyy-MM-dd HH:mm').format(order.createdAt)}',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                          _StatusChip(order: order),
                        ],
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Customer Info
                      if (order.customerId != null)
                        _buildSection(
                          context,
                          title: l10n.customers,
                          child: _CustomerInfo(customerId: order.customerId!),
                        )
                      else if (order.dealerId != null)
                        _buildSection(
                          context,
                          title: l10n.dealers,
                          child: _DealerInfo(
                            dealerId: order.dealerId!,
                            deviceOwnerName: order.deviceOwnerName,
                          ),
                        ),
                      const SizedBox(height: 24),

                      // Problem Description
                      _buildSection(
                        context,
                        title: l10n.problemDescription,
                        child: Text(order.problemDescription),
                      ),
                      const SizedBox(height: 24),

                      // Financial Summary
                      _buildSection(
                        context,
                        title: l10n.payments,
                        child: Column(
                          children: [
                            _InfoRow(
                              label: l10n.repairCost,
                              value: l10n.currency(order.totalCost),
                              valueColor: Colors.blue,
                            ),
                            _InfoRow(
                              label: l10n.paidAmount,
                              value: l10n.currency(order.paidAmount),
                              valueColor: Colors.green,
                            ),
                            _InfoRow(
                              label: l10n.remainingAmount,
                              value: l10n.currency(order.remainingAmount),
                              valueColor: order.remainingAmount > 0
                                  ? Colors.red
                                  : Colors.green,
                              bold: true,
                            ),
                            if (order.remainingAmount > 0) ...[
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.payment),
                                  label: Text(l10n.addPayment),
                                  onPressed: () => _showAddPaymentDialog(
                                      context, ref, order),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Accessories
                      _buildSection(
                        context,
                        title: l10n.accessories,
                        child: Column(
                          children: [
                            if (order.accessories.isNotEmpty)
                              ...order.accessories.map((acc) {
                                return Card(
                                  child: ListTile(
                                    title: Text(
                                      l10n.isArabic
                                          ? acc.accessoryNameAr
                                          : acc.accessoryNameEn,
                                    ),
                                    subtitle: Text(
                                      '${acc.quantity} × ${l10n.currency(acc.unitPrice)}',
                                    ),
                                    trailing: Text(
                                      l10n.currency(acc.totalPrice),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.add_shopping_cart),
                                label: Text(l10n.isArabic
                                    ? 'إضافة إكسسوارات'
                                    : 'Add Accessories'),
                                onPressed: () => _showAddAccessoriesDialog(
                                    context, ref, order),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Payment History
                      if (order.payments.isNotEmpty)
                        _buildSection(
                          context,
                          title: l10n.paymentHistory,
                          child: Column(
                            children: order.payments.map((payment) {
                              return Card(
                                child: ListTile(
                                  leading: const Icon(Icons.payment,
                                      color: Colors.green),
                                  title: Text(l10n.currency(payment.amount)),
                                  subtitle: Text(
                                    DateFormat('yyyy-MM-dd HH:mm')
                                        .format(payment.paymentDate),
                                  ),
                                  trailing: payment.notes != null
                                      ? Tooltip(
                                          message: payment.notes!,
                                          child: const Icon(Icons.note),
                                        )
                                      : null,
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildSection(BuildContext context,
      {required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        child,
      ],
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

  Future<void> _showEditOrderDialog(
    BuildContext context,
    WidgetRef ref,
    RepairOrder? order,
  ) async {
    if (order == null) return;

    final l10n = AppLocalizations.of(context);
    final laptopTypeController = TextEditingController(text: order.laptopType);
    final problemController =
        TextEditingController(text: order.problemDescription);
    final notesController = TextEditingController(text: order.notes);
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.edit),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: laptopTypeController,
                  decoration: InputDecoration(labelText: l10n.laptopType),
                  validator: (value) =>
                      value?.isEmpty ?? true ? l10n.fieldRequired : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: problemController,
                  decoration:
                      InputDecoration(labelText: l10n.problemDescription),
                  maxLines: 3,
                  validator: (value) =>
                      value?.isEmpty ?? true ? l10n.fieldRequired : null,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesController,
                  decoration: InputDecoration(
                    labelText:
                        '${l10n.notes} (${l10n.isArabic ? "اختياري" : "Optional"})',
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, true);
              }
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        // Update order in database using DatabaseHelper
        final dbHelper = DatabaseHelper.instance;
        final database = await dbHelper.database;

        await database.update(
          'repair_orders',
          {
            'laptop_type': laptopTypeController.text,
            'problem_description': problemController.text,
            'notes': notesController.text.isEmpty ? null : notesController.text,
          },
          where: 'id = ?',
          whereArgs: [order.id],
        );

        ref.invalidate(orderDetailsProvider(orderId));
        ref.invalidate(ordersProvider);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.saveSuccess),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _showAddAccessoriesDialog(
    BuildContext context,
    WidgetRef ref,
    RepairOrder order,
  ) async {
    final l10n = AppLocalizations.of(context);
    final accessoriesAsync = ref.read(accessoriesProvider);

    if (!accessoriesAsync.hasValue) return;

    final accessories = accessoriesAsync.value!;
    final selectedItems = <Accessory, int>{};

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final total = selectedItems.entries.fold<double>(
            0,
            (sum, entry) => sum + (entry.key.price * entry.value),
          );

          return AlertDialog(
            title: Text(l10n.isArabic
                ? 'إضافة إكسسوارات للطلب'
                : 'Add Accessories to Order'),
            content: SizedBox(
              width: 500,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 300,
                    child: ListView.builder(
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
                onPressed: () => Navigator.pop(context, false),
                child: Text(l10n.cancel),
              ),
              ElevatedButton(
                onPressed: selectedItems.isEmpty
                    ? null
                    : () => Navigator.pop(context, true),
                child: Text(l10n.add),
              ),
            ],
          );
        },
      ),
    );

    if (result == true && selectedItems.isNotEmpty) {
      try {
        final dbHelper = DatabaseHelper.instance;
        final database = await dbHelper.database;
        final uuid = const Uuid();

        // Add accessories to order
        for (var entry in selectedItems.entries) {
          final accessory = entry.key;
          final quantity = entry.value;

          await database.insert('order_accessories', {
            'id': uuid.v4(),
            'order_id': order.id,
            'accessory_id': accessory.id,
            'accessory_name_ar': accessory.nameAr,
            'accessory_name_en': accessory.nameEn,
            'quantity': quantity,
            'unit_price': accessory.price,
            'total_price': accessory.price * quantity,
          });

          // Update stock
          await database.rawUpdate(
            'UPDATE accessories SET stock_quantity = stock_quantity - ? WHERE id = ?',
            [quantity, accessory.id],
          );
        }

        // Update order total cost
        final newTotal = order.totalCost +
            selectedItems.entries.fold<double>(
              0,
              (sum, entry) => sum + (entry.key.price * entry.value),
            );

        await database.update(
          'repair_orders',
          {'total_cost': newTotal},
          where: 'id = ?',
          whereArgs: [order.id],
        );

        ref.invalidate(orderDetailsProvider(orderId));
        ref.invalidate(ordersProvider);
        ref.invalidate(accessoriesProvider);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.saveSuccess),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _printReceipt(
    BuildContext context,
    WidgetRef ref,
    RepairOrder? order,
  ) async {
    if (order == null) return;

    try {
      Customer? customer;
      Dealer? dealer;

      if (order.customerId != null) {
        final customersAsync = ref.read(customersProvider);
        if (customersAsync.hasValue) {
          customer =
              customersAsync.value!.firstWhere((c) => c.id == order.customerId);
        }
      } else if (order.dealerId != null) {
        final dealersAsync = ref.read(dealersProvider);
        if (dealersAsync.hasValue) {
          dealer =
              dealersAsync.value!.firstWhere((d) => d.id == order.dealerId);
        }
      }

      await ReceiptPrinter.printReceipt(order, customer, dealer);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Print error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showAddPaymentDialog(
    BuildContext context,
    WidgetRef ref,
    RepairOrder order,
  ) async {
    final l10n = AppLocalizations.of(context);
    final amountController = TextEditingController();
    final notesController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.addPayment),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${l10n.remainingAmount}: ${l10n.currency(order.remainingAmount)}',
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: amountController,
                decoration: InputDecoration(
                  labelText: l10n.paymentAmount,
                  prefixIcon: const Icon(Icons.attach_money),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))
                ],
                validator: (value) {
                  if (value?.isEmpty ?? true) return l10n.fieldRequired;
                  final amount = double.tryParse(value!);
                  if (amount == null) return l10n.invalidNumber;
                  if (amount <= 0 || amount > order.remainingAmount) {
                    return l10n.isArabic ? 'المبلغ غير صحيح' : 'Invalid amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                decoration: InputDecoration(
                  labelText:
                      '${l10n.notes} (${l10n.isArabic ? "اختياري" : "Optional"})',
                  prefixIcon: const Icon(Icons.note),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, true);
              }
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );

    if (result == true && amountController.text.isNotEmpty) {
      try {
        await ref.read(repairOrderRepositoryProvider).addPayment(
              orderId: order.id,
              amount: double.parse(amountController.text),
              notes: notesController.text.isEmpty ? null : notesController.text,
            );

        ref.invalidate(orderDetailsProvider(orderId));
        ref.invalidate(ordersProvider);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.saveSuccess),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.delete),
        content: Text(l10n.deleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        await ref.read(repairOrderRepositoryProvider).delete(orderId);
        ref.invalidate(ordersProvider);

        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.deleteSuccess),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }
}

// Customer Info Widget
class _CustomerInfo extends ConsumerWidget {
  final String customerId;

  const _CustomerInfo({required this.customerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final customersAsync = ref.watch(customersProvider);

    return customersAsync.when(
      data: (customers) {
        final customer = customers.firstWhere((c) => c.id == customerId);
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoRow(label: l10n.customerName, value: customer.name),
                _InfoRow(label: l10n.phoneNumber, value: customer.phone),
                if (customer.address != null)
                  _InfoRow(label: l10n.address, value: customer.address!),
              ],
            ),
          ),
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (_, __) => Text(l10n.error),
    );
  }
}

// Dealer Info Widget
class _DealerInfo extends ConsumerWidget {
  final String dealerId;
  final String? deviceOwnerName;

  const _DealerInfo({required this.dealerId, this.deviceOwnerName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final dealersAsync = ref.watch(dealersProvider);

    return dealersAsync.when(
      data: (dealers) {
        final dealer = dealers.firstWhere((d) => d.id == dealerId);
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoRow(label: l10n.dealerName, value: dealer.name),
                _InfoRow(label: l10n.phoneNumber, value: dealer.phone),
                if (deviceOwnerName != null)
                  _InfoRow(
                      label: l10n.deviceOwnerName, value: deviceOwnerName!),
                if (dealer.contactPerson != null)
                  _InfoRow(
                      label: l10n.contactPerson, value: dealer.contactPerson!),
              ],
            ),
          ),
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (_, __) => Text(l10n.error),
    );
  }
}

// Info Row Widget
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool bold;

  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey[600]),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              color: valueColor,
              fontSize: bold ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }
}

// Status Chip Widget
class _StatusChip extends ConsumerWidget {
  final RepairOrder order;

  const _StatusChip({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return PopupMenuButton<OrderStatus>(
      initialValue: order.status,
      onSelected: (status) async {
        try {
          await ref
              .read(repairOrderRepositoryProvider)
              .updateStatus(order.id, status);
          ref.invalidate(orderDetailsProvider(order.id));
          ref.invalidate(ordersProvider);

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.saveSuccess),
                backgroundColor: Colors.green,
              ),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
            );
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: _getStatusColor(order.status),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.isArabic ? order.status.nameAr : order.status.nameEn,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, color: Colors.white),
          ],
        ),
      ),
      itemBuilder: (context) {
        return OrderStatus.values.map((status) {
          return PopupMenuItem(
            value: status,
            child: Text(l10n.isArabic ? status.nameAr : status.nameEn),
          );
        }).toList();
      },
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
