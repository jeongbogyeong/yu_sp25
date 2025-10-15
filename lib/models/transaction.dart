// 거래 타입 열거형
enum TxType {
  expense, // 지출
  income,  // 수입
}

// 카테고리 모델
class Category {
  final String id;
  final String name;
  final TxType type;
  final int? colorHex;
  final int? iconCodePoint;

  Category({
    required this.id,
    required this.name,
    required this.type,
    this.colorHex,
    this.iconCodePoint,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'color_hex': colorHex,
      'icon_code_point': iconCodePoint,
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'],
      name: map['name'],
      type: TxType.values.firstWhere((e) => e.name == map['type']),
      colorHex: map['color_hex'],
      iconCodePoint: map['icon_code_point'],
    );
  }
}

// 계좌/지갑 모델
class Account {
  final String id;
  final String name;
  final String? note;

  Account({
    required this.id,
    required this.name,
    this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'note': note,
    };
  }

  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      id: map['id'],
      name: map['name'],
      note: map['note'],
    );
  }
}

// 거래 기록 모델
class MoneyTx {
  final String id;
  final String categoryId;
  final int amount;
  final String? memo;
  final DateTime occurredAt;
  final DateTime createdAt;
  final String? accountId;
  final int ym; // YYYYMM
  final int ymd; // YYYYMMDD
  final String? lowerMemo;

  MoneyTx({
    required this.id,
    required this.categoryId,
    required this.amount,
    this.memo,
    required this.occurredAt,
    required this.createdAt,
    this.accountId,
    int? ym,
    int? ymd,
    String? lowerMemo,
  }) : ym = ym ?? _toYm(occurredAt),
       ymd = ymd ?? _toYmd(occurredAt),
       lowerMemo = lowerMemo ?? memo?.toLowerCase();

  static int _toYm(DateTime dt) => dt.year * 100 + dt.month;
  static int _toYmd(DateTime dt) => dt.year * 10000 + dt.month * 100 + dt.day;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category_id': categoryId,
      'amount': amount,
      'memo': memo,
      'occurred_at': occurredAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'account_id': accountId,
      'ym': ym,
      'ymd': ymd,
      'lower_memo': lowerMemo,
    };
  }

  factory MoneyTx.fromMap(Map<String, dynamic> map) {
    return MoneyTx(
      id: map['id'],
      categoryId: map['category_id'],
      amount: map['amount'],
      memo: map['memo'],
      occurredAt: DateTime.parse(map['occurred_at']),
      createdAt: DateTime.parse(map['created_at']),
      accountId: map['account_id'],
      ym: map['ym'],
      ymd: map['ymd'],
      lowerMemo: map['lower_memo'],
    );
  }
}

// 앱 설정 모델
class AppSettings {
  final String currencyCode;
  final int firstDayOfWeek;
  final String themeMode;
  final DateTime? lastBackupAt;

  AppSettings({
    this.currencyCode = 'KRW',
    this.firstDayOfWeek = 1,
    this.themeMode = 'system',
    this.lastBackupAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'currency_code': currencyCode,
      'first_day_of_week': firstDayOfWeek,
      'theme_mode': themeMode,
      'last_backup_at': lastBackupAt?.toIso8601String(),
    };
  }

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      currencyCode: map['currency_code'] ?? 'KRW',
      firstDayOfWeek: map['first_day_of_week'] ?? 1,
      themeMode: map['theme_mode'] ?? 'system',
      lastBackupAt: map['last_backup_at'] != null 
          ? DateTime.parse(map['last_backup_at']) 
          : null,
    );
  }
}
