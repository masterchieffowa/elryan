import 'package:elryan/core/database/database_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../domain/models/models.dart';
import '../../../data/repositories/dealer_repository.dart';

// Dealer Provider
final dealerRepositoryProvider = Provider((ref) => DealerRepository());

final dealersProvider = FutureProvider<List<Dealer>>((ref) async {
  final repo = ref.watch(dealerRepositoryProvider);
  return await repo.getAll();
});

final dealerOrdersProvider = FutureProvider.family<List<RepairOrder>, String>(
  (ref, dealerId) async {
    final database = await DatabaseHelper.instance.database;
    final maps = await database.query('repair_orders',
        where: 'dealer_id = ?',
        whereArgs: [dealerId],
        orderBy: 'created_at DESC');

    final orders = <RepairOrder>[];
    for (var map in maps) {
      final order = RepairOrder.fromMap(map);
      orders.add(order);
    }
    return orders;
  },
);

class DealersScreen extends ConsumerStatefulWidget {
  const DealersScreen({super.key});

  @override
  ConsumerState<DealersScreen> createState() => _DealersScreenState();
}

class _DealersScreenState extends ConsumerState<DealersScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final dealersAsync = ref.watch(dealersProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.isArabic ? 'الموزعين' : 'Dealers'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(dealersProvider),
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
                  label: Text(l10n.isArabic ? 'موزع جديد' : 'New Dealer'),
                  onPressed: () => _showDealerDialog(context),
                ),
              ],
            ),
          ),

          // Dealers List
          Expanded(
            child: dealersAsync.when(
              data: (dealers) {
                var filteredDealers = dealers;

                if (_searchQuery.isNotEmpty) {
                  filteredDealers = dealers.where((dealer) {
                    return dealer.name.toLowerCase().contains(_searchQuery) ||
                        dealer.phone.contains(_searchQuery);
                  }).toList();
                }

                if (filteredDealers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.business_outlined,
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
                  itemCount: filteredDealers.length,
                  itemBuilder: (context, index) {
                    return DealerCard(
                      dealer: filteredDealers[index],
                      onEdit: () =>
                          _showDealerDialog(context, filteredDealers[index]),
                      onDelete: () =>
                          _deleteDealer(context, ref, filteredDealers[index]),
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

  Future<void> _showDealerDialog(BuildContext context, [Dealer? dealer]) async {
    final l10n = AppLocalizations.of(context);
    final nameController = TextEditingController(text: dealer?.name);
    final phoneController = TextEditingController(text: dealer?.phone);
    final addressController = TextEditingController(text: dealer?.address);
    final contactPersonController =
        TextEditingController(text: dealer?.contactPerson);
    final emailController = TextEditingController(text: dealer?.email);
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(dealer == null
            ? (l10n.isArabic ? 'موزع جديد' : 'New Dealer')
            : l10n.edit),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: l10n.isArabic ? 'اسم الموزع' : 'Dealer Name',
                    prefixIcon: const Icon(Icons.business),
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
                const SizedBox(height: 12),
                TextField(
                  controller: contactPersonController,
                  decoration: InputDecoration(
                    labelText:
                        '${l10n.isArabic ? "الشخص المسؤول" : "Contact Person"} (${l10n.isArabic ? "اختياري" : "Optional"})',
                    prefixIcon: const Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText:
                        '${l10n.isArabic ? "البريد الإلكتروني" : "Email"} (${l10n.isArabic ? "اختياري" : "Optional"})',
                    prefixIcon: const Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
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
        final repo = ref.read(dealerRepositoryProvider);

        if (dealer == null) {
          await repo.create(
            name: nameController.text,
            phone: phoneController.text,
            address:
                addressController.text.isEmpty ? null : addressController.text,
            contactPerson: contactPersonController.text.isEmpty
                ? null
                : contactPersonController.text,
            email: emailController.text.isEmpty ? null : emailController.text,
          );
        } else {
          await repo.update(dealer.copyWith(
            name: nameController.text,
            phone: phoneController.text,
            address:
                addressController.text.isEmpty ? null : addressController.text,
            contactPerson: contactPersonController.text.isEmpty
                ? null
                : contactPersonController.text,
            email: emailController.text.isEmpty ? null : emailController.text,
          ));
        }

        ref.invalidate(dealersProvider);

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

  Future<void> _deleteDealer(
      BuildContext context, WidgetRef ref, Dealer dealer) async {
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
        await ref.read(dealerRepositoryProvider).delete(dealer.id);
        ref.invalidate(dealersProvider);

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
}

class DealerCard extends ConsumerWidget {
  final Dealer dealer;
  final void Function() onEdit;
  final void Function() onDelete;

  const DealerCard({
    super.key,
    required this.dealer,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final ordersAsync = ref.watch(dealerOrdersProvider(dealer.id));

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
          backgroundColor: Colors.blue,
          child: Text(
            dealer.name[0].toUpperCase(),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(dealer.name,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.phone, size: 16),
                const SizedBox(width: 4),
                Text(dealer.phone),
              ],
            ),
            if (dealer.contactPerson != null)
              Row(
                children: [
                  const Icon(Icons.person, size: 16),
                  const SizedBox(width: 4),
                  Text(dealer.contactPerson!),
                ],
              ),
            if (dealer.email != null)
              Row(
                children: [
                  const Icon(Icons.email, size: 16),
                  const SizedBox(width: 4),
                  Text(dealer.email!),
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
                  l10n.isArabic ? 'الأجهزة المرسلة' : 'Submitted Devices',
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
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                l10n.isArabic ? 'عدد الأجهزة' : 'Total Devices',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '${orders.length}',
                                style: TextStyle(
                                  color: Colors.blue[700],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (outstanding > 0) ...[
                          const SizedBox(height: 8),
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
                        ],
                        const SizedBox(height: 12),
                        ...orders.take(3).map((order) {
                          return ListTile(
                            dense: true,
                            title:
                                Text(order.deviceOwnerName ?? order.laptopType),
                            subtitle: Row(
                              children: [
                                Text(order.laptopType),
                                const Text(' - '),
                                Text(
                                  l10n.isArabic
                                      ? order.status.nameAr
                                      : order.status.nameEn,
                                ),
                              ],
                            ),
                            trailing: Text(l10n.currency(order.totalCost)),
                          );
                        }).toList(),
                        if (orders.length > 3)
                          TextButton(
                            onPressed: () {
                              // Navigate to dealer details
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
