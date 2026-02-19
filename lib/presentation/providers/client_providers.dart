import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/client.dart';
import 'repository_providers.dart';

final clientsProvider = StateNotifierProvider<ClientsNotifier, AsyncValue<List<Client>>>((ref) {
  return ClientsNotifier(ref);
});

final clientSearchQueryProvider = StateProvider<String>((ref) => '');

final filteredClientsProvider = Provider<AsyncValue<List<Client>>>((ref) {
  final query = ref.watch(clientSearchQueryProvider);
  final clients = ref.watch(clientsProvider);
  
  return clients.whenData((clientList) {
    if (query.isEmpty) return clientList;
    final lowerQuery = query.toLowerCase();
    return clientList.where((client) {
      return client.name.toLowerCase().contains(lowerQuery) ||
             (client.phone?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();
  });
});

final selectedClientProvider = FutureProvider.family<Client?, int>((ref, id) async {
  final repository = ref.watch(clientRepositoryProvider);
  return await repository.getClient(id);
});

class ClientsNotifier extends StateNotifier<AsyncValue<List<Client>>> {
  final Ref _ref;

  ClientsNotifier(this._ref) : super(const AsyncValue.loading()) {
    loadClients();
  }

  Future<void> loadClients() async {
    state = const AsyncValue.loading();
    try {
      final repository = _ref.read(clientRepositoryProvider);
      final clients = await repository.getAllClients();
      state = AsyncValue.data(clients);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<int> addClient(Client client) async {
    final repository = _ref.read(clientRepositoryProvider);
    final id = await repository.createClient(client);
    await loadClients();
    return id;
  }

  Future<void> updateClient(Client client) async {
    final repository = _ref.read(clientRepositoryProvider);
    await repository.updateClient(client);
    await loadClients();
  }

  Future<void> deleteClient(int id) async {
    final repository = _ref.read(clientRepositoryProvider);
    await repository.deleteClient(id);
    await loadClients();
  }
}
