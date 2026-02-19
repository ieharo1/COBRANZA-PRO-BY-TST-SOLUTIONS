import '../../domain/entities/client.dart';

abstract class ClientRepository {
  Future<int> createClient(Client client);
  Future<List<Client>> getAllClients();
  Future<Client?> getClient(int id);
  Future<List<Client>> searchClients(String query);
  Future<int> updateClient(Client client);
  Future<int> deleteClient(int id);
}
