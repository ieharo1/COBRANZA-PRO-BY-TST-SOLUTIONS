import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/debt.dart';
import '../../providers/client_providers.dart';
import '../../providers/debt_providers.dart';
import '../../providers/payment_providers.dart';

class DebtDetailScreen extends ConsumerWidget {
  final int debtId;
  final int? clientId;

  const DebtDetailScreen({super.key, required this.debtId, this.clientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final debtAsync = ref.watch(debtDetailProvider(debtId));
    final paymentsAsync = ref.watch(debtPaymentsProvider(debtId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de Deuda'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (clientId != null) {
              context.go('/clients/$clientId');
            } else {
              context.go('/debts');
            }
          },
        ),
        actions: [
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Eliminar', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
            onSelected: (value) async {
              if (value == 'delete') {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Confirmar eliminación'),
                    content: const Text('¿Estás seguro de eliminar esta deuda? Se eliminarán todos los pagos asociados.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancelar'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
                if (confirm == true && context.mounted) {
                  await ref.read(debtsProvider.notifier).deleteDebt(debtId);
                  if (context.mounted) {
                    if (clientId != null) {
                      context.go('/clients/$clientId');
                    } else {
                      context.go('/debts');
                    }
                  }
                }
              }
            },
          ),
        ],
      ),
      body: debtAsync.when(
        data: (debt) {
          if (debt == null) {
            return const Center(child: Text('Deuda no encontrada'));
          }
          final statusColor = AppTheme.getStatusColor(debt.calculatedStatus.displayName);
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(debtDetailProvider(debtId));
              ref.invalidate(debtPaymentsProvider(debtId));
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDebtHeader(context, debt, statusColor),
                  const SizedBox(height: 24),
                  _buildProgressSection(context, debt),
                  const SizedBox(height: 24),
                  _buildPaymentsSection(context, ref, paymentsAsync),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: debtAsync.maybeWhen(
        data: (debt) => debt != null && debt.remainingAmount > 0
            ? FloatingActionButton.extended(
                onPressed: () {
                  if (clientId != null) {
                    context.go('/clients/$clientId/debt/$debtId/payment/add');
                  } else {
                    context.go('/debts/$debtId/payment/add');
                  }
                },
                icon: const Icon(Icons.payment),
                label: const Text('Registrar Pago'),
              )
            : null,
        orElse: () => null,
      ),
    );
  }

  Widget _buildDebtHeader(BuildContext context, Debt debt, Color statusColor) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                debt.calculatedStatus == DebtStatus.pagada
                    ? Icons.check_circle
                    : debt.isOverdue
                        ? Icons.warning
                        : Icons.receipt_long,
                size: 48,
                color: statusColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              debt.concept,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                debt.calculatedStatus.displayName,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    const Text('Total', style: TextStyle(color: Colors.grey)),
                    Text(
                      '\$${debt.totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Column(
                  children: [
                    const Text('Pagado', style: TextStyle(color: Colors.grey)),
                    Text(
                      '\$${debt.paidAmount.toStringAsFixed(2)}',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.successColor),
                    ),
                  ],
                ),
              ],
            ),
            if (debt.dueDate != null) ...[
              const Divider(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: debt.isOverdue ? AppTheme.errorColor : Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Vence: ${DateFormat('dd/MM/yyyy').format(debt.dueDate!)}',
                    style: TextStyle(
                      color: debt.isOverdue ? AppTheme.errorColor : Colors.grey,
                      fontWeight: debt.isOverdue ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ],
            if (debt.interestRate != null && debt.interestRate! > 0) ...[
              const SizedBox(height: 8),
              Text(
                'Interés: ${debt.interestRate}%',
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProgressSection(BuildContext context, Debt debt) {
    final progress = debt.totalAmount > 0 ? debt.paidAmount / debt.totalAmount : 0.0;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Progreso de Pago',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${(progress * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 12,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation(
                  progress >= 1.0 ? AppTheme.successColor : AppTheme.primaryColor,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Pendiente: \$${debt.remainingAmount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: debt.remainingAmount > 0 ? AppTheme.warningColor : AppTheme.successColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentsSection(BuildContext context, WidgetRef ref, AsyncValue paymentsAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Historial de Pagos',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        paymentsAsync.when(
          data: (payments) {
            if (payments.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.payment_outlined, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 8),
                      Text('No hay pagos registrados', style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                ),
              );
            }
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: payments.length,
              itemBuilder: (context, index) {
                final payment = payments[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.successColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check, color: AppTheme.successColor),
                    ),
                    title: Text(
                      '\$${payment.amount.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(payment.method.displayName),
                        Text(
                          DateFormat('dd/MM/yyyy HH:mm').format(payment.createdAt),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    trailing: payment.notes != null && payment.notes!.isNotEmpty
                        ? const Icon(Icons.note, color: Colors.grey)
                        : null,
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ],
    );
  }
}
