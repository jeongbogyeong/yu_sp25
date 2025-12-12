import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/user_entity.dart';

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
        bankName: data['bankName'] as String?,
        photoUrl: data['photoUrl'] as String?, // ✅ 프로필 사진
        incomeType:
            data['incomeType'] as String? ??
            'PART_TIME', // ✅ ENUM 컬럼 읽어오기 (기본값)
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
    required String incomeType, // 🔥 추가
  }) async {
    try {
      // 1) 이메일 중복 체크
      final registeredEmail = await client
          .from('userInfo_table')
          .select()
          .eq('email', email)
          .maybeSingle();
      print("이메일 중복 : $registeredEmail");
      if (registeredEmail != null) {
        throw Exception("email-already-in-use");
      }

      // 2) 계좌번호 중복 체크 (0은 예외)
      if (accountNumber != 0) {
        final registeredAccount = await client
            .from('userInfo_table')
            .select()
            .eq('accountNumber', accountNumber)
            .maybeSingle();

        if (registeredAccount != null) {
          throw Exception("account-number-already-in-use");
        }
      }

      // 3) Supabase Auth 회원가입
      final response = await client.auth.signUp(
        email: email,
        password: password,
      );

      final user = response.user;
      if (user == null) {
        throw Exception("회원가입 실패: Supabase가 user를 반환하지 않았습니다.");
      }

      final uid = user.id;

      // 4) userInfo_table 에 추가 정보 저장
      await client.from('userInfo_table').insert({
        'uid': uid,
        'name': name,
        'email': email,
        'accountNumber': accountNumber,
        'bankName': bankName,
        'incomeType': incomeType,
      });

      // 5) UserEntity 반환
      return UserEntity(
        id: uid,
        name: name,
        email: email,
        account_number: accountNumber,
        bankName: bankName,
        photoUrl: null,
        incomeType: incomeType,
      );
    } catch (e) {
      print("회원가입 에러 발생: $e");
      rethrow;
    }
  }

  // =========================================
  // 프로필 이미지 업로드 + URL 리턴
  // =========================================
  Future<String> uploadProfileImage(String userId, XFile file) async {
    final bytes = await file.readAsBytes();
    final filePath =
        'users/$userId/profile_${DateTime.now().millisecondsSinceEpoch}.png';

    await client.storage
        .from('profile_images')
        .uploadBinary(
          filePath,
          bytes,
          fileOptions: const FileOptions(contentType: 'image/png'),
        );

    final url = client.storage.from('profile_images').getPublicUrl(filePath);
    print("url : $url");
    return url;
  }

  // =========================================
  // photoUrl 컬럼 업데이트
  // =========================================
  Future<bool> updatePhotoUrl(String uid, String url) async {
    try {
      await client
          .from('userInfo_table')
          .update({'photoUrl': url})
          .eq('uid', uid)
          .select();

      print("Supabase update 결과: $uid");
      return true;
    } catch (e) {
      print("updatePhotoUrl 에러 발생: $e");
      return false;
    }
  }

  // =========================================
  // 이메일로 유저 조회
  // =========================================
  Future<UserEntity?> getUserByEmail(String email) async {
    try {
      final result = await client
          .from('userInfo_table')
          .select()
          .eq('email', email)
          .maybeSingle();

      if (result == null) return null;

      return UserEntity(
        id: result['uid'] as String,
        name: result['name'] as String,
        email: result['email'] as String,
        account_number: result['accountNumber'] as int,
        bankName: result['bankName'] as String?,
        photoUrl: result['photoUrl'] as String?,
        incomeType: result['incomeType'] as String? ?? 'PART_TIME', // ✅ 추가
      );
    } catch (e) {
      print('❌ getUserByEmail error: $e');
      return null;
    }
  }

  // =========================================
  // 로그아웃
  // =========================================
  Future<void> logout() async {
    await client.auth.signOut();
  }
}
