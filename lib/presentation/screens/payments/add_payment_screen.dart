import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/payment.dart';
import '../../providers/client_providers.dart';
import '../../providers/debt_providers.dart';
import '../../providers/payment_providers.dart';

class AddPaymentScreen extends ConsumerStatefulWidget {
  final int debtId;
  final int? clientId;

  const AddPaymentScreen({super.key, required this.debtId, this.clientId});

  @override
  ConsumerState<AddPaymentScreen> createState() => _AddPaymentScreenState();
}

class _AddPaymentScreenState extends ConsumerState<AddPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  PaymentMethod _selectedMethod = PaymentMethod.efectivo;
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _savePayment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final amount = double.parse(_amountController.text.replaceAll(',', '.'));
      final debt = await ref.read(debtDetailProvider(widget.debtId).future);
      
      if (debt == null) {
        throw Exception('Deuda no encontrada');
      }

      if (amount > debt.remainingAmount) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('El monto no puede exceder el saldo pendiente'),
            backgroundColor: AppTheme.warningColor,
          ),
        );
        setState(() => _isLoading = false);
        return;
      }

      final payment = Payment(
        debtId: widget.debtId,
        clientId: widget.clientId ?? debt.clientId,
        amount: amount,
        method: _selectedMethod,
        createdAt: DateTime.now(),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );

      await ref.read(debtsProvider.notifier).registerPayment(payment);
      ref.invalidate(debtDetailProvider(widget.debtId));
      ref.invalidate(debtPaymentsProvider(widget.debtId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pago registrado correctamente'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        if (widget.clientId != null) {
          context.go('/clients/${widget.clientId}/debt/${widget.debtId}');
        } else {
          context.go('/debts/${widget.debtId}');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final debtAsync = ref.watch(debtDetailProvider(widget.debtId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Pago'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            if (widget.clientId != null) {
              context.go('/clients/${widget.clientId}/debt/${widget.debtId}');
            } else {
              context.go('/debts/${widget.debtId}');
            }
          },
        ),
      ),
      body: debtAsync.when(
        data: (debt) {
          if (debt == null) {
            return const Center(child: Text('Deuda no encontrada'));
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.payment, size: 40, color: AppTheme.primaryColor),
                          ),
                          const SizedBox(height: 16),
                          Text(debt.concept, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text(
                            'Pendiente: \$${debt.remainingAmount.toStringAsFixed(2)}',
                            style: TextStyle(fontSize: 16, color: AppTheme.warningColor, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Datos del Pago', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<PaymentMethod>(
                            value: _selectedMethod,
                            decoration: const InputDecoration(
                              labelText: 'Método de pago',
                              prefixIcon: Icon(Icons.payment),
                            ),
                            items: PaymentMethod.values.map((method) {
                              return DropdownMenuItem(
                                value: method,
                                child: Text(method.displayName),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) setState(() => _selectedMethod = value);
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _amountController,
                            decoration: const InputDecoration(
                              labelText: 'Monto *',
                              prefixIcon: Icon(Icons.attach_money),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'El monto es requerido';
                              final amount = double.tryParse(value.replaceAll(',', '.'));
                              if (amount == null || amount <= 0) return 'Monto inválido';
                              if (amount > debt.remainingAmount) return 'Monto mayor al pendiente';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _notesController,
                            decoration: const InputDecoration(
                              labelText: 'Notas',
                              prefixIcon: Icon(Icons.note),
                            ),
                            maxLines: 2,
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () {
                                _amountController.text = debt.remainingAmount.toStringAsFixed(2);
                              },
                              child: const Text('Pagar total pendiente'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _savePayment,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppTheme.successColor,
                    ),
                    child: _isLoading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Registrar Pago', style: TextStyle(fontSize: 16)),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
