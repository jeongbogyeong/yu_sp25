import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

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

  // 🔔 거래 생성에 성공했으면, 실시간 알림 발사
  if (ok) {
    await NotificationService.showInstantTransactionNotification(
      isIncome: isIncome,
      amount: parsed.amount, // 양수 금액 그대로
      memo: parsed.name,
    );
  }
}
