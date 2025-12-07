import 'package:supabase_flutter/supabase_flutter.dart';

class UserEntity {
  final String id;
  final String name;
  final String email;
  final int account_number;
  final String? bankName;

  // 🔥 새 필드: 주 수입원 (ENUM 문자열)
  final String incomeType; // PART_TIME / SALARY / ALLOWANCE

  const UserEntity({
    required this.id,
    required this.name,
    required this.email,
    required this.account_number,
    this.bankName,
    required this.incomeType,
  });

  // 선택: 필요하면 팩토리로도 쓸 수 있음
  factory UserEntity.fromMap(Map<String, dynamic> map) {
    return UserEntity(
      id: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      account_number: map['accountNumber'] ?? 0,
      bankName: map['bankName'],
      incomeType: map['incomeType'] ?? 'PART_TIME',
    );
  }
}
