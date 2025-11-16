import 'package:get_it/get_it.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

// ✅ 도메인 및 데이터 레이어 import
import '../data/datasources/stat_remote_datasource.dart';
import '../data/datasources/user_remote_datasource.dart';
import '../data/repositories/stat_repository_impl.dart';
import '../data/repositories/user_repository_impl.dart';
import '../domain/repositories/stat_repository.dart';
import '../domain/repositories/user_repository.dart'; // UserRepository (추상 클래스)

// UseCase
import '../domain/usecases/userInfo_user.dart';
import '../domain/usecases/stat_user.dart';

// ✅ 뷰모델 import

import '../screens/viewmodels/UserViewModel.dart';
import '../screens/viewmodels/StatViewModel.dart';
// GetIt 인스턴스를 전역으로 사용하기 위해 선언
final locator = GetIt.instance;

void setupLocator() {
  final client = Supabase.instance.client;
  //#region Data Layer
  locator.registerLazySingleton<UserRemoteDataSource>(
          () => UserRemoteDataSource(client));
  locator.registerLazySingleton<StatRemoteDataSource>(
          () => StatRemoteDataSource(client));

  locator.registerLazySingleton<UserRepository>(
          () => UserRepositoryImpl(locator<UserRemoteDataSource>()));
  locator.registerLazySingleton<StatRepository>(
          () => StatRepositoryImpl(locator<StatRemoteDataSource>()));
  //#endregion

  //#region Domain Layer
  locator.registerLazySingleton<UserInfoUser>(
          () => UserInfoUser(locator<UserRepository>()));

  locator.registerLazySingleton<StatUser>(
          () => StatUser(locator<StatRepository>()));
  //#endregion

  //#region Presentation Layer - ViewModels
  locator.registerLazySingleton<UserViewModel>(
          () => UserViewModel(locator<UserInfoUser>()));

  locator.registerLazySingleton<StatViewModel>(
          () => StatViewModel(locator<StatUser>()));
  //#endregion
}