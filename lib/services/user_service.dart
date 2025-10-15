import '../database/database_helper.dart';

class UserService {
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  final DatabaseHelper _db = DatabaseHelper.instance;

  // 사용자 추가
  Future<void> addUser({
    required String id,
    required String email,
    required String name,
  }) async {
    final db = await _db.database;
    await db.insert('users', {
      'id': id,
      'email': email,
      'name': name,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  // 사용자 정보 수정
  Future<void> updateUser({
    required String id,
    String? email,
    String? name,
  }) async {
    final db = await _db.database;
    final Map<String, dynamic> updateData = {
      'updated_at': DateTime.now().toIso8601String(),
    };
    
    if (email != null) updateData['email'] = email;
    if (name != null) updateData['name'] = name;

    await db.update(
      'users',
      updateData,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // 사용자 조회
  Future<Map<String, dynamic>?> getUserById(String id) async {
    final db = await _db.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return maps.first;
    }
    return null;
  }

  // 사용자 이메일로 조회
  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final db = await _db.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );

    if (maps.isNotEmpty) {
      return maps.first;
    }
    return null;
  }

  // 사용자 존재 여부 확인
  Future<bool> userExists(String id) async {
    final user = await getUserById(id);
    return user != null;
  }
}
