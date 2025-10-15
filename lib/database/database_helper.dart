import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('smartmoney.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> init() async {
    await database;
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const textTypeNullable = 'TEXT';
    const integerType = 'INTEGER NOT NULL';
    const integerTypeNullable = 'INTEGER';
    const realType = 'REAL NOT NULL';
    const realTypeNullable = 'REAL';

    // 사용자 정보 테이블
    await db.execute('''
      CREATE TABLE users (
        id $idType,
        email $textType,
        name $textType,
        created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // 카테고리 테이블
    await db.execute('''
      CREATE TABLE categories (
        id $textType,
        name $textType,
        type $textType,
        color_hex $integerTypeNullable,
        icon_code_point $integerTypeNullable,
        created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        PRIMARY KEY (id)
      )
    ''');

    // 계좌/지갑 테이블
    await db.execute('''
      CREATE TABLE accounts (
        id $textType,
        name $textType,
        note $textTypeNullable,
        created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        PRIMARY KEY (id)
      )
    ''');

    // 거래 기록 테이블
    await db.execute('''
      CREATE TABLE transactions (
        id $textType,
        category_id $textType NOT NULL,
        amount $integerType,
        memo $textTypeNullable,
        occurred_at TEXT NOT NULL,
        created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        account_id $textTypeNullable,
        ym $integerType,
        ymd $integerType,
        lower_memo $textTypeNullable,
        PRIMARY KEY (id),
        FOREIGN KEY (category_id) REFERENCES categories (id),
        FOREIGN KEY (account_id) REFERENCES accounts (id)
      )
    ''');

    // 커뮤니티 게시글 테이블
    await db.execute('''
      CREATE TABLE posts (
        id $textType,
        author_id $textType NOT NULL,
        text $textType NOT NULL,
        category $textType DEFAULT '자유',
        created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        like_count $integerType DEFAULT 0,
        liked_by_me $integerType DEFAULT 0,
        PRIMARY KEY (id),
        FOREIGN KEY (author_id) REFERENCES users (id)
      )
    ''');

    // 커뮤니티 댓글 테이블
    await db.execute('''
      CREATE TABLE comments (
        id $textType,
        post_id $textType NOT NULL,
        author_id $textType NOT NULL,
        text $textType NOT NULL,
        created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        PRIMARY KEY (id),
        FOREIGN KEY (post_id) REFERENCES posts (id),
        FOREIGN KEY (author_id) REFERENCES users (id)
      )
    ''');

    // 앱 설정 테이블
    await db.execute('''
      CREATE TABLE app_settings (
        id $integerType DEFAULT 1,
        currency_code $textType DEFAULT 'KRW',
        first_day_of_week $integerType DEFAULT 1,
        theme_mode $textType DEFAULT 'system',
        last_backup_at $textTypeNullable,
        created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        PRIMARY KEY (id)
      )
    ''');

    // 기본 데이터 삽입
    await _insertInitialData(db);
  }

  Future<void> _insertInitialData(Database db) async {
    // 기본 카테고리 삽입
    await db.insert('categories', {
      'id': 'exp:food',
      'name': '식비',
      'type': 'expense',
      'color_hex': 0xFFFFA726,
      'icon_code_point': 0xe3a7, // restaurant icon
    });

    await db.insert('categories', {
      'id': 'inc:salary',
      'name': '월급',
      'type': 'income',
      'color_hex': 0xFF4CAF50,
      'icon_code_point': 0xe8f4, // work icon
    });

    // 기본 계좌 삽입
    await db.insert('accounts', {
      'id': 'cash',
      'name': '현금',
      'note': '현금 계좌',
    });

    // 기본 앱 설정 삽입
    await db.insert('app_settings', {
      'id': 1,
      'currency_code': 'KRW',
      'first_day_of_week': 1,
      'theme_mode': 'system',
    });
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
