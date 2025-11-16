import 'db.dart';
import 'models.dart';

class TxSummary {
  final int expense;
  final int income;
  int get net => income - expense;
  TxSummary({required this.expense, required this.income});
}

class TxRepositories {
  /// 월키(YYYYMM) 구하기
  static int ymKey(DateTime dt) => dt.year * 100 + dt.month;

  /// 월 범위 (시작/끝) 구하기
  static (DateTime start, DateTime end) monthRange(DateTime anyDay) {
    final start = DateTime(anyDay.year, anyDay.month, 1);
    final end = DateTime(anyDay.year, anyDay.month + 1, 0, 23, 59, 59);
    return (start, end);
  }

  /// 특정 월(YYYYMM)의 지출/수입/순수입 합계
  static TxSummary monthlyTotals(int ym) {
    int expense = 0, income = 0;
    for (final t in DB.transactions.values) {
      if (t.ym != ym) continue;
      final cat = DB.categories.get(t.categoryId);
      if (cat == null) continue;
      if (cat.type == TxType.expense) expense += t.amount;
      else income += t.amount;
    }
    return TxSummary(expense: expense, income: income);
  }

  /// 기간 합계 (포함 범위) — 타입 필터 가능
  static int sumInRange(DateTime start, DateTime end, {TxType? byType}) {
    int sum = 0;
    for (final t in DB.transactions.values) {
      if (t.occurredAt.isBefore(start) || t.occurredAt.isAfter(end)) continue;
      if (byType != null) {
        final cat = DB.categories.get(t.categoryId);
        if (cat?.type != byType) continue;
      }
      sum += t.amount;
    }
    return sum;
  }

  /// 카테고리별 합계 (특정 월)
  /// byType 지정 시 해당 타입만 집계; null이면 모두 집계
  static Map<String, int> totalsByCategory(int ym, {TxType? byType}) {
    final map = <String, int>{};
    for (final t in DB.transactions.values) {
      if (t.ym != ym) continue;
      final cat = DB.categories.get(t.categoryId);
      if (cat == null) continue;
      if (byType != null && cat.type != byType) continue;
      map[t.categoryId] = (map[t.categoryId] ?? 0) + t.amount;
    }
    return map; // key=categoryId, value=합계
  }

  /// 계좌별 합계 (특정 월, 타입 필터 가능)
  static Map<String, int> totalsByAccount(int ym, {TxType? byType}) {
    final map = <String, int>{};
    for (final t in DB.transactions.values) {
      if (t.ym != ym) continue;
      final cat = DB.categories.get(t.categoryId);
      if (cat == null) continue;
      if (byType != null && cat.type != byType) continue;
      final accId = t.accountId ?? '_none';
      map[accId] = (map[accId] ?? 0) + t.amount;
    }
    return map;
  }

  /// 일별 시계열 (특정 월, 타입 필터 가능)
  /// return: Map<YYYYMMDD, 합계>
  static Map<int, int> dailySeries(int ym, {TxType? byType}) {
    final map = <int, int>{};
    for (final t in DB.transactions.values) {
      if (t.ym != ym) continue;
      final cat = DB.categories.get(t.categoryId);
      if (byType != null && cat?.type != byType) continue;
      map[t.ymd] = (map[t.ymd] ?? 0) + t.amount;
    }
    return map;
  }

  /// 키워드 검색 (메모 기준, 대소문자 무시)
  static List<MoneyTx> searchByMemo(String keyword, {int? ym}) {
    final key = keyword.trim().toLowerCase();
    if (key.isEmpty) return const [];
    final out = <MoneyTx>[];
    for (final t in DB.transactions.values) {
      if (ym != null && t.ym != ym) continue;
      final lm = t.lowerMemo ?? '';
      if (lm.contains(key)) out.add(t);
    }
    out.sort((a, b) => a.occurredAt.compareTo(b.occurredAt));
    return out;
  }

  /// 거래 리스트: 특정 월(정렬 포함)
  static List<MoneyTx> listByMonth(int ym) {
    final list = DB.transactions.values.where((t) => t.ym == ym).toList()
      ..sort((a, b) => a.occurredAt.compareTo(b.occurredAt));
    return list;
  }

  /// 카테고리 ID -> 표시명 변환 유틸
  static String categoryName(String categoryId) =>
      DB.categories.get(categoryId)?.name ?? categoryId;

  /// 계좌 ID -> 표시명 변환 유틸
  static String accountName(String accountId) =>
      DB.accounts.get(accountId)?.name ?? accountId;
}
