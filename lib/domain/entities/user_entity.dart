import 'package:supabase_flutter/supabase_flutter.dart';

class UserEntity {
  final String id;
  final String name;
  final String email;
  final int account_number;
  final String? bankName;
  final String? photoUrl;

  const UserEntity({
    required this.id,
    required this.name,
    required this.email,
    required this.account_number,
    this.bankName,
    this.photoUrl,
  });
}
