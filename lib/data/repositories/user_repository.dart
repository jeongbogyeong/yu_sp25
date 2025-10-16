import '../../domain/entities/user_entity.dart';
import '../../domain/entities/spending_entitiy.dart';
abstract class UserRepository {
  // 회원가입 (MySQL에만 저장)
  Future<bool> signup(UserEntity user, String password);

  // ✅ 추가: 로그인 (이메일, 비밀번호로 인증 후 UserEntity 반환)
  Future<UserEntity?> login(String email, String password);

  // 로그인 성공 후 추가 정보를 가져오는 용도 (선택적)
  Future<UserEntity?> fetchUser(String userId);

  // 유저의 소비데이터 가져오기
  Future<List<SpendingEntity>?> getSpending(int uid);

  //유저의 소비데이터 업데인트
  Future<bool> FetchSpending(SpendingEntity spending);
}
