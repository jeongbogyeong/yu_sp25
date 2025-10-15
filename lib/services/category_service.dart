import '../database/database_helper.dart';
import '../models/transaction.dart';

class CategoryService {
  static final CategoryService _instance = CategoryService._internal();
  factory CategoryService() => _instance;
  CategoryService._internal();

  final DatabaseHelper _db = DatabaseHelper.instance;

  // 카테고리 추가
  Future<void> addCategory(Category category) async {
    final db = await _db.database;
    await db.insert('categories', category.toMap());
  }

  // 카테고리 수정
  Future<void> updateCategory(Category category) async {
    final db = await _db.database;
    await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  // 카테고리 삭제
  Future<void> deleteCategory(String id) async {
    final db = await _db.database;
    await db.delete(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // 모든 카테고리 조회
  Future<List<Category>> getAllCategories() async {
    final db = await _db.database;
    final List<Map<String, dynamic>> maps = await db.query('categories');

    return List.generate(maps.length, (i) {
      return Category.fromMap(maps[i]);
    });
  }

  // 수입 카테고리만 조회
  Future<List<Category>> getIncomeCategories() async {
    final db = await _db.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'categories',
      where: 'type = ?',
      whereArgs: ['income'],
    );

    return List.generate(maps.length, (i) {
      return Category.fromMap(maps[i]);
    });
  }

  // 지출 카테고리만 조회
  Future<List<Category>> getExpenseCategories() async {
    final db = await _db.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'categories',
      where: 'type = ?',
      whereArgs: ['expense'],
    );

    return List.generate(maps.length, (i) {
      return Category.fromMap(maps[i]);
    });
  }

  // 카테고리 ID로 조회
  Future<Category?> getCategoryById(String id) async {
    final db = await _db.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Category.fromMap(maps.first);
    }
    return null;
  }
}
