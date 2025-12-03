// lib/presentation/screens/accessories/accessories_screen.dart
// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../domain/models/models.dart';
import '../../providers/providers.dart';

class AccessoriesScreen extends ConsumerWidget {
  const AccessoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final accessoriesAsync = ref.watch(accessoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.accessories),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(accessoriesProvider),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.isArabic ? 'إدارة المخزون' : 'Inventory Management',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: Text(l10n.newAccessory),
                  onPressed: () => _showAccessoryDialog(context, ref),
                ),
              ],
            ),
          ),
          Expanded(
            child: accessoriesAsync.when(
              data: (accessories) {
                if (accessories.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined,
                            size: 80, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(l10n.noData,
                            style: TextStyle(color: Colors.grey[600])),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 300,
                    childAspectRatio: 1.2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: accessories.length,
                  itemBuilder: (context, index) {
                    return AccessoryCard(accessory: accessories[index]);
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

  Future<void> _showAccessoryDialog(BuildContext context, WidgetRef ref,
      [Accessory? accessory]) async {
    final l10n = AppLocalizations.of(context);
    final nameArController = TextEditingController(text: accessory?.nameAr);
    final nameEnController = TextEditingController(text: accessory?.nameEn);
    final priceController =
        TextEditingController(text: accessory?.price.toString());
    final stockController =
        TextEditingController(text: accessory?.stockQuantity.toString());
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(accessory == null ? l10n.newAccessory : l10n.edit),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameArController,
                  decoration: InputDecoration(labelText: l10n.accessoryNameAr),
                  validator: (value) =>
                      value?.isEmpty ?? true ? l10n.fieldRequired : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: nameEnController,
                  decoration: InputDecoration(labelText: l10n.accessoryNameEn),
                  validator: (value) =>
                      value?.isEmpty ?? true ? l10n.fieldRequired : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: priceController,
                  decoration: InputDecoration(labelText: l10n.price),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return l10n.fieldRequired;
                    if (double.tryParse(value!) == null)
                      return l10n.invalidNumber;
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: stockController,
                  decoration: InputDecoration(labelText: l10n.stockQuantity),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return l10n.fieldRequired;
                    if (int.tryParse(value!) == null) return l10n.invalidNumber;
                    return null;
                  },
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
        final repo = ref.read(accessoryRepositoryProvider);

        if (accessory == null) {
          await repo.create(
            nameAr: nameArController.text,
            nameEn: nameEnController.text,
            price: double.parse(priceController.text),
            stockQuantity: int.parse(stockController.text),
          );
        } else {
          await repo.update(accessory.copyWith(
            nameAr: nameArController.text,
            nameEn: nameEnController.text,
            price: double.parse(priceController.text),
            stockQuantity: int.parse(stockController.text),
          ));
        }

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
}

class AccessoryCard extends ConsumerWidget {
  final Accessory accessory;

  const AccessoryCard({super.key, required this.accessory});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final isLowStock = accessory.stockQuantity <= 5;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    l10n.isArabic ? accessory.nameAr : accessory.nameEn,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                PopupMenuButton(
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      child: Text(l10n.edit),
                      onTap: () {
                        Future.delayed(
                          const Duration(milliseconds: 100),
                          () => _showAccessoryDialog(context, ref, accessory),
                        );
                      },
                    ),
                    PopupMenuItem(
                      child: Text(l10n.delete),
                      onTap: () => _deleteAccessory(context, ref, accessory),
                    ),
                  ],
                ),
              ],
            ),
            const Spacer(),
            Text(
              '${l10n.price}: ${l10n.currency(accessory.price)}',
              style: const TextStyle(fontSize: 16, color: Colors.blue),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isLowStock ? Colors.red[50] : Colors.green[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isLowStock ? Icons.warning : Icons.check_circle,
                    size: 16,
                    color: isLowStock ? Colors.red : Colors.green,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${l10n.stockQuantity}: ${accessory.stockQuantity}',
                    style: TextStyle(
                      color: isLowStock ? Colors.red[700] : Colors.green[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteAccessory(
      BuildContext context, WidgetRef ref, Accessory accessory) async {
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
        await ref.read(accessoryRepositoryProvider).delete(accessory.id);
        ref.invalidate(accessoriesProvider);

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
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _showAccessoryDialog(
      BuildContext context, WidgetRef ref, Accessory accessory) async {
    // Same implementation as in AccessoriesScreen
  }
}
