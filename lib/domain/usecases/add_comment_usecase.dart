import '../entities/comment_entity.dart';
import '../repositories/community_repository.dart';

class AddCommentUseCase {
  final CommunityRepository repository;

  AddCommentUseCase(this.repository);

  Future<CommentEntity> call({
    required String postId,
    required String authorId,
    required String authorName,
    required String content,
  }) async {
    return await repository.addComment(
      postId: postId,
      authorId: authorId,
      authorName: authorName,
      content: content,
    );
  }
}

