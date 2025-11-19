import 'package:smartmoney/domain/entities/user_entity.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserRemoteDataSource {
  final SupabaseClient client;
  UserRemoteDataSource(this.client);

  Future<UserEntity?> login(String email, String password) async {
    try{
      final response =await client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final user = response.user;

      if (user == null) {
        throw Exception("로그인 실패: Supabase가 user를 반환하지 않았습니다.");
      }else{
        if(user!=null){
          final data = await client.from('userInfo_table').select().eq('uid', user.id).maybeSingle();
          if (data == null) return null;

          return UserEntity(
              id: data['uid'],
              name: data['name'],
              email: data['email'],
              account_number: data['accountNumber']
          );
        }
      }
    }catch(e){
      print("로그인 에러 발생: $e");
      rethrow;
    }

  }

  Future<UserEntity?> signup({
    required String email,
    required String password,
    required String name,
    required int accountNumber,
  }) async {
    try {
      final registered = await client.from('userInfo_table').select().eq('email', email).maybeSingle();
      if(registered!=null) return null;
      final response = await client.auth.signUp(
        email: email,
        password: password,
      );

      final user = response.user;
      if (user == null) {
        throw Exception("회원가입 실패: Supabase가 user를 반환하지 않았습니다.");
      }

      // 2️⃣ Supabase Auth에서 받은 uid (유저 고유 ID)
      final uid = user.id;

      // 3️⃣ userInfo 테이블에 추가 정보 저장
      await client.from('userInfo_table').insert({
        'uid': uid,
        'name': name,
        'email': email,
        'accountNumber': accountNumber,
      });

      return UserEntity(
          id: uid,
          name: name,
          email: email,
          account_number: accountNumber);
    } catch (e) {
      print("회원가입 에러 발생: $e");
      rethrow;
    }
  }

  Future<void> logout() async {
    await client.auth.signOut();
  }
}
