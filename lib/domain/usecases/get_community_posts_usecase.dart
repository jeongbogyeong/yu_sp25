import '../entities/community_post_entity.dart';
import '../repositories/community_repository.dart';

class GetCommunityPostsUseCase {
  final CommunityRepository repository;

  GetCommunityPostsUseCase(this.repository);

  Future<List<CommunityPostEntity>> call({
    int? limit,
    int? offset,
    String? category,
  }) async {
    return await repository.getPosts(
      limit: limit,
      offset: offset,
      category: category,
    );
  }
}

