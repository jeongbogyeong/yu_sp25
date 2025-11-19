import 'package:readsms/readsms.dart';
import 'package:dio/dio.dart';
import 'utils/dio.dart';

/// --------------------
/// 결제 응답 모델
/// --------------------
class PaymentResponse {
  final int status;
  final int code;
  final String message;
  final PaymentData data;

  PaymentResponse({
    required this.status,
    required this.code,
    required this.message,
    required this.data,
  });

  factory PaymentResponse.fromJson(Map<String, dynamic> json) {
    return PaymentResponse(
      status: json['status'],
      code: json['code'],
      message: json['message'] ?? "",
      data: PaymentData.fromJson(json['data']),
    );
  }
}

class PaymentData {
  final String receiptId;
  final String orderId;
  final String name;
  final int price;
  final String pg;
  final String method;
  final String statusKo;

  PaymentData({
    required this.receiptId,
    required this.orderId,
    required this.name,
    required this.price,
    required this.pg,
    required this.method,
    required this.statusKo,
  });

  factory PaymentData.fromJson(Map<String, dynamic> json) {
    return PaymentData(
      receiptId: json['receipt_id'],
      orderId: json['order_id'],
      name: json['name'],
      price: json['price'],
      pg: json['pg'],
      method: json['method'],
      statusKo: json['status_ko'],
    );
  }
}

/// --------------------
/// 은행 문자 파싱 + 결제 확인 서비스
/// --------------------
class BankService {
  /// 문자 → 데이터 파싱
  Map<String, dynamic> parseSms(SMS event) {
    final lines = event.body.split("\n");

    String recipientAccount = lines[2]; // 계좌번호
    String remitterName = lines[3]; // 송금인
    String remittanceType = lines[4].contains("입금") ? "DEPOSIT" : "WITHDRAWAL";
    int remittanceAmount = int.parse(lines[5].replaceAll(",", "")); // 금액
    int remittanceBalance = int.parse(
      lines[6].replaceAll("잔액", "").replaceAll(",", ""),
    ); // 잔액

    return {
      "account": recipientAccount,
      "name": remitterName,
      "type": remittanceType,
      "amount": remittanceAmount,
      "balance": remittanceBalance,
    };
  }

  /// 서버 전송 + 결제 응답 확인
  Future<PaymentResponse?> sendToServer(Map<String, dynamic> data) async {
    try {
      final res = await dio.post('https://handy.com/v1/accounts', data: data);

      final paymentResponse = PaymentResponse.fromJson(res.data);
      return paymentResponse;
    } catch (e) {
      print("서버 통신 오류: $e");
      return null;
    }
  }

  /// 문자 이벤트 전체 처리
  Future<void> handleSms(SMS event) async {
    try {
      // 문자 파싱
      final parsed = parseSms(event);

      // 서버 전송 후 결제 응답 확인
      final response = await sendToServer(parsed);

      if (response != null) {
        print("결제 처리 완료 ✅");
        print("영수증 ID: ${response.data.receiptId}");
        print("주문 ID: ${response.data.orderId}");
        print("결제명: ${response.data.name}");
        print("결제 상태: ${response.data.statusKo}");
      }
    } catch (e) {
      print("SMS 처리 중 오류: $e");
    }
  }
}
