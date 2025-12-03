import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../domain/models/models.dart';
import '../../providers/providers.dart';

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

  Customer? _selectedCustomer;
  bool _isSaving = false;

  @override
  void dispose() {
    _laptopTypeController.dispose();
    _problemController.dispose();
    _totalCostController.dispose();
    _initialPaymentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final customersAsync = ref.watch(customersProvider);

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
              // Customer Selection
              customersAsync.when(
                data: (customers) => DropdownButtonFormField<Customer>(
                  initialValue: _selectedCustomer,
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
                  if (double.tryParse(value!) == null)
                    return l10n.invalidNumber;
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
                  if (double.tryParse(value!) == null)
                    return l10n.invalidNumber;
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

      await repo.create(
        customerId: _selectedCustomer!.id,
        laptopType: _laptopTypeController.text,
        problemDescription: _problemController.text,
        totalCost: double.parse(_totalCostController.text),
        initialPayment: double.parse(_initialPaymentController.text),
      );

      ref.invalidate(ordersProvider);

      if (mounted) {
        Navigator.pop(context);
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
