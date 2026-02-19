import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'repository_providers.dart';

class DashboardStats {
  final double totalPending;
  final double totalOverdue;
  final double totalCollectedThisMonth;
  final int clientsWithDebts;

  DashboardStats({
    required this.totalPending,
    required this.totalOverdue,
    required this.totalCollectedThisMonth,
    required this.clientsWithDebts,
  });
}

final dashboardStatsProvider = FutureProvider<DashboardStats>((ref) async {
  final db = ref.watch(databaseServiceProvider);
  
  final totalPending = await db.getTotalPending();
  final totalOverdue = await db.getTotalOverdue();
  final totalCollected = await db.getTotalCollectedThisMonth();
  final clientsWithDebts = await db.getClientCountWithDebts();

  return DashboardStats(
    totalPending: totalPending,
    totalOverdue: totalOverdue,
    totalCollectedThisMonth: totalCollected,
    clientsWithDebts: clientsWithDebts,
  );
});
