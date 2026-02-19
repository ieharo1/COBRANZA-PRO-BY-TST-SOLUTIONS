import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/debt.dart';
import '../../providers/client_providers.dart';
import '../../providers/debt_providers.dart';

class DebtsScreen extends ConsumerStatefulWidget {
  const DebtsScreen({super.key});

  @override
  ConsumerState<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends ConsumerState<DebtsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedStatus = 'todas';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      setState(() {
        switch (_tabController.index) {
          case 0:
            _selectedStatus = 'todas';
            break;
          case 1:
            _selectedStatus = 'pendiente';
            break;
          case 2:
            _selectedStatus = 'parcial';
            break;
          case 3:
            _selectedStatus = 'vencida';
            break;
          case 4:
            _selectedStatus = 'pagada';
            break;
        }
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final debts = ref.watch(debtsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Deudas'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Todas'),
            Tab(text: 'Pendiente'),
            Tab(text: 'Parcial'),
            Tab(text: 'Vencida'),
            Tab(text: 'Pagada'),
          ],
        ),
      ),
      body: debts.when(
        data: (debtList) {
          final filteredDebts = _selectedStatus == 'todas'
              ? debtList
              : debtList.where((d) => d.calculatedStatus.name == _selectedStatus).toList();

          if (filteredDebts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    _selectedStatus == 'todas'
                        ? 'No hay deudas registradas'
                        : 'No hay deudas $_selectedStatus',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  if (_selectedStatus == 'todas') ...[
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => context.go('/debts/add'),
                      icon: const Icon(Icons.add),
                      label: const Text('Agregar Deuda'),
                    ),
                  ],
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await ref.read(debtsProvider.notifier).loadDebts();
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredDebts.length,
              itemBuilder: (context, index) {
                final debt = filteredDebts[index];
                return _DebtCard(debt: debt);
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/debts/add'),
        icon: const Icon(Icons.add),
        label: const Text('Nueva Deuda'),
      ),
    );
  }
}

class _DebtCard extends ConsumerWidget {
  final Debt debt;

  const _DebtCard({required this.debt});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientAsync = ref.watch(selectedClientProvider(debt.clientId));
    final statusColor = AppTheme.getStatusColor(debt.calculatedStatus.displayName);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: debt.isOverdue
            ? BorderSide(color: AppTheme.errorColor.withOpacity(0.5), width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () => context.go('/clients/${debt.clientId}/debt/${debt.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  clientAsync.when(
                    data: (client) => CircleAvatar(
                      radius: 20,
                      backgroundColor: AppTheme.primaryColor,
                      child: Text(
                        client?.name.substring(0, 1).toUpperCase() ?? '?',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    loading: () => const CircleAvatar(
                      radius: 20,
                      child: Icon(Icons.person, size: 20),
                    ),
                    error: (_, __) => const CircleAvatar(
                      radius: 20,
                      child: Icon(Icons.person, size: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        clientAsync.when(
                          data: (client) => Text(
                            client?.name ?? 'Cliente',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          loading: () => const Text('Cargando...'),
                          error: (_, __) => const Text('Cliente'),
                        ),
                        Text(
                          debt.concept,
                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      debt.calculatedStatus.displayName,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Monto', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Text(
                        '\$${debt.totalAmount.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Pagado', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Text(
                        '\$${debt.paidAmount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppTheme.successColor,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Pendiente', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Text(
                        '\$${debt.remainingAmount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: debt.remainingAmount > 0 ? AppTheme.warningColor : AppTheme.successColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (debt.dueDate != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: debt.isOverdue ? AppTheme.errorColor : Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Vence: ${DateFormat('dd/MM/yyyy').format(debt.dueDate!)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: debt.isOverdue ? AppTheme.errorColor : Colors.grey,
                        fontWeight: debt.isOverdue ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    if (debt.isOverdue) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.errorColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'VENCIDA',
                          style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
