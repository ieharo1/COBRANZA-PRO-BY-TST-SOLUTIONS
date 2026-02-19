import '../../domain/entities/payment.dart';
import '../../domain/repositories/payment_repository.dart';
import '../datasources/database_service.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  final DatabaseService _databaseService;

  PaymentRepositoryImpl(this._databaseService);

  @override
  Future<int> createPayment(Payment payment) async {
    return await _databaseService.insertPayment(payment);
  }

  @override
  Future<List<Payment>> getPaymentsByDebt(int debtId) async {
    return await _databaseService.getPaymentsByDebt(debtId);
  }

  @override
  Future<List<Payment>> getPaymentsByClient(int clientId) async {
    return await _databaseService.getPaymentsByClient(clientId);
  }

  @override
  Future<List<Payment>> getAllPayments() async {
    return await _databaseService.getAllPayments();
  }

  @override
  Future<List<Payment>> getPaymentsThisMonth() async {
    return await _databaseService.getPaymentsThisMonth();
  }
}
