// lib/domain/entities/user_entity.dart

class UserEntity {
  final String id;
  final String name;
  final String email;
  final int account_number;
  final String? bankName;
  final String? photoUrl;

  // 🔥 새 필드: 주 수입원 (ENUM 문자열)
  //  ex) PART_TIME / SALARY / ALLOWANCE
  final String incomeType;

  const UserEntity({
    required this.id,
    required this.name,
    required this.email,
    required this.account_number,
    this.bankName,
    this.photoUrl,
    required this.incomeType,
  });

  factory UserEntity.fromMap(Map<String, dynamic> map) {
    return UserEntity(
      id: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      account_number: (map['accountNumber'] ?? 0) as int,
      bankName: map['bankName'] as String?,
      photoUrl: map['photoUrl'] as String? ?? map['photo_url'] as String?,
      incomeType: map['incomeType'] as String? ?? 'PART_TIME',
    );
  }

  // 필요하면 copyWith 도 써도 됨
  UserEntity copyWith({
    String? name,
    String? email,
    int? account_number,
    String? bankName,
    String? photoUrl,
    String? incomeType,
  }) {
    return UserEntity(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      account_number: account_number ?? this.account_number,
      bankName: bankName ?? this.bankName,
      photoUrl: photoUrl ?? this.photoUrl,
      incomeType: incomeType ?? this.incomeType,
    );
  }
}
