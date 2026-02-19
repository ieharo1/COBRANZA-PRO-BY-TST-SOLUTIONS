import '../../domain/entities/debt.dart';
import '../../domain/repositories/debt_repository.dart';
import '../datasources/database_service.dart';

class DebtRepositoryImpl implements DebtRepository {
  final DatabaseService _databaseService;

  DebtRepositoryImpl(this._databaseService);

  @override
  Future<int> createDebt(Debt debt) async {
    return await _databaseService.insertDebt(debt);
  }

  @override
  Future<List<Debt>> getDebtsByClient(int clientId) async {
    return await _databaseService.getDebtsByClient(clientId);
  }

  @override
  Future<List<Debt>> getAllDebts() async {
    return await _databaseService.getAllDebts();
  }

  @override
  Future<List<Debt>> getDebtsByStatus(DebtStatus status) async {
    return await _databaseService.getDebtsByStatus(status);
  }

  @override
  Future<List<Debt>> getOverdueDebts() async {
    return await _databaseService.getOverdueDebts();
  }

  @override
  Future<Debt?> getDebt(int id) async {
    return await _databaseService.getDebt(id);
  }

  @override
  Future<int> updateDebt(Debt debt) async {
    return await _databaseService.updateDebt(debt);
  }

  @override
  Future<int> deleteDebt(int id) async {
    return await _databaseService.deleteDebt(id);
  }
}
