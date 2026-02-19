import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/client_providers.dart';
import '../../providers/debt_providers.dart';

class ClientsScreen extends ConsumerWidget {
  const ClientsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clients = ref.watch(filteredClientsProvider);
    final searchQuery = ref.watch(clientSearchQueryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clientes'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Buscar clientes...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          ref.read(clientSearchQueryProvider.notifier).state = '';
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                ref.read(clientSearchQueryProvider.notifier).state = value;
              },
            ),
          ),
          Expanded(
            child: clients.when(
              data: (clientList) {
                if (clientList.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          searchQuery.isEmpty 
                              ? 'No hay clientes registrados' 
                              : 'No se encontraron resultados',
                          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                        ),
                        if (searchQuery.isEmpty) ...[
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => context.go('/clients/add'),
                            icon: const Icon(Icons.add),
                            label: const Text('Agregar Cliente'),
                          ),
                        ],
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    await ref.read(clientsProvider.notifier).loadClients();
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: clientList.length,
                    itemBuilder: (context, index) {
                      final client = clientList[index];
                      return FutureBuilder<List<dynamic>>(
                        future: _getClientDebts(ref, client.id!),
                        builder: (context, snapshot) {
                          final debtCount = snapshot.data?[0] ?? 0;
                          final totalDebt = (snapshot.data?[1] as num?)?.toDouble() ?? 0.0;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(12),
                              leading: CircleAvatar(
                                backgroundColor: AppTheme.primaryColor,
                                child: Text(
                                  client.name.substring(0, 1).toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                client.name,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (client.phone != null && client.phone!.isNotEmpty)
                                    Text(client.phone!),
                                  if (debtCount > 0)
                                    Text(
                                      '$debtCount deuda(s) - \$${totalDebt.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        color: totalDebt > 0 ? AppTheme.warningColor : AppTheme.successColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                ],
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => context.go('/clients/${client.id}'),
                            ),
                          );
                        },
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/clients/add'),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Cliente'),
      ),
    );
  }

  Future<List<dynamic>> _getClientDebts(WidgetRef ref, int clientId) async {
    final debts = await ref.read(clientDebtsProvider(clientId).future);
    final totalDebt = debts.fold<double>(0, (sum, debt) => sum + debt.remainingAmount);
    return [debts.length, totalDebt];
  }
}
