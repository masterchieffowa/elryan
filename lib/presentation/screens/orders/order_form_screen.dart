// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/utils/serial_generator.dart';
import '../../../domain/models/models.dart';
import '../../providers/providers.dart';
import '../dealers/dealers_screen.dart';

class OrderFormScreen extends ConsumerStatefulWidget {
  final RepairOrder? order;

  const OrderFormScreen({super.key, this.order});

  @override
  ConsumerState<OrderFormScreen> createState() => _OrderFormScreenState();
}

class _OrderFormScreenState extends ConsumerState<OrderFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _laptopTypeController = TextEditingController();
  final _problemController = TextEditingController();
  final _totalCostController = TextEditingController();
  final _initialPaymentController = TextEditingController();
  final _deviceOwnerNameController = TextEditingController();

  Customer? _selectedCustomer;
  Dealer? _selectedDealer;
  bool _isSaving = false;
  bool _isForDealer = false;

  @override
  void dispose() {
    _laptopTypeController.dispose();
    _problemController.dispose();
    _totalCostController.dispose();
    _initialPaymentController.dispose();
    _deviceOwnerNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final customersAsync = ref.watch(customersProvider);
    final dealersAsync = ref.watch(dealersProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.newOrder),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order Type Selection
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.isArabic ? 'نوع الطلب' : 'Order Type',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<bool>(
                              title: Text(l10n.isArabic
                                  ? 'عميل مباشر'
                                  : 'Direct Customer'),
                              value: false,
                              groupValue: _isForDealer,
                              onChanged: (value) {
                                setState(() {
                                  _isForDealer = value!;
                                  _selectedCustomer = null;
                                  _selectedDealer = null;
                                });
                              },
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<bool>(
                              title: Text(
                                  l10n.isArabic ? 'من موزع' : 'From Dealer'),
                              value: true,
                              groupValue: _isForDealer,
                              onChanged: (value) {
                                setState(() {
                                  _isForDealer = value!;
                                  _selectedCustomer = null;
                                  _selectedDealer = null;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Customer or Dealer Selection
              if (!_isForDealer)
                customersAsync.when(
                  data: (customers) => DropdownButtonFormField<Customer>(
                    value: _selectedCustomer,
                    decoration: InputDecoration(labelText: l10n.customerName),
                    items: customers.map((customer) {
                      return DropdownMenuItem(
                        value: customer,
                        child: Text('${customer.name} - ${customer.phone}'),
                      );
                    }).toList(),
                    onChanged: (customer) {
                      setState(() => _selectedCustomer = customer);
                    },
                    validator: (value) =>
                        value == null ? l10n.fieldRequired : null,
                  ),
                  loading: () => const CircularProgressIndicator(),
                  error: (_, __) => const SizedBox(),
                )
              else
                dealersAsync.when(
                  data: (dealers) => Column(
                    children: [
                      DropdownButtonFormField<Dealer>(
                        value: _selectedDealer,
                        decoration: InputDecoration(
                            labelText: l10n.isArabic ? 'الموزع' : 'Dealer'),
                        items: dealers.map((dealer) {
                          return DropdownMenuItem(
                            value: dealer,
                            child: Text('${dealer.name} - ${dealer.phone}'),
                          );
                        }).toList(),
                        onChanged: (dealer) {
                          setState(() => _selectedDealer = dealer);
                        },
                        validator: (value) =>
                            value == null ? l10n.fieldRequired : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _deviceOwnerNameController,
                        decoration: InputDecoration(
                          labelText: l10n.isArabic
                              ? 'اسم صاحب الجهاز'
                              : 'Device Owner Name',
                          prefixIcon: const Icon(Icons.person),
                        ),
                        validator: (value) =>
                            value?.isEmpty ?? true ? l10n.fieldRequired : null,
                      ),
                    ],
                  ),
                  loading: () => const CircularProgressIndicator(),
                  error: (_, __) => const SizedBox(),
                ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _laptopTypeController,
                decoration: InputDecoration(labelText: l10n.laptopType),
                validator: (value) =>
                    value?.isEmpty ?? true ? l10n.fieldRequired : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _problemController,
                decoration: InputDecoration(labelText: l10n.problemDescription),
                maxLines: 3,
                validator: (value) =>
                    value?.isEmpty ?? true ? l10n.fieldRequired : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _totalCostController,
                decoration: InputDecoration(labelText: l10n.repairCost),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))
                ],
                validator: (value) {
                  if (value?.isEmpty ?? true) return l10n.fieldRequired;
                  if (double.tryParse(value!) == null) {
                    return l10n.invalidNumber;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _initialPaymentController,
                decoration: InputDecoration(labelText: l10n.paidAmount),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))
                ],
                validator: (value) {
                  if (value?.isEmpty ?? true) return l10n.fieldRequired;
                  if (double.tryParse(value!) == null) {
                    return l10n.invalidNumber;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const CircularProgressIndicator()
                      : Text(l10n.save),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final repo = ref.read(repairOrderRepositoryProvider);
      final serialCode = SerialCodeGenerator.generate();

      await repo.createWithSerial(
        serialCode: serialCode,
        customerId: _isForDealer ? null : _selectedCustomer!.id,
        dealerId: _isForDealer ? _selectedDealer!.id : null,
        deviceOwnerName: _isForDealer ? _deviceOwnerNameController.text : null,
        laptopType: _laptopTypeController.text,
        problemDescription: _problemController.text,
        totalCost: double.parse(_totalCostController.text),
        initialPayment: double.parse(_initialPaymentController.text),
      );

      ref.invalidate(ordersProvider);

      if (mounted) {
        // Show success with serial code
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(AppLocalizations.of(context).success),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(AppLocalizations.of(context).isArabic
                    ? 'تم إنشاء الطلب بنجاح'
                    : 'Order created successfully'),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context).isArabic
                      ? 'رقم التسلسل'
                      : 'Serial Code',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    SerialCodeGenerator.formatSerialCode(serialCode),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: Text(AppLocalizations.of(context).close),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}
