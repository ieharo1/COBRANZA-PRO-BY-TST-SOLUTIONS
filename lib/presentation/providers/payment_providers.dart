import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/payment.dart';
import 'repository_providers.dart';

final paymentsProvider = StateNotifierProvider<PaymentsNotifier, AsyncValue<List<Payment>>>((ref) {
  return PaymentsNotifier(ref);
});

final debtPaymentsProvider = FutureProvider.family<List<Payment>, int>((ref, debtId) async {
  final repository = ref.watch(paymentRepositoryProvider);
  return await repository.getPaymentsByDebt(debtId);
});

final clientPaymentsProvider = FutureProvider.family<List<Payment>, int>((ref, clientId) async {
  final repository = ref.watch(paymentRepositoryProvider);
  return await repository.getPaymentsByClient(clientId);
});

final paymentsThisMonthProvider = FutureProvider<List<Payment>>((ref) async {
  final repository = ref.watch(paymentRepositoryProvider);
  return await repository.getPaymentsThisMonth();
});

class PaymentsNotifier extends StateNotifier<AsyncValue<List<Payment>>> {
  final Ref _ref;

  PaymentsNotifier(this._ref) : super(const AsyncValue.loading()) {
    loadPayments();
  }

  Future<void> loadPayments() async {
    state = const AsyncValue.loading();
    try {
      final repository = _ref.read(paymentRepositoryProvider);
      final payments = await repository.getAllPayments();
      state = AsyncValue.data(payments);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
