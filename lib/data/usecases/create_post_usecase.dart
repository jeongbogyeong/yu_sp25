import '../../domain/entities/community_post_entity.dart';
import '../../domain/repositories/community_repository.dart';

class CreatePostUseCase {
  final CommunityRepository repository;

  CreatePostUseCase(this.repository);

  Future<CommunityPostEntity> call({
    required String title,
    required String content,
    required String authorId,
    required String authorName,
    String category = '자유',
  }) async {
    return await repository.createPost(
      title: title,
      content: content,
      authorId: authorId,
      authorName: authorName,
      category: category,
    );
  }
}

