import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/database_service.dart';
import '../../data/repositories/client_repository_impl.dart';
import '../../data/repositories/debt_repository_impl.dart';
import '../../data/repositories/payment_repository_impl.dart';
import '../../domain/repositories/client_repository.dart';
import '../../domain/repositories/debt_repository.dart';
import '../../domain/repositories/payment_repository.dart';

final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});

final clientRepositoryProvider = Provider<ClientRepository>((ref) {
  return ClientRepositoryImpl(ref.watch(databaseServiceProvider));
});

final debtRepositoryProvider = Provider<DebtRepository>((ref) {
  return DebtRepositoryImpl(ref.watch(databaseServiceProvider));
});

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return PaymentRepositoryImpl(ref.watch(databaseServiceProvider));
});
