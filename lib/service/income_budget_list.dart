import 'package:supabase_flutter/supabase_flutter.dart';

/// 이번 달 예산 계산용 요약 모델
class IncomeBudgetSummary {
  final int? salaryDay; // 월급날 (1~28)
  final int salaryAmount10k; // 월급 (십만 원 단위)
  final int extraAmount10k; // 추가 수입 총합 (십만 원 단위)

  IncomeBudgetSummary({
    required this.salaryDay,
    required this.salaryAmount10k,
    required this.extraAmount10k,
  });

  /// 총 예산 (원 단위)
  int get totalBudgetWon => (salaryAmount10k + extraAmount10k) * 100000;
}

/// Supabase에서 userInfo_table + user_extra_income_table 읽어서
/// 이번 달 “예상 예산” 계산
Future<IncomeBudgetSummary?> fetchIncomeBudgetSummary() async {
  final client = Supabase.instance.client;
  final session = client.auth.currentSession;
  if (session == null) return null;

  final uid = session.user.id;

  // 1) 기본 월급 정보
  final userInfo = await client
      .from('userInfo_table')
      .select()
      .eq('uid', uid)
      .maybeSingle();

  int? salaryDay;
  int salaryAmount10k = 0;

  if (userInfo != null) {
    salaryDay = (userInfo['salaryDay'] as num?)?.toInt();
    salaryAmount10k = (userInfo['salaryAmount10k'] as num?)?.toInt() ?? 0;
  }

  // 2) 추가 수입 총액
  final extraRows = await client
      .from('user_extra_income_table')
      .select()
      .eq('uid', uid);

  int extraAmount10k = 0;

  if (extraRows is List) {
    for (final row in extraRows) {
      final num? rawAmount =
          (row['amount10k'] ?? row['incomeAmount10k']) as num?;
      extraAmount10k += rawAmount?.toInt() ?? 0;
    }
  }

  return IncomeBudgetSummary(
    salaryDay: salaryDay,
    salaryAmount10k: salaryAmount10k,
    extraAmount10k: extraAmount10k,
  );
}
