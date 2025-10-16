import 'package:get_it/get_it.dart';

// ✅ 도메인 및 데이터 레이어 import
import 'data/datasources/user_remote_datasource.dart';
import 'data/repositories/user_repository_impl.dart';
import 'data/repositories/user_repository.dart'; // UserRepository (추상 클래스)

// UseCase
import 'domain/usecases/fetch_user.dart';
import 'domain/usecases/login_user.dart';
import 'domain/usecases/signup_user.dart';
import 'domain/usecases/get_spending.dart';
import 'domain/usecases/fetch_spending.dart';

// ✅ 뷰모델 import
import 'screens/viewmodels/SignupViewModel.dart';
import 'screens/viewmodels/UserViewModel.dart';
import 'screens/viewmodels/SpendingViewModel.dart';

// GetIt 인스턴스를 전역으로 사용하기 위해 선언
final locator = GetIt.instance;

void setupLocator() {

  //#region Data Layer
  locator.registerLazySingleton<UserRemoteDataSource>(
          () => UserRemoteDataSource());
  locator.registerLazySingleton<UserRepository>(
          () => UserRepositoryImpl(locator<UserRemoteDataSource>()));

  //#endregion

  //#region Domain Layer
  locator.registerLazySingleton<SignupUser>(
          () => SignupUser(locator<UserRepository>()));

  locator.registerLazySingleton<FetchUser>(
          () => FetchUser(locator<UserRepository>()));

  locator.registerLazySingleton<LoginUser>(
          () => LoginUser(locator<UserRepository>()));

  locator.registerLazySingleton<GetSpending>(
          () => GetSpending(locator<UserRepository>()));

  locator.registerLazySingleton<FetchSpending>(
          () => FetchSpending(locator<UserRepository>()));
  //#endregion

  //#region Presentation Layer - ViewModels
  locator.registerFactory<SignupViewModel>(
          () => SignupViewModel(locator<SignupUser>()));

  locator.registerLazySingleton<UserViewModel>(
          () => UserViewModel());

  locator.registerLazySingleton<SpendingViewModel>(
          () => SpendingViewModel(locator<GetSpending>(),locator<FetchSpending>()));
  //#endregion
}