// lib/seeds.dart
import 'dart:math';
import 'package:uuid/uuid.dart';
import 'db.dart';
import 'models.dart';

/// 🧩 샘플 데이터 자동 생성 (Seed)
///
/// - months: 최근 N개월 생성
/// - perMonth: 월별 거래 수
/// - randomSeed: 재현 가능한 랜덤값을 위한 시드
///
/// 💡 개발용 예시
/// ```dart
/// if (DB.transactions.isEmpty) {
///   await seedSampleData(months: 3, perMonth: 100);
/// }
/// ```
Future<void> seedSampleData({
  int months = 3,
  int perMonth = 100,
  int? randomSeed,
}) async {
  final rnd = Random(randomSeed ?? DateTime.now().millisecondsSinceEpoch);
  final uuid = const Uuid();

  // 🧱 1. 카테고리/계좌/설정이 비어 있다면 기본값 생성
  if (DB.categories.isEmpty) {
    await DB.categories.put('exp:food',
        Category(id: 'exp:food', name: '식비', type: TxType.expense));
    await DB.categories.put('exp:transport',
        Category(id: 'exp:transport', name: '교통', type: TxType.expense));
    await DB.categories.put('exp:shop',
        Category(id: 'exp:shop', name: '쇼핑', type: TxType.expense));
    await DB.categories.put('exp:ent',
        Category(id: 'exp:ent', name: '문화/여가', type: TxType.expense));

    await DB.categories.put('inc:salary',
        Category(id: 'inc:salary', name: '월급', type: TxType.income));
    await DB.categories.put('inc:bonus',
        Category(id: 'inc:bonus', name: '보너스', type: TxType.income));
  }

  if (DB.accounts.isEmpty) {
    await DB.accounts.put('cash', Account(id: 'cash', name: '현금'));
    await DB.accounts.put('card', Account(id: 'card', name: '체크카드'));
    await DB.accounts.put('visa', Account(id: 'visa', name: '비자카드'));
  }

  if (DB.settings.isEmpty) {
    await DB.settings.put('app', AppSettings());
  }

  // 🔁 2. 최근 months개월의 시작일 목록
  final now = DateTime.now();
  final startMonths = List.generate(
    months,
        (i) => DateTime(now.year, now.month - i, 1),
  );

  // 💰 3. 거래 생성
  final expenseCats = DB.categories.values
      .where((c) => c.type == TxType.expense)
      .toList();
  final incomeCats = DB.categories.values
      .where((c) => c.type == TxType.income)
      .toList();
  final accounts = DB.accounts.keys.cast<String>().toList();

  int randAmountExpense() {
    // 5천~5만원대
    const list = [5000, 8000, 10000, 15000, 20000, 25000, 30000, 50000];
    return list[rnd.nextInt(list.length)];
  }

  int randAmountIncome() {
    // 2백~4백만원대 or 보너스 20~80만원
    final salary = [2000000, 2500000, 3000000, 3500000];
    final bonus = [200000, 300000, 500000, 800000];
    return rnd.nextBool()
        ? salary[rnd.nextInt(salary.length)]
        : bonus[rnd.nextInt(bonus.length)];
  }

  // 🧾 메모 후보
  final memoList = [
    '점심',
    '커피',
    '지하철',
    '택시',
    '장보기',
    '편의점',
    '영화',
    '술자리',
    '간식',
    null,
    null,
  ];

  for (final start in startMonths) {
    final end = DateTime(start.year, start.month + 1, 0);
    final daysInMonth = end.day;

    final expenseCount = (perMonth * 0.85).round();
    final incomeCount = perMonth - expenseCount;

    // 📈 수입 (월초/월말)
    for (int i = 0; i < incomeCount; i++) {
      final isMonthStart = rnd.nextBool();
      final day = isMonthStart ? rnd.nextInt(3) + 1 : daysInMonth - rnd.nextInt(3);
      final time = DateTime(start.year, start.month, day, 10 + rnd.nextInt(5));
      final cat = incomeCats[rnd.nextInt(incomeCats.length)];
      final tx = MoneyTx(
        id: uuid.v4(),
        categoryId: cat.id,
        amount: randAmountIncome(),
        memo: '수입-${cat.name}',
        occurredAt: time,
        createdAt: DateTime.now(),
        accountId: accounts[rnd.nextInt(accounts.length)],
      );
      await DB.transactions.put(tx.id, tx);
    }

    // 📉 지출 (매일 2~3건)
    for (int i = 0; i < expenseCount; i++) {
      final day = rnd.nextInt(daysInMonth) + 1;
      final hour = 8 + rnd.nextInt(12); // 오전8~오후8
      final time = DateTime(start.year, start.month, day, hour, rnd.nextInt(60));
      final cat = expenseCats[rnd.nextInt(expenseCats.length)];
      final tx = MoneyTx(
        id: uuid.v4(),
        categoryId: cat.id,
        amount: randAmountExpense(),
        memo: memoList[rnd.nextInt(memoList.length)],
        occurredAt: time,
        createdAt: DateTime.now(),
        accountId: accounts[rnd.nextInt(accounts.length)],
      );
      await DB.transactions.put(tx.id, tx);
    }
  }

  print('✅ 샘플 데이터 생성 완료: ${DB.transactions.length} 건');
}

