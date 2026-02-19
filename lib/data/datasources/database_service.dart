import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../domain/entities/client.dart';
import '../../domain/entities/debt.dart';
import '../../domain/entities/payment.dart';

class DatabaseService {
  static Database? _database;
  static const String _dbName = 'cobranza_pro.db';
  static const int _dbVersion = 1;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE clients (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT,
        address TEXT,
        notes TEXT,
        photoPath TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE debts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        clientId INTEGER NOT NULL,
        concept TEXT NOT NULL,
        totalAmount REAL NOT NULL,
        paidAmount REAL DEFAULT 0,
        createdAt TEXT NOT NULL,
        dueDate TEXT,
        interestRate REAL,
        status TEXT DEFAULT 'pendiente',
        updatedAt TEXT,
        FOREIGN KEY (clientId) REFERENCES clients (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        debtId INTEGER NOT NULL,
        clientId INTEGER NOT NULL,
        amount REAL NOT NULL,
        method TEXT DEFAULT 'efectivo',
        createdAt TEXT NOT NULL,
        notes TEXT,
        FOREIGN KEY (debtId) REFERENCES debts (id) ON DELETE CASCADE,
        FOREIGN KEY (clientId) REFERENCES clients (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('CREATE INDEX idx_debts_clientId ON debts (clientId)');
    await db.execute('CREATE INDEX idx_payments_debtId ON payments (debtId)');
    await db.execute('CREATE INDEX idx_payments_clientId ON payments (clientId)');
  }

  // Client CRUD
  Future<int> insertClient(Client client) async {
    final db = await database;
    final map = client.toMap();
    map.remove('id');
    return await db.insert('clients', map);
  }

  Future<List<Client>> getAllClients() async {
    final db = await database;
    final maps = await db.query('clients', orderBy: 'name ASC');
    return maps.map((map) => Client.fromMap(map)).toList();
  }

  Future<Client?> getClient(int id) async {
    final db = await database;
    final maps = await db.query('clients', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Client.fromMap(maps.first);
  }

  Future<List<Client>> searchClients(String query) async {
    final db = await database;
    final maps = await db.query(
      'clients',
      where: 'name LIKE ? OR phone LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'name ASC',
    );
    return maps.map((map) => Client.fromMap(map)).toList();
  }

  Future<int> updateClient(Client client) async {
    final db = await database;
    return await db.update(
      'clients',
      client.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [client.id],
    );
  }

  Future<int> deleteClient(int id) async {
    final db = await database;
    await db.delete('debts', where: 'clientId = ?', whereArgs: [id]);
    await db.delete('payments', where: 'clientId = ?', whereArgs: [id]);
    return await db.delete('clients', where: 'id = ?', whereArgs: [id]);
  }

  // Debt CRUD
  Future<int> insertDebt(Debt debt) async {
    final db = await database;
    final map = debt.toMap();
    map.remove('id');
    return await db.insert('debts', map);
  }

  Future<List<Debt>> getDebtsByClient(int clientId) async {
    final db = await database;
    final maps = await db.query(
      'debts',
      where: 'clientId = ?',
      whereArgs: [clientId],
      orderBy: 'createdAt DESC',
    );
    return maps.map((map) => Debt.fromMap(map)).toList();
  }

  Future<List<Debt>> getAllDebts() async {
    final db = await database;
    final maps = await db.query('debts', orderBy: 'createdAt DESC');
    return maps.map((map) => Debt.fromMap(map)).toList();
  }

  Future<List<Debt>> getDebtsByStatus(DebtStatus status) async {
    final db = await database;
    final maps = await db.query(
      'debts',
      where: 'status = ?',
      whereArgs: [status.name],
      orderBy: 'dueDate ASC',
    );
    return maps.map((map) => Debt.fromMap(map)).toList();
  }

  Future<List<Debt>> getOverdueDebts() async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    final maps = await db.query(
      'debts',
      where: "status != 'pagada' AND dueDate IS NOT NULL AND dueDate < ?",
      whereArgs: [now],
      orderBy: 'dueDate ASC',
    );
    return maps.map((map) => Debt.fromMap(map)).toList();
  }

  Future<Debt?> getDebt(int id) async {
    final db = await database;
    final maps = await db.query('debts', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Debt.fromMap(maps.first);
  }

  Future<int> updateDebt(Debt debt) async {
    final db = await database;
    final updatedDebt = debt.copyWith(updatedAt: DateTime.now());
    return await db.update(
      'debts',
      updatedDebt.toMap(),
      where: 'id = ?',
      whereArgs: [debt.id],
    );
  }

  Future<int> deleteDebt(int id) async {
    final db = await database;
    await db.delete('payments', where: 'debtId = ?', whereArgs: [id]);
    return await db.delete('debts', where: 'id = ?', whereArgs: [id]);
  }

  // Payment CRUD
  Future<int> insertPayment(Payment payment) async {
    final db = await database;
    final map = payment.toMap();
    map.remove('id');
    return await db.insert('payments', map);
  }

  Future<List<Payment>> getPaymentsByDebt(int debtId) async {
    final db = await database;
    final maps = await db.query(
      'payments',
      where: 'debtId = ?',
      whereArgs: [debtId],
      orderBy: 'createdAt DESC',
    );
    return maps.map((map) => Payment.fromMap(map)).toList();
  }

  Future<List<Payment>> getPaymentsByClient(int clientId) async {
    final db = await database;
    final maps = await db.query(
      'payments',
      where: 'clientId = ?',
      whereArgs: [clientId],
      orderBy: 'createdAt DESC',
    );
    return maps.map((map) => Payment.fromMap(map)).toList();
  }

  Future<List<Payment>> getAllPayments() async {
    final db = await database;
    final maps = await db.query('payments', orderBy: 'createdAt DESC');
    return maps.map((map) => Payment.fromMap(map)).toList();
  }

  Future<List<Payment>> getPaymentsThisMonth() async {
    final db = await database;
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final maps = await db.query(
      'payments',
      where: 'createdAt >= ?',
      whereArgs: [startOfMonth.toIso8601String()],
      orderBy: 'createdAt DESC',
    );
    return maps.map((map) => Payment.fromMap(map)).toList();
  }

  // Dashboard statistics
  Future<double> getTotalPending() async {
    final db = await database;
    final result = await db.rawQuery(
      "SELECT COALESCE(SUM(totalAmount - paidAmount), 0) as total FROM debts WHERE status != 'pagada'"
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0;
  }

  Future<double> getTotalOverdue() async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    final result = await db.rawQuery(
      "SELECT COALESCE(SUM(totalAmount - paidAmount), 0) as total FROM debts WHERE status != 'pagada' AND dueDate IS NOT NULL AND dueDate < ?",
      [now]
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0;
  }

  Future<double> getTotalCollectedThisMonth() async {
    final db = await database;
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) as total FROM payments WHERE createdAt >= ?',
      [startOfMonth.toIso8601String()]
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0;
  }

  Future<int> getClientCountWithDebts() async {
    final db = await database;
    final result = await db.rawQuery(
      "SELECT COUNT(DISTINCT clientId) as count FROM debts WHERE status != 'pagada'"
    );
    return (result.first['count'] as int?) ?? 0;
  }

  // Backup and Restore
  Future<Map<String, dynamic>> exportDatabase() async {
    final db = await database;
    final clients = await db.query('clients');
    final debts = await db.query('debts');
    final payments = await db.query('payments');
    
    return {
      'clients': clients,
      'debts': debts,
      'payments': payments,
      'exportedAt': DateTime.now().toIso8601String(),
      'version': _dbVersion,
    };
  }

  Future<void> importDatabase(Map<String, dynamic> data) async {
    final db = await database;
    
    await db.transaction((txn) async {
      await txn.delete('payments');
      await txn.delete('debts');
      await txn.delete('clients');

      final clients = data['clients'] as List<dynamic>;
      for (final client in clients) {
        await txn.insert('clients', Map<String, dynamic>.from(client));
      }

      final debts = data['debts'] as List<dynamic>;
      for (final debt in debts) {
        await txn.insert('debts', Map<String, dynamic>.from(debt));
      }

      final payments = data['payments'] as List<dynamic>;
      for (final payment in payments) {
        await txn.insert('payments', Map<String, dynamic>.from(payment));
      }
    });
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
