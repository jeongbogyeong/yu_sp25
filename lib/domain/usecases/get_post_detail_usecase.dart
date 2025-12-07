import '../entities/community_post_entity.dart';
import '../repositories/community_repository.dart';

class GetPostDetailUseCase {
  final CommunityRepository repository;

  GetPostDetailUseCase(this.repository);

  Future<CommunityPostEntity?> call(String postId) async {
    return await repository.getPostById(postId);
  }
}

