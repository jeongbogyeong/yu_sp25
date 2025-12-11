import 'package:flutter/foundation.dart';

class ParsedSms {
  final String account;
  final String name;
  final int amount;
  final String type;

  ParsedSms({
    required this.account,
    required this.name,
    required this.amount,
    required this.type,
  });
}

class SmsParser {
  static ParsedSms? parse(String body) {
    try {
      // 계좌 번호: 123-***45 이런 형식
      final accountMatch = RegExp(r'\d{3,}-?\*{2,}\d{2,}').firstMatch(body);

      // 한글 이름 2~4글자 (가맹점명 등)
      final nameMatch = RegExp(r'[\uAC00-\uD7A3]{2,4}').firstMatch(body);

      // 금액: 12,345원
      final amountMatch = RegExp(r'([\d,]+)원').firstMatch(body);

      if (accountMatch == null || nameMatch == null || amountMatch == null) {
        debugPrint('❌ 파싱 실패: account/name/amount 중 하나 못 찾음');
        return null;
      }

      final amount = int.parse(
        amountMatch.group(1)!.replaceAll(RegExp(r'[^0-9]'), ''),
      );

      final isDeposit = body.contains('입금') || body.contains('예금');

      return ParsedSms(
        account: accountMatch.group(0)!,
        name: nameMatch.group(0)!,
        amount: amount,
        type: isDeposit ? 'DEPOSIT' : 'WITHDRAWAL',
      );
    } catch (e) {
      debugPrint('❌ SmsParser.parse 에러: $e');
      return null;
    }
  }
}
