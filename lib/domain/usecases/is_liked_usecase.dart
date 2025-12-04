import '../repositories/community_repository.dart';

class IsLikedUseCase {
  final CommunityRepository repository;

  IsLikedUseCase(this.repository);

  Future<bool> call({
    required String postId,
    required String userId,
  }) async {
    return await repository.isLiked(
      postId: postId,
      userId: userId,
    );
  }
}

