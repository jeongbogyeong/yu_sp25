import 'package:flutter/foundation.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/signup_user.dart';

class SignupViewModel extends ChangeNotifier {
  final SignupUser signupUseCase;
  bool _isLoading = false;

  SignupViewModel(this.signupUseCase);

  bool get isLoading => _isLoading;

  Future<bool> registerUser({
    required String id,
    required String email,
    required String password,
    required String name,
    required String regdate,
  }) async {
    _isLoading = true;
    notifyListeners();

    final userEntity = UserEntity(
      id: id,
      email: email,
      password: password,
      name: name,
      regdate: regdate,
    );

    // 도메인 계층의 UseCase 호출
    final result = await signupUseCase.call(userEntity, password);

    _isLoading = false;
    notifyListeners();

    return result; // MySQL 등록 성공/실패 반환
  }
}
