import '../database/database_helper.dart';
import '../models/transaction.dart';

class AccountService {
  static final AccountService _instance = AccountService._internal();
  factory AccountService() => _instance;
  AccountService._internal();

  final DatabaseHelper _db = DatabaseHelper.instance;

  // 계좌 추가
  Future<void> addAccount(Account account) async {
    final db = await _db.database;
    await db.insert('accounts', account.toMap());
  }

  // 계좌 수정
  Future<void> updateAccount(Account account) async {
    final db = await _db.database;
    await db.update(
      'accounts',
      account.toMap(),
      where: 'id = ?',
      whereArgs: [account.id],
    );
  }

  // 계좌 삭제
  Future<void> deleteAccount(String id) async {
    final db = await _db.database;
    await db.delete(
      'accounts',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // 모든 계좌 조회
  Future<List<Account>> getAllAccounts() async {
    final db = await _db.database;
    final List<Map<String, dynamic>> maps = await db.query('accounts');

    return List.generate(maps.length, (i) {
      return Account.fromMap(maps[i]);
    });
  }

  // 계좌 ID로 조회
  Future<Account?> getAccountById(String id) async {
    final db = await _db.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'accounts',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Account.fromMap(maps.first);
    }
    return null;
  }
}
