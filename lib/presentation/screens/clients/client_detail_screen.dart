import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/client.dart';
import '../../providers/client_providers.dart';
import '../../providers/debt_providers.dart';

class ClientDetailScreen extends ConsumerWidget {
  final int clientId;

  const ClientDetailScreen({super.key, required this.clientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientAsync = ref.watch(selectedClientProvider(clientId));
    final debtsAsync = ref.watch(clientDebtsProvider(clientId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del Cliente'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/clients'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => context.go('/clients/$clientId/edit'),
          ),
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
                    content: const Text('¿Estás seguro de eliminar este cliente? Se eliminarán todas sus deudas y pagos.'),
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
                  await ref.read(clientsProvider.notifier).deleteClient(clientId);
                  if (context.mounted) context.go('/clients');
                }
              }
            },
          ),
        ],
      ),
      body: clientAsync.when(
        data: (client) {
          if (client == null) {
            return const Center(child: Text('Cliente no encontrado'));
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(selectedClientProvider(clientId));
              ref.invalidate(clientDebtsProvider(clientId));
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildClientHeader(context, client),
                  const SizedBox(height: 24),
                  _buildDebtsSection(context, ref, debtsAsync),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/clients/$clientId/debt/add'),
        icon: const Icon(Icons.add),
        label: const Text('Nueva Deuda'),
      ),
    );
  }

  Widget _buildClientHeader(BuildContext context, Client client) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: AppTheme.primaryColor,
              child: Text(
                client.name.substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  fontSize: 32,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              client.name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            if (client.phone != null && client.phone!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.phone, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(client.phone!, style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ],
            if (client.address != null && client.address!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(client.address!, style: const TextStyle(color: Colors.grey)),
                  ),
                ],
              ),
            ],
            if (client.notes != null && client.notes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.note, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(child: Text(client.notes!)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDebtsSection(BuildContext context, WidgetRef ref, AsyncValue debtsAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Historial de Deudas',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        debtsAsync.when(
          data: (debts) {
            if (debts.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 8),
                      Text('No hay deudas registradas', style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                ),
              );
            }
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: debts.length,
              itemBuilder: (context, index) {
                final debt = debts[index];
                final statusColor = AppTheme.getStatusColor(debt.calculatedStatus.displayName);
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: Container(
                      width: 4,
                      height: 50,
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    title: Text(
                      debt.concept,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total: \$${debt.totalAmount.toStringAsFixed(2)}'),
                        Text(
                          'Pendiente: \$${debt.remainingAmount.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: debt.remainingAmount > 0 ? AppTheme.warningColor : AppTheme.successColor,
                          ),
                        ),
                        if (debt.dueDate != null)
                          Text(
                            'Vence: ${DateFormat('dd/MM/yyyy').format(debt.dueDate!)}',
                            style: TextStyle(
                              color: debt.isOverdue ? AppTheme.errorColor : Colors.grey,
                            ),
                          ),
                      ],
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        debt.calculatedStatus.displayName,
                        style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                    onTap: () => context.go('/clients/$clientId/debt/${debt.id}'),
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
