import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../domain/models/models.dart';
import '../../providers/providers.dart';

class CustomersScreen extends ConsumerStatefulWidget {
  const CustomersScreen({super.key});

  @override
  ConsumerState<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends ConsumerState<CustomersScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final customersAsync = ref.watch(customersProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.customers),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(customersProvider),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: l10n.search,
                      prefixIcon: const Icon(Icons.search),
                    ),
                    onChanged: (value) {
                      setState(() => _searchQuery = value.toLowerCase());
                    },
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: Text(l10n.newCustomer),
                  onPressed: () => _showCustomerDialog(context),
                ),
              ],
            ),
          ),

          // Customers List
          Expanded(
            child: customersAsync.when(
              data: (customers) {
                var filteredCustomers = customers;

                if (_searchQuery.isNotEmpty) {
                  filteredCustomers = customers.where((customer) {
                    return customer.name.toLowerCase().contains(_searchQuery) ||
                        customer.phone.contains(_searchQuery);
                  }).toList();
                }

                if (filteredCustomers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline,
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
                  itemCount: filteredCustomers.length,
                  itemBuilder: (context, index) {
                    return CustomerCard(
                      customer: filteredCustomers[index],
                      onEdit: () => _showCustomerDialog(
                          context, filteredCustomers[index]),
                      onDelete: () => _deleteCustomer(
                          context, ref, filteredCustomers[index]),
                    );
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

  Future<void> _showCustomerDialog(BuildContext context,
      [Customer? customer]) async {
    final l10n = AppLocalizations.of(context);
    final nameController = TextEditingController(text: customer?.name);
    final phoneController = TextEditingController(text: customer?.phone);
    final addressController = TextEditingController(text: customer?.address);
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(customer == null ? l10n.newCustomer : l10n.edit),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: l10n.customerName,
                  prefixIcon: const Icon(Icons.person),
                ),
                validator: (value) =>
                    value?.isEmpty ?? true ? l10n.fieldRequired : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: phoneController,
                decoration: InputDecoration(
                  labelText: l10n.phoneNumber,
                  prefixIcon: const Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) =>
                    value?.isEmpty ?? true ? l10n.fieldRequired : null,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: addressController,
                decoration: InputDecoration(
                  labelText:
                      '${l10n.address} (${l10n.isArabic ? "اختياري" : "Optional"})',
                  prefixIcon: const Icon(Icons.location_on),
                ),
                maxLines: 2,
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

    if (result == true) {
      try {
        final repo = ref.read(customerRepositoryProvider);

        if (customer == null) {
          await repo.create(
            nameController.text,
            phoneController.text,
            addressController.text.isEmpty ? null : addressController.text,
          );
        } else {
          await repo.update(customer.copyWith(
            name: nameController.text,
            phone: phoneController.text,
            address:
                addressController.text.isEmpty ? null : addressController.text,
          ));
        }

        ref.invalidate(customersProvider);

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
}

Future<void> _deleteCustomer(
    BuildContext context, WidgetRef ref, Customer customer) async {
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
      await ref.read(customerRepositoryProvider).delete(customer.id);
      ref.invalidate(customersProvider);

      if (context.mounted) {
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
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class CustomerCard extends ConsumerWidget {
  final Customer customer;
  final void Function() onEdit;
  final void Function() onDelete;

  const CustomerCard({
    super.key,
    required this.customer,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final ordersAsync = ref.watch(customerOrdersProvider(customer.id));

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            PopupMenuItem(
              child: Row(
                children: [
                  const Icon(Icons.edit),
                  const SizedBox(width: 8),
                  Text(l10n.edit),
                ],
              ),
              onTap: () {
                Future.delayed(
                  const Duration(milliseconds: 100),
                  onEdit,
                );
              },
            ),
            PopupMenuItem(
              onTap: onDelete,
              child: Row(
                children: [
                  const Icon(Icons.delete, color: Colors.red),
                  const SizedBox(width: 8),
                  Text(l10n.delete, style: const TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
        leading: CircleAvatar(
          child: Text(customer.name[0].toUpperCase()),
        ),
        title: Text(customer.name,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.phone, size: 16),
                const SizedBox(width: 4),
                Text(customer.phone),
              ],
            ),
            if (customer.address != null)
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16),
                  const SizedBox(width: 4),
                  Expanded(child: Text(customer.address!)),
                ],
              ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.customerHistory,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                ordersAsync.when(
                  data: (orders) {
                    if (orders.isEmpty) {
                      return Text(l10n.noData);
                    }

                    final outstanding = orders.fold<double>(
                      0,
                      (sum, order) => sum + order.remainingAmount,
                    );

                    return Column(
                      children: [
                        if (outstanding > 0)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  l10n.outstandingBalance,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  l10n.currency(outstanding),
                                  style: TextStyle(
                                    color: Colors.red[700],
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 12),
                        ...orders.take(3).map((order) {
                          return ListTile(
                            dense: true,
                            title: Text(order.laptopType),
                            subtitle: Text(
                              l10n.isArabic
                                  ? order.status.nameAr
                                  : order.status.nameEn,
                            ),
                            trailing: Text(l10n.currency(order.totalCost)),
                          );
                        }).toList(),
                        if (orders.length > 3)
                          TextButton(
                            onPressed: () {
                              // Navigate to customer details
                            },
                            child: Text(
                                '${l10n.isArabic ? "عرض الكل" : "View All"} (${orders.length})'),
                          ),
                      ],
                    );
                  },
                  loading: () => const CircularProgressIndicator(),
                  error: (_, __) => Text(l10n.error),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
