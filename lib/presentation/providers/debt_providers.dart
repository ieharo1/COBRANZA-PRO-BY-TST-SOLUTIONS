import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/debt.dart';
import '../../domain/entities/payment.dart';
import 'repository_providers.dart';

final debtsProvider = StateNotifierProvider<DebtsNotifier, AsyncValue<List<Debt>>>((ref) {
  return DebtsNotifier(ref);
});

final clientDebtsProvider = FutureProvider.family<List<Debt>, int>((ref, clientId) async {
  final repository = ref.watch(debtRepositoryProvider);
  return await repository.getDebtsByClient(clientId);
});

final overdueDebtsProvider = FutureProvider<List<Debt>>((ref) async {
  final repository = ref.watch(debtRepositoryProvider);
  return await repository.getOverdueDebts();
});

final debtDetailProvider = FutureProvider.family<Debt?, int>((ref, debtId) async {
  final repository = ref.watch(debtRepositoryProvider);
  return await repository.getDebt(debtId);
});

class DebtsNotifier extends StateNotifier<AsyncValue<List<Debt>>> {
  final Ref _ref;

  DebtsNotifier(this._ref) : super(const AsyncValue.loading()) {
    loadDebts();
  }

  Future<void> loadDebts() async {
    state = const AsyncValue.loading();
    try {
      final repository = _ref.read(debtRepositoryProvider);
      final debts = await repository.getAllDebts();
      state = AsyncValue.data(debts);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<int> addDebt(Debt debt) async {
    final repository = _ref.read(debtRepositoryProvider);
    final id = await repository.createDebt(debt);
    await loadDebts();
    return id;
  }

  Future<void> updateDebt(Debt debt) async {
    final repository = _ref.read(debtRepositoryProvider);
    await repository.updateDebt(debt);
    await loadDebts();
  }

  Future<void> deleteDebt(int id) async {
    final repository = _ref.read(debtRepositoryProvider);
    await repository.deleteDebt(id);
    await loadDebts();
  }

  Future<void> registerPayment(Payment payment) async {
    final paymentRepo = _ref.read(paymentRepositoryProvider);
    final debtRepo = _ref.read(debtRepositoryProvider);
    
    await paymentRepo.createPayment(payment);
    
    final debt = await debtRepo.getDebt(payment.debtId);
    if (debt != null) {
      final newPaidAmount = debt.paidAmount + payment.amount;
      final newStatus = newPaidAmount >= debt.totalAmount 
          ? DebtStatus.pagada 
          : (newPaidAmount > 0 ? DebtStatus.parcial : DebtStatus.pendiente);
      
      await debtRepo.updateDebt(debt.copyWith(
        paidAmount: newPaidAmount,
        status: newStatus,
      ));
    }
    await loadDebts();
  }
}
