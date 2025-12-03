import 'package:get_it/get_it.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

// ✅ 도메인 및 데이터 레이어 import
import '../data/datasources/stat_remote_datasource.dart';
import '../data/datasources/user_remote_datasource.dart';
import '../data/datasources/community_remote_datasource.dart';
import '../data/repositories/stat_repository_impl.dart';
import '../data/repositories/user_repository_impl.dart';
import '../data/repositories/community_repository_impl.dart';
import '../domain/repositories/stat_repository.dart';
import '../domain/repositories/user_repository.dart'; // UserRepository (추상 클래스)
import '../domain/repositories/community_repository.dart';
import '../data/datasources/transaction_romote_datasource.dart';

import '../data/repositories/stat_repository_impl.dart';
import '../data/repositories/user_repository_impl.dart';
import '../data/repositories/transaction_repository_impl.dart';

import '../domain/repositories/stat_repository.dart';
import '../domain/repositories/user_repository.dart';
import '../domain/repositories/transaction_repository.dart';

// UseCase
import '../domain/usecases/userInfo_user.dart';
import '../domain/usecases/stat_user.dart';
import '../data/usecases/get_community_posts_usecase.dart';
import '../data/usecases/get_post_detail_usecase.dart';
import '../data/usecases/create_post_usecase.dart';
import '../data/usecases/update_post_usecase.dart';
import '../data/usecases/delete_post_usecase.dart';
import '../data/usecases/get_comments_usecase.dart';
import '../data/usecases/add_comment_usecase.dart';
import '../data/usecases/delete_comment_usecase.dart';
import '../data/usecases/toggle_like_usecase.dart';
import '../data/usecases/is_liked_usecase.dart';
import '../domain/usecases/transaction_user.dart';

// ✅ 뷰모델 import
import '../screens/viewmodels/UserViewModel.dart';
import '../screens/viewmodels/StatViewModel.dart';
import '../screens/viewmodels/CommunityViewModel.dart';
import '../screens/viewmodels/TransactionViewModel.dart';
// GetIt 인스턴스를 전역으로 사용하기 위해 선언
final locator = GetIt.instance;

void setupLocator() {
  final client = Supabase.instance.client;
  //#region Data Layer
  locator.registerLazySingleton<UserRemoteDataSource>(
          () => UserRemoteDataSource(client));
  locator.registerLazySingleton<StatRemoteDataSource>(
          () => StatRemoteDataSource(client));
  locator.registerLazySingleton<CommunityRemoteDataSource>(
          () => CommunityRemoteDataSource(client));
  locator.registerLazySingleton<TransactionRomoteDatasource>(
          () => TransactionRomoteDatasource(client));

  locator.registerLazySingleton<UserRepository>(
          () => UserRepositoryImpl(locator<UserRemoteDataSource>()));
  locator.registerLazySingleton<StatRepository>(
          () => StatRepositoryImpl(locator<StatRemoteDataSource>()));
  locator.registerLazySingleton<CommunityRepository>(
          () => CommunityRepositoryImpl(locator<CommunityRemoteDataSource>()));
  locator.registerLazySingleton<TransactionRepository>(
          () => TransactionRepositoryImpl(locator<TransactionRomoteDatasource>()));


  //#endregion

  //#region Domain Layer
  locator.registerLazySingleton<UserInfoUser>(
          () => UserInfoUser(locator<UserRepository>()));

  locator.registerLazySingleton<StatUser>(
          () => StatUser(locator<StatRepository>()));

  // Community UseCases
  locator.registerLazySingleton<GetCommunityPostsUseCase>(
          () => GetCommunityPostsUseCase(locator<CommunityRepository>()));
  locator.registerLazySingleton<GetPostDetailUseCase>(
          () => GetPostDetailUseCase(locator<CommunityRepository>()));
  locator.registerLazySingleton<CreatePostUseCase>(
          () => CreatePostUseCase(locator<CommunityRepository>()));
  locator.registerLazySingleton<UpdatePostUseCase>(
          () => UpdatePostUseCase(locator<CommunityRepository>()));
  locator.registerLazySingleton<DeletePostUseCase>(
          () => DeletePostUseCase(locator<CommunityRepository>()));
  locator.registerLazySingleton<GetCommentsUseCase>(
          () => GetCommentsUseCase(locator<CommunityRepository>()));
  locator.registerLazySingleton<AddCommentUseCase>(
          () => AddCommentUseCase(locator<CommunityRepository>()));
  locator.registerLazySingleton<DeleteCommentUseCase>(
          () => DeleteCommentUseCase(locator<CommunityRepository>()));
  locator.registerLazySingleton<ToggleLikeUseCase>(
          () => ToggleLikeUseCase(locator<CommunityRepository>()));
  locator.registerLazySingleton<IsLikedUseCase>(
          () => IsLikedUseCase(locator<CommunityRepository>()));
  locator.registerLazySingleton<TransactionUser>(
          () => TransactionUser(locator<TransactionRepository>()));
  //#endregion

  //#region Presentation Layer - ViewModels
  locator.registerLazySingleton<UserViewModel>(
          () => UserViewModel(locator<UserInfoUser>()));

  locator.registerLazySingleton<StatViewModel>(
          () => StatViewModel(locator<StatUser>()));

  locator.registerLazySingleton<CommunityViewModel>(
          () => CommunityViewModel(
            getCommunityPostsUseCase: locator<GetCommunityPostsUseCase>(),
            getPostDetailUseCase: locator<GetPostDetailUseCase>(),
            createPostUseCase: locator<CreatePostUseCase>(),
            updatePostUseCase: locator<UpdatePostUseCase>(),
            deletePostUseCase: locator<DeletePostUseCase>(),
            getCommentsUseCase: locator<GetCommentsUseCase>(),
            addCommentUseCase: locator<AddCommentUseCase>(),
            deleteCommentUseCase: locator<DeleteCommentUseCase>(),
            toggleLikeUseCase: locator<ToggleLikeUseCase>(),
            isLikedUseCase: locator<IsLikedUseCase>(),
          ));
  locator.registerLazySingleton<TransactionViewModel>(
          () => TransactionViewModel(locator<TransactionUser>()));
  //#endregion
}