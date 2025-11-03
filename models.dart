// lib/models.dart
// --------------------------------------
// 📦 Hive 모델 정의 (가계부 앱 스키마)
// --------------------------------------

import 'package:hive/hive.dart';

part 'models.g.dart';


// 1. TxType (enum)

@HiveType(typeId: 1)
enum TxType {
  @HiveField(0)
  expense, // 지출

  @HiveField(1)
  income, // 수입
}


// 2. Category (카테고리)

@HiveType(typeId: 2)
class Category extends HiveObject {
  @HiveField(0)
  String id; // "exp:food", "inc:salary" 처럼 prefix로 구분
  @HiveField(1)
  String name; // 표시명
  @HiveField(2)
  TxType type; // 수입/지출 구분
  @HiveField(3)
  int? colorHex; // UI용 색상 코드
  @HiveField(4)
  int? iconCodePoint; // UI용 아이콘 코드

  Category({
    required this.id,
    required this.name,
    required this.type,
    this.colorHex,
    this.iconCodePoint,
  });
}


// 3. Account (계좌/지갑)

@HiveType(typeId: 3)
class Account extends HiveObject {
  @HiveField(0)
  String id; // "cash", "kb-check"
  @HiveField(1)
  String name; // 표시명
  @HiveField(2)
  String? note; // 메모

  Account({
    required this.id,
    required this.name,
    this.note,
  });
}


// 4. MoneyTx (거래 기록)

@HiveType(typeId: 4)
class MoneyTx extends HiveObject {
  @HiveField(0)
  String id; // PK (UUID 등)
  @HiveField(1)
  String categoryId; // FK → Category.id
  @HiveField(2)
  int amount; // 금액 (원 단위, 정수)
  @HiveField(3)
  String? memo; // 메모
  @HiveField(4)
  DateTime occurredAt; // 발생 시각
  @HiveField(5)
  DateTime createdAt; // 기록 시각
  @HiveField(6)
  String? accountId; // FK → Account.id

  // ✅ 파생 필드 (조회 성능 향상용)
  @HiveField(7)
  int ym; // YYYYMM (월별 조회 키)
  @HiveField(8)
  int ymd; // YYYYMMDD (일별 조회 키)
  @HiveField(9)
  String? lowerMemo; // 소문자 메모 (검색용)

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
  })  : ym = ym ?? _toYm(occurredAt),
        ymd = ymd ?? _toYmd(occurredAt),
        lowerMemo = lowerMemo ?? memo?.toLowerCase();

  // 🧮 파생 필드 계산 함수
  static int _toYm(DateTime dt) => dt.year * 100 + dt.month;
  static int _toYmd(DateTime dt) =>
      dt.year * 10000 + dt.month * 100 + dt.day;
}


// 5. AppSettings (앱 설정)

@HiveType(typeId: 5)
class AppSettings extends HiveObject {
  @HiveField(0)
  String currencyCode; // 통화 단위 (KRW)
  @HiveField(1)
  int firstDayOfWeek; // 월요일=1 … 일요일=7
  @HiveField(2)
  String themeMode; // light / dark / system
  @HiveField(3)
  DateTime? lastBackupAt; // 마지막 백업 시각

  AppSettings({
    this.currencyCode = 'KRW',
    this.firstDayOfWeek = 1,
    this.themeMode = 'system',
    this.lastBackupAt,
  });
}
