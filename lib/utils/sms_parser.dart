// sms_parser.dart
class ParsedSms {
  final String account;
  final String name;
  final int amount;
  final int balance;
  final String type;

  ParsedSms({
    required this.account,
    required this.name,
    required this.amount,
    required this.balance,
    required this.type,
  });
}

class SmsParser {
  static ParsedSms? parse(String body) {
    try {
      final accountMatch = RegExp(r'\d{3,}-?\*{2,}\d{2,}').firstMatch(body);
      final nameMatch = RegExp(r'[\uAC00-\uD7A3]{2,4}').firstMatch(body);
      final amountMatch = RegExp(r'[\d,]+원').firstMatch(body);
      final balanceMatch = RegExp(r'잔액[:\s]*([\d,]+)원').firstMatch(body);

      if (accountMatch == null || nameMatch == null || amountMatch == null)
        return null;

      return ParsedSms(
        account: accountMatch.group(0)!,
        name: nameMatch.group(0)!,
        amount: int.parse(
          amountMatch.group(0)!.replaceAll(RegExp(r'[^0-9]'), ''),
        ),
        balance: balanceMatch != null
            ? int.parse(balanceMatch.group(1)!.replaceAll(',', ''))
            : 0,
        type: body.contains("입금") ? "DEPOSIT" : "WITHDRAWAL",
      );
    } catch (e) {
      return null;
    }
  }
}
