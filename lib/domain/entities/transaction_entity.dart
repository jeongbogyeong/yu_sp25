class TransactionEntity {
  final int id;
  final int accountNumber;
  final int categoryId;
  final int amount;
  final String memo;
  final String createdAt;
  final int assetId;//0:현금, 1:카드, 2:계좌이체

  TransactionEntity({
    required this.id,
    required this.accountNumber,
    required this.categoryId,
    required this.amount,
    required this.memo,
    required this.createdAt,
    required this.assetId
  });
  Map<String, dynamic> toMap() {
    return {
      'transactionId': id,
      'accountNumber': accountNumber,
      'categoryId': categoryId, // 예시: DB 필드명에 맞춤
      'amount': amount,
      'memo': memo,
      'createdAt': createdAt,
      'assetId': assetId,
    };
  }
}
