class TransactionEntity {
  final int id;
  final int accountNumber;
  final int categoryId;
  final int amount;
  final String Memo;
  final String createdAt;
  final int assetId;//0:현금, 1:카드, 2:계좌이체

  TransactionEntity({
    required this.id,
    required this.accountNumber,
    required this.categoryId,
    required this.amount,
    required this.Memo,
    required this.createdAt,
    required this.assetId
  });
}
