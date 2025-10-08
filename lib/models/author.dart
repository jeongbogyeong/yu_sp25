import 'package:hive/hive.dart';

part 'author.g.dart';

@HiveType(typeId: 11)
class Author {
  @HiveField(0)
  final String email;

  @HiveField(1)
  final String userId; // Firebase UID

  @HiveField(2)
  final String? displayName; // 사용자 표시명 (선택사항)

  const Author({
    required this.email,
    required this.userId,
    this.displayName,
  });

  // 익명 작성자 생성 (로그인하지 않은 경우용)
  factory Author.anonymous() {
    return const Author(
      email: 'anonymous@example.com',
      userId: 'anonymous',
      displayName: '익명',
    );
  }

  // 현재 로그인한 사용자로부터 Author 생성
  factory Author.fromFirebaseUser(dynamic firebaseUser) {
    return Author(
      email: firebaseUser.email ?? 'unknown@example.com',
      userId: firebaseUser.uid,
      displayName: firebaseUser.displayName,
    );
  }

  // 이메일만 표시 (개인정보 보호를 위해 일부 마스킹)
  String get maskedEmail {
    if (email == 'anonymous@example.com') return '익명';
    final parts = email.split('@');
    if (parts.length != 2) return email;
    
    final username = parts[0];
    final domain = parts[1];
    
    if (username.length <= 2) {
      return email; // 너무 짧으면 그대로 표시
    }
    
    final maskedUsername = username.substring(0, 2) + '*' * (username.length - 2);
    return '$maskedUsername@$domain';
  }
}



