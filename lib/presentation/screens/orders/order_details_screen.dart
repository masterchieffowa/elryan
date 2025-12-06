// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../domain/models/models.dart';
import '../../providers/providers.dart';

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
                          Text(
                            order.laptopType,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          _StatusChip(order: order),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${l10n.createdDate}: ${DateFormat('yyyy-MM-dd HH:mm').format(order.createdAt)}',
                        style: TextStyle(color: Colors.grey[600]),
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
                      if (order.accessories.isNotEmpty)
                        _buildSection(
                          context,
                          title: l10n.accessories,
                          child: Column(
                            children: order.accessories.map((acc) {
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
