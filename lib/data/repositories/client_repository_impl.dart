import '../../domain/entities/client.dart';
import '../../domain/repositories/client_repository.dart';
import '../datasources/database_service.dart';

class ClientRepositoryImpl implements ClientRepository {
  final DatabaseService _databaseService;

  ClientRepositoryImpl(this._databaseService);

  @override
  Future<int> createClient(Client client) async {
    return await _databaseService.insertClient(client);
  }

  @override
  Future<List<Client>> getAllClients() async {
    return await _databaseService.getAllClients();
  }

  @override
  Future<Client?> getClient(int id) async {
    return await _databaseService.getClient(id);
  }

  @override
  Future<List<Client>> searchClients(String query) async {
    return await _databaseService.searchClients(query);
  }

  @override
  Future<int> updateClient(Client client) async {
    return await _databaseService.updateClient(client);
  }

  @override
  Future<int> deleteClient(int id) async {
    return await _databaseService.deleteClient(id);
  }
}
