import '../../domain/entities/debt.dart';

abstract class DebtRepository {
  Future<int> createDebt(Debt debt);
  Future<List<Debt>> getDebtsByClient(int clientId);
  Future<List<Debt>> getAllDebts();
  Future<List<Debt>> getDebtsByStatus(DebtStatus status);
  Future<List<Debt>> getOverdueDebts();
  Future<Debt?> getDebt(int id);
  Future<int> updateDebt(Debt debt);
  Future<int> deleteDebt(int id);
}
