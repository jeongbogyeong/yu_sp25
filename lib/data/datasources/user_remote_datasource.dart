import 'package:smartmoney/domain/entities/user_entity.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserRemoteDataSource {
  final SupabaseClient client;

  UserRemoteDataSource(this.client);

  // =========================================
  // 로그인
  // =========================================
  Future<UserEntity?> login(String email, String password) async {
    try {
      final response = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final user = response.user;

      if (user == null) {
        throw Exception("로그인 실패: Supabase가 user를 반환하지 않았습니다.");
      }

      // userInfo_table 에서 추가 정보 조회
      final data = await client
          .from('userInfo_table')
          .select()
          .eq('uid', user.id)
          .maybeSingle();

      if (data == null) return null;

      return UserEntity(
        id: data['uid'] as String,
        name: data['name'] as String,
        email: data['email'] as String,
        account_number: data['accountNumber'] as int,
        bankName: data['bankName'] as String?, // 👈 Supabase 컬럼 bankName
      );
    } catch (e) {
      print("로그인 에러 발생: $e");
      rethrow;
    }
  }

  // =========================================
  // 회원가입
  // =========================================
  Future<UserEntity?> signup({
    required String email,
    required String password,
    required String name,
    required int accountNumber,
    required String bankName,
  }) async {
    try {
      // 이미 같은 이메일이 있는지 확인
      final registered = await client
          .from('userInfo_table')
          .select()
          .eq('email', email)
          .maybeSingle();

      if (registered != null) {
        // 이미 등록된 이메일이면 null 반환 (위쪽에서 처리)
        return null;
      }

      // 1) Supabase Auth 회원가입
      final response = await client.auth.signUp(
        email: email,
        password: password,
      );

      final user = response.user;
      if (user == null) {
        throw Exception("회원가입 실패: Supabase가 user를 반환하지 않았습니다.");
      }

      final uid = user.id;

      // 2) userInfo_table 에 추가 정보 저장
      await client.from('userInfo_table').insert({
        'uid': uid,
        'name': name,
        'email': email,
        'accountNumber': accountNumber,
        'bankName': bankName, // 👈 컬럼명 bankName 으로 저장
      });

      // 3) UserEntity 반환
      return UserEntity(
        id: uid,
        name: name,
        email: email,
        account_number: accountNumber,
        bankName: bankName,
      );
    } catch (e) {
      print("회원가입 에러 발생: $e");
      rethrow;
    }
  }

  // =========================================
  // 로그아웃
  // =========================================
  Future<void> logout() async {
    await client.auth.signOut();
  }
}
