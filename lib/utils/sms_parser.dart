import 'package:flutter/foundation.dart';

class ParsedSms {
  final String account; // 계좌번호 또는 카드번호
  final String name; // 가맹점명 / 카드사명 / 은행명 등
  final int amount; // 거래 금액
  final String type; // 'DEPOSIT' or 'WITHDRAWAL'

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
      // 줄바꿈 제거해서 패턴 매칭 편하게
      final normalized = body.replaceAll('\n', ' ').replaceAll('\r', ' ');
      debugPrint('🔍 SmsParser.parse 실행, body=$normalized');

      // 1) KB국민카드 전용 패턴
      final kb = _parseKbCard(normalized);
      if (kb != null) return kb;

      // 2) 일반 카드 문자 패턴 (신한/현대/롯데/우리/하나/삼성/농협카드 등)
      final card = _parseGenericCard(normalized);
      if (card != null) return card;

      // 3) 일반 은행 입출금/이체 문자 패턴
      final bank = _parseGenericBank(normalized);
      if (bank != null) return bank;

      // 4) 아주 느슨한 기본 패턴 (fallback)
      final fallback = _parseFallback(normalized);
      if (fallback != null) return fallback;

      debugPrint('❌ 최종 파싱 실패: 어떤 패턴에도 매칭 안됨');
      return null;
    } catch (e, st) {
      debugPrint('❌ SmsParser.parse 에러: $e');
      debugPrint(st.toString());
      return null;
    }
  }

  // ==========================
  // 1) KB국민카드 전용
  // ==========================
  // 예: "KB국민카드 1234*56 결제 12,500원 잔액 530,000원"
  //     "KB국민카드 1234*56 승인 12,500원 일시불"
  static ParsedSms? _parseKbCard(String body) {
    final regex = RegExp(
      r'KB국민카드\s+([0-9*]+)\s+(승인|결제|취소|취소승인|승인취소)?\s*([\d,]+)원',
    );

    final match = regex.firstMatch(body);
    if (match == null) return null;

    final cardNumber = match.group(1)!; // 1234*56
    final action = match.group(2) ?? '결제'; // 승인/결제/취소...
    final amountStr = match.group(3)!; // 12,500

    final amount = int.parse(amountStr.replaceAll(RegExp(r'[^0-9]'), ''));

    final isDeposit = _isDepositByText(body) || _isCancelText(body);
    final type = isDeposit ? 'DEPOSIT' : 'WITHDRAWAL';

    debugPrint(
      '✅ KB국민카드 문자 파싱 성공: card=$cardNumber, amount=$amount, type=$type',
    );

    return ParsedSms(
      account: cardNumber,
      name: 'KB국민카드 $action',
      amount: amount,
      type: type,
    );
  }

  // ==========================
  // 2) 일반 카드 문자
  // ==========================
  // 예:
  //  - "신한카드(1234) 12,500원 일시불 편의점"
  //  - "현대카드 1234 승인 12,500원 일시불 CU편의점"
  //  - "롯데카드 1234*56 결제 12,500원 가맹점명"
  static ParsedSms? _parseGenericCard(String body) {
    final regex = RegExp(
      r'([가-힣A-Za-z]+)카드[^\d\n]*?([0-9*]{3,})[^\n]*?(승인|결제|취소|취소승인|승인취소|사용|이용)?[^\d\n]*?([\d,]+)원',
    );

    final match = regex.firstMatch(body);
    if (match == null) return null;

    final brand = match.group(1)!; // 신한 / 현대 / 롯데 / 우리 / 하나...
    final cardNumber = match.group(2)!; // 1234*56, 1234 등
    final action = match.group(3) ?? '결제';
    final amountStr = match.group(4)!; // 12,500

    final amount = int.parse(amountStr.replaceAll(RegExp(r'[^0-9]'), ''));

    final isDeposit = _isDepositByText(body) || _isCancelText(body);
    final type = isDeposit ? 'DEPOSIT' : 'WITHDRAWAL';

    debugPrint(
      '✅ 카드 문자 파싱 성공: $brand, card=$cardNumber, amount=$amount, type=$type',
    );

    return ParsedSms(
      account: cardNumber,
      name: '$brand카드 $action',
      amount: amount,
      type: type,
    );
  }

  // ==========================
  // 3) 일반 은행 문자
  // ==========================
  // 예:
  //  - "카카오뱅크 33333-**-***** 입금 12500원 잔액 530000원"
  //  - "농협 123-****-123456 출금 12,500원"
  //  - "우리은행 123-***-45 입금 120,000원"
  static ParsedSms? _parseGenericBank(String body) {
    final regex = RegExp(
      r'([가-힣A-Za-z]+)\s+([0-9\-*]+)[^\n]*?\s(입금|출금|이체|송금|결제|사용)[^\d\n]*([\d,]+)원',
    );

    final match = regex.firstMatch(body);
    if (match == null) return null;

    final bankName = match.group(1)!; // 카카오뱅크 / 농협 / 우리은행 등
    final accountNumber = match.group(2)!; // 33333-**-***** 등
    final action = match.group(3)!; // 입금 / 출금 / 이체 ...
    final amountStr = match.group(4)!; // 12500

    final amount = int.parse(amountStr.replaceAll(RegExp(r'[^0-9]'), ''));

    final isDeposit = _isDepositByText(body) || action.contains('입금');
    final type = isDeposit ? 'DEPOSIT' : 'WITHDRAWAL';

    debugPrint(
      '✅ 은행 문자 파싱 성공: $bankName, account=$accountNumber, amount=$amount, type=$type',
    );

    return ParsedSms(
      account: accountNumber,
      name: bankName,
      amount: amount,
      type: type,
    );
  }

  // ==========================
  // 4) 느슨한 기본 패턴 (fallback)
  // ==========================
  static ParsedSms? _parseFallback(String body) {
    // 계좌/카드: 숫자/하이픈/별표 섞인 덩어리
    final accountMatch = RegExp(r'[0-9\-*]{5,}').firstMatch(body);

    // 한글 이름 2~4글자 (가맹점명 등)
    final nameMatch = RegExp(r'[\uAC00-\uD7A3]{2,4}').firstMatch(body);

    // 금액: 12,345원 (맨 처음 나오는 금액 기준)
    final amountMatch = RegExp(r'([\d,]+)원').firstMatch(body);

    if (accountMatch == null || nameMatch == null || amountMatch == null) {
      debugPrint('❌ fallback 파싱 실패: account/name/amount 중 하나 못 찾음');
      return null;
    }

    final amount = int.parse(
      amountMatch.group(1)!.replaceAll(RegExp(r'[^0-9]'), ''),
    );

    final isDeposit = _isDepositByText(body);
    final type = isDeposit ? 'DEPOSIT' : 'WITHDRAWAL';

    debugPrint('✅ fallback 문자 파싱 성공');

    return ParsedSms(
      account: accountMatch.group(0)!,
      name: nameMatch.group(0)!,
      amount: amount,
      type: type,
    );
  }

  // ==========================
  // 공통 헬퍼
  // ==========================

  /// '입금', '예금', '환불', '캐시백' 등이 포함되어 있으면 돈 들어온 걸로 간주
  static bool _isDepositByText(String body) {
    const depositKeywords = ['입금', '예금', '환불', '환입', '캐시백', '취소환급'];
    return depositKeywords.any((k) => body.contains(k));
  }

  /// '취소', '승인취소', '취소승인' 같은 단어가 있으면
  /// 카드 결제 취소 → 실질적으로 돈 들어온 거라 DEPOSIT 쪽으로 봐줄 수 있음
  static bool _isCancelText(String body) {
    const cancelKeywords = ['취소', '승인취소', '취소승인'];
    return cancelKeywords.any((k) => body.contains(k));
  }
}
