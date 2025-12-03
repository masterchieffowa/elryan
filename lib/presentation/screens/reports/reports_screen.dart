import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../../core/l10n/app_localizations.dart';
import '../../../domain/models/models.dart';
import '../../providers/providers.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.reports),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Range Selector
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.selectDateRange,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.calendar_today),
                            label: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(l10n.from),
                                Text(
                                  DateFormat('yyyy-MM-dd').format(_startDate),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            onPressed: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: _startDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(),
                              );
                              if (date != null) {
                                setState(() => _startDate = date);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.calendar_today),
                            label: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(l10n.to),
                                Text(
                                  DateFormat('yyyy-MM-dd').format(_endDate),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            onPressed: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: _endDate,
                                firstDate: _startDate,
                                lastDate: DateTime.now(),
                              );
                              if (date != null) {
                                setState(() => _endDate = date);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Revenue Report
            Text(
              l10n.revenueReport,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            _RevenueReport(startDate: _startDate, endDate: _endDate),
            const SizedBox(height: 24),

            // Pending Orders
            Text(
              l10n.pendingOrdersReport,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            const _PendingOrdersReport(),
            const SizedBox(height: 24),

            // Outstanding Balances
            Text(
              l10n.customerBalances,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            const _OutstandingBalancesReport(),
          ],
        ),
      ),
    );
  }
}

class _RevenueReport extends ConsumerWidget {
  final DateTime startDate;
  final DateTime endDate;

  const _RevenueReport({
    required this.startDate,
    required this.endDate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final ordersAsync = ref.watch(ordersProvider);

    return ordersAsync.when(
      data: (allOrders) {
        final orders = allOrders.where((order) {
          return order.createdAt.isAfter(startDate) &&
              order.createdAt.isBefore(endDate.add(const Duration(days: 1)));
        }).toList();

        final totalRevenue =
            orders.fold<double>(0, (sum, order) => sum + order.totalCost);
        final totalPaid =
            orders.fold<double>(0, (sum, order) => sum + order.paidAmount);
        final outstanding = totalRevenue - totalPaid;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _StatRow(
                  label: l10n.totalOrders,
                  value: '${orders.length}',
                  icon: Icons.receipt,
                ),
                const Divider(),
                _StatRow(
                  label: l10n.totalRevenue,
                  value: l10n.currency(totalRevenue),
                  icon: Icons.attach_money,
                  valueColor: Colors.blue,
                ),
                _StatRow(
                  label: l10n.paidAmount,
                  value: l10n.currency(totalPaid),
                  icon: Icons.check_circle,
                  valueColor: Colors.green,
                ),
                _StatRow(
                  label: l10n.outstandingBalance,
                  value: l10n.currency(outstanding),
                  icon: Icons.warning,
                  valueColor: Colors.red,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.file_download),
                    label: Text(l10n.exportToCSV),
                    onPressed: () => _exportToCSV(context, orders),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (error, stack) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Error: $error'),
        ),
      ),
    );
  }

  Future<void> _exportToCSV(
      BuildContext context, List<RepairOrder> orders) async {
    final l10n = AppLocalizations.of(context);

    try {
      List<List<dynamic>> rows = [
        [
          'Order ID',
          'Date',
          'Customer ID',
          'Laptop Type',
          'Problem',
          'Status',
          'Total Cost',
          'Paid',
          'Remaining',
        ],
      ];

      for (var order in orders) {
        rows.add([
          order.id.substring(0, 8),
          DateFormat('yyyy-MM-dd').format(order.createdAt),
          order.customerId.substring(0, 8),
          order.laptopType,
          order.problemDescription,
          l10n.isArabic ? order.status.nameAr : order.status.nameEn,
          order.totalCost,
          order.paidAmount,
          order.remainingAmount,
        ]);
      }

      String csv = const ListToCsvConverter().convert(rows);

      String? outputPath = await FilePicker.platform.saveFile(
        dialogTitle: l10n.exportToCSV,
        fileName:
            'revenue_report_${DateFormat('yyyy-MM-dd').format(DateTime.now())}.csv',
      );

      if (outputPath != null) {
        await File(outputPath).writeAsString(csv);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.saveSuccess),
              backgroundColor: Colors.green,
            ),
          );
        }
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

class _PendingOrdersReport extends ConsumerWidget {
  const _PendingOrdersReport();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final pendingOrdersAsync =
        ref.watch(ordersByStatusProvider(OrderStatus.pending));

    return pendingOrdersAsync.when(
      data: (orders) {
        if (orders.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Center(child: Text(l10n.noData)),
            ),
          );
        }

        return Card(
          child: Column(
            children: orders.map((order) {
              return ListTile(
                title: Text(order.laptopType),
                subtitle: Text(order.problemDescription),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(l10n.currency(order.totalCost)),
                    Text(
                      DateFormat('yyyy-MM-dd').format(order.createdAt),
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      },
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (error, stack) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Error: $error'),
        ),
      ),
    );
  }
}

class _OutstandingBalancesReport extends ConsumerWidget {
  const _OutstandingBalancesReport();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final ordersAsync = ref.watch(ordersProvider);
    final customersAsync = ref.watch(customersProvider);

    return ordersAsync.when(
      data: (orders) {
        return customersAsync.when(
          data: (customers) {
            final customerBalances = <String, double>{};

            for (var order in orders) {
              if (order.remainingAmount > 0) {
                customerBalances[order.customerId] =
                    (customerBalances[order.customerId] ?? 0) +
                        order.remainingAmount;
              }
            }

            if (customerBalances.isEmpty) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(child: Text(l10n.noData)),
                ),
              );
            }

            final sortedEntries = customerBalances.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value));

            return Card(
              child: Column(
                children: sortedEntries.map((entry) {
                  final customer =
                      customers.firstWhere((c) => c.id == entry.key);
                  return ListTile(
                    leading: CircleAvatar(
                      child: Text(customer.name[0].toUpperCase()),
                    ),
                    title: Text(customer.name),
                    subtitle: Text(customer.phone),
                    trailing: Text(
                      l10n.currency(entry.value),
                      style: TextStyle(
                        color: Colors.red[700],
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  );
                }).toList(),
              ),
            );
          },
          loading: () => const CircularProgressIndicator(),
          error: (_, __) => Text(l10n.error),
        );
      },
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (error, stack) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Error: $error'),
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;

  const _StatRow({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
