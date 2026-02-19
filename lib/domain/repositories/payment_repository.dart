import '../../domain/entities/payment.dart';

abstract class PaymentRepository {
  Future<int> createPayment(Payment payment);
  Future<List<Payment>> getPaymentsByDebt(int debtId);
  Future<List<Payment>> getPaymentsByClient(int clientId);
  Future<List<Payment>> getAllPayments();
  Future<List<Payment>> getPaymentsThisMonth();
}
