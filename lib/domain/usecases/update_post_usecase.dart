import '../entities/community_post_entity.dart';
import '../repositories/community_repository.dart';

class UpdatePostUseCase {
  final CommunityRepository repository;

  UpdatePostUseCase(this.repository);

  Future<CommunityPostEntity> call({
    required String postId,
    String? title,
    String? content,
    String? category,
  }) async {
    return await repository.updatePost(
      postId: postId,
      title: title,
      content: content,
      category: category,
    );
  }
}

