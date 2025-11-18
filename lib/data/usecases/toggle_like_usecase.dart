import '../../domain/repositories/community_repository.dart';

class ToggleLikeUseCase {
  final CommunityRepository repository;

  ToggleLikeUseCase(this.repository);

  Future<bool> call({
    required String postId,
    required String userId,
  }) async {
    return await repository.toggleLike(
      postId: postId,
      userId: userId,
    );
  }
}

