import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/transaction_entity.dart';
import '../viewmodels/TransactionViewModel.dart';
import '../viewmodels/UserViewModel.dart';
import '../../utils/sms_parser.dart';
import 'package:smartmoney/service/notification/notification_service.dart';

/// 📩 문자 1건을 파싱해서 Transaction 으로 바로 저장하는 함수
Future<void> createTransactionFromSms(
  String smsBody,
  BuildContext context,
) async {
  debugPrint('🔍 createTransactionFromSms 호출, body=$smsBody');

  final parsed = SmsParser.parse(smsBody);
  if (parsed == null) {
    debugPrint('❌ SmsParser.parse 결과 null');
    return;
  }

  final bool isIncome = parsed.type == "DEPOSIT";
  final int categoryId = isIncome ? 16 : 10; // 기타(수입)/기타(지출)
  const int assetId = 1; // 카드

  final user = Provider.of<UserViewModel>(context, listen: false).user!;
  final accountNum = user.account_number;

  final int finalAmount = isIncome ? parsed.amount : -parsed.amount;

  final tx = TransactionEntity(
    id: 0,
    accountNumber: accountNum,
    categoryId: categoryId,
    assetId: assetId,
    amount: finalAmount,
    memo: parsed.name,
    createdAt: DateFormat('yyyy-MM-dd').format(DateTime.now()),
  );

  debugPrint(
    '✅ parsed → TransactionEntity: '
    'amount=$finalAmount, category=$categoryId, memo=${parsed.name}',
  );

  final vm = Provider.of<TransactionViewModel>(context, listen: false);
  final ok = await vm.insertTranaction(tx);
  debugPrint('✅ insertTransaction 결과: $ok');

  // 🔔 거래 생성에 성공했으면, 실시간 "결제/입금" 알림
  if (ok) {
    await NotificationService.showInstantTransactionNotification(
      isIncome: isIncome,
      amount: parsed.amount, // 양수 금액 그대로
      memo: parsed.name,
    );

    // 👇 여기부터: "오늘 예산 초과" 체크 로직

    // 1) 오늘 날짜 문자열
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // 2) TransactionViewModel 에서 오늘 지출 합계 계산 (amount < 0 인 것만)
    final txList = vm.transactions; // List<TransactionEntity>
    final double todayTotalSpending = txList
        .where((t) => t.createdAt == todayStr && t.amount < 0)
        .fold<double>(0, (sum, t) => sum + t.amount.abs().toDouble());

    debugPrint('📊 오늘 총 지출(문자 포함) = $todayTotalSpending 원');

    // 3) SharedPreferences 에 저장된 하루 예산 불러오기
    //    (예: ExpensePlanScreen 등에서 'daily_budget' 로 저장해놨다고 가정)
    final prefs = await SharedPreferences.getInstance();
    final double dailyBudget = prefs.getDouble('daily_budget') ?? 0.0;

    debugPrint('📌 저장된 하루 예산(daily_budget) = $dailyBudget 원');

    // 4) 입금이 아니라 지출이고, 하루 예산이 설정되어 있으며, 초과한 경우만 알림
    if (!isIncome && dailyBudget > 0) {
      await NotificationService.checkDailyOverBudgetAndNotify(
        todayTotal: todayTotalSpending,
        todayBudget: dailyBudget,
      );
    }
  }
}
