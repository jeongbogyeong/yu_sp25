import '../database/database_helper.dart';
import '../models/transaction.dart';

class TransactionService {
  static final TransactionService _instance = TransactionService._internal();
  factory TransactionService() => _instance;
  TransactionService._internal();

  final DatabaseHelper _db = DatabaseHelper.instance;

  // 거래 기록 추가
  Future<void> addTransaction(MoneyTx transaction) async {
    final db = await _db.database;
    await db.insert('transactions', transaction.toMap());
  }

  // 거래 기록 수정
  Future<void> updateTransaction(MoneyTx transaction) async {
    final db = await _db.database;
    await db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  // 거래 기록 삭제
  Future<void> deleteTransaction(String id) async {
    final db = await _db.database;
    await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // 모든 거래 기록 조회
  Future<List<MoneyTx>> getAllTransactions() async {
    final db = await _db.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      orderBy: 'occurred_at DESC',
    );

    return List.generate(maps.length, (i) {
      return MoneyTx.fromMap(maps[i]);
    });
  }

  // 특정 월의 거래 기록 조회
  Future<List<MoneyTx>> getTransactionsByMonth(int year, int month) async {
    final db = await _db.database;
    final ym = year * 100 + month;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'ym = ?',
      whereArgs: [ym],
      orderBy: 'occurred_at DESC',
    );

    return List.generate(maps.length, (i) {
      return MoneyTx.fromMap(maps[i]);
    });
  }

  // 특정 날짜의 거래 기록 조회
  Future<List<MoneyTx>> getTransactionsByDate(DateTime date) async {
    final db = await _db.database;
    final ymd = date.year * 10000 + date.month * 100 + date.day;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'ymd = ?',
      whereArgs: [ymd],
      orderBy: 'occurred_at DESC',
    );

    return List.generate(maps.length, (i) {
      return MoneyTx.fromMap(maps[i]);
    });
  }

  // 월별 총 지출 조회
  Future<int> getMonthlyExpense(int year, int month) async {
    final db = await _db.database;
    final ym = year * 100 + month;
    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM transactions WHERE ym = ? AND amount < 0',
      [ym],
    );
    return result.first['total'] as int? ?? 0;
  }

  // 월별 총 수입 조회
  Future<int> getMonthlyIncome(int year, int month) async {
    final db = await _db.database;
    final ym = year * 100 + month;
    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM transactions WHERE ym = ? AND amount > 0',
      [ym],
    );
    return result.first['total'] as int? ?? 0;
  }
}
