import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/debt.dart';
import '../../providers/client_providers.dart';
import '../../providers/debt_providers.dart';

class AddDebtScreen extends ConsumerStatefulWidget {
  final int? clientId;

  const AddDebtScreen({super.key, this.clientId});

  @override
  ConsumerState<AddDebtScreen> createState() => _AddDebtScreenState();
}

class _AddDebtScreenState extends ConsumerState<AddDebtScreen> {
  final _formKey = GlobalKey<FormState>();
  final _conceptController = TextEditingController();
  final _amountController = TextEditingController();
  final _interestController = TextEditingController();
  DateTime? _dueDate;
  int? _selectedClientId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedClientId = widget.clientId;
  }

  @override
  void dispose() {
    _conceptController.dispose();
    _amountController.dispose();
    _interestController.dispose();
    super.dispose();
  }

  Future<void> _selectDueDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (date != null) {
      setState(() => _dueDate = date);
    }
  }

  Future<void> _saveDebt() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedClientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona un cliente'),
          backgroundColor: AppTheme.warningColor,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final amount = double.parse(_amountController.text.replaceAll(',', '.'));
      double? interest;
      if (_interestController.text.isNotEmpty) {
        interest = double.parse(_interestController.text.replaceAll(',', '.'));
      }

      final debt = Debt(
        clientId: _selectedClientId!,
        concept: _conceptController.text.trim(),
        totalAmount: amount,
        dueDate: _dueDate,
        interestRate: interest,
        createdAt: DateTime.now(),
      );

      await ref.read(debtsProvider.notifier).addDebt(debt);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Deuda registrada correctamente'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        if (widget.clientId != null) {
          context.go('/clients/$widget.clientId');
        } else {
          context.go('/debts');
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
    final clients = ref.watch(clientsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva Deuda'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            if (widget.clientId != null) {
              context.go('/clients/$widget.clientId');
            } else {
              context.go('/debts');
            }
          },
        ),
      ),
      body: SingleChildScrollView(
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Datos de la Deuda',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      if (widget.clientId == null)
                        clients.when(
                          data: (clientList) {
                            if (clientList.isEmpty) {
                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppTheme.warningColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  children: [
                                    const Text('No hay clientes registrados'),
                                    const SizedBox(height: 8),
                                    ElevatedButton(
                                      onPressed: () => context.go('/clients/add'),
                                      child: const Text('Agregar Cliente'),
                                    ),
                                  ],
                                ),
                              );
                            }
                            return DropdownButtonFormField<int>(
                              value: _selectedClientId,
                              decoration: const InputDecoration(
                                labelText: 'Cliente *',
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                              items: clientList.map((client) {
                                return DropdownMenuItem(
                                  value: client.id,
                                  child: Text(client.name),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() => _selectedClientId = value);
                              },
                              validator: (value) {
                                if (value == null) return 'Selecciona un cliente';
                                return null;
                              },
                            );
                          },
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (e, _) => Text('Error: $e'),
                        )
                      else
                        FutureBuilder(
                          future: ref.read(selectedClientProvider(widget.clientId!).future),
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: CircleAvatar(
                                  backgroundColor: AppTheme.primaryColor,
                                  child: Text(
                                    snapshot.data!.name.substring(0, 1).toUpperCase(),
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                                title: Text(snapshot.data!.name),
                                subtitle: snapshot.data!.phone != null ? Text(snapshot.data!.phone!) : null,
                              );
                            }
                            return const SizedBox();
                          },
                        ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _conceptController,
                        decoration: const InputDecoration(
                          labelText: 'Concepto *',
                          prefixIcon: Icon(Icons.description_outlined),
                          hintText: 'Ej: Compra de mercancía',
                        ),
                        textCapitalization: TextCapitalization.sentences,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'El concepto es requerido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _amountController,
                        decoration: const InputDecoration(
                          labelText: 'Monto *',
                          prefixIcon: Icon(Icons.attach_money),
                          hintText: '0.00',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'El monto es requerido';
                          }
                          final amount = double.tryParse(value.replaceAll(',', '.'));
                          if (amount == null || amount <= 0) {
                            return 'Monto inválido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _interestController,
                        decoration: const InputDecoration(
                          labelText: 'Interés (%)',
                          prefixIcon: Icon(Icons.percent),
                          hintText: 'Opcional',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.calendar_today),
                        title: Text(
                          _dueDate != null
                              ? 'Vence: ${DateFormat('dd/MM/yyyy').format(_dueDate!)}'
                              : 'Seleccionar fecha de vencimiento',
                        ),
                        trailing: _dueDate != null
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () => setState(() => _dueDate = null),
                              )
                            : null,
                        onTap: _selectDueDate,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveDebt,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Registrar Deuda', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
